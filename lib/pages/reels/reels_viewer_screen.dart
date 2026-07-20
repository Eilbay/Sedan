import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:video_player/video_player.dart';
import 'package:collection/collection.dart';
import 'package:optombai/bloc/favorite_bloc/favorite_bloc.dart';
import 'package:optombai/bloc/reel_bloc/reel_bloc.dart';
import 'package:optombai/configs/constrants.dart';
import 'package:optombai/core/debug/talker_instance.dart';
import 'package:optombai/bloc/user_bloc/user_bloc.dart';
import 'package:optombai/core/theme_notifier.dart';
import 'package:optombai/data/models/favorite/favorite_model.dart';
import 'package:optombai/data/models/posts/post_model.dart';
import 'package:optombai/data/models/reel/reel_model.dart';
import 'package:optombai/data/repositories/i_reel_repository.dart';
import 'package:optombai/data/api_client.dart';
import 'package:optombai/features/promotion/data/data_sources/promotion_remote_data_source.dart';
import 'package:optombai/pages/reels/reel_impression_tracker.dart';
import 'package:optombai/pages/reels/reel_playback_manager.dart';
import 'package:optombai/services/i_video_pre_buffer_service.dart';
import 'package:optombai/services/i_player_factory.dart';
import 'package:optombai/services/connectivity_aware_config.dart';
import 'package:optombai/core/di/injection.dart';
import 'package:optombai/utils/extensions/int_format_extension.dart';
import 'package:optombai/widgets/comment/comments_bottom_sheet.dart';
import 'package:share_plus/share_plus.dart';
import 'package:optombai/data/models/report/report_target_type.dart';
import 'package:optombai/widgets/moderation/user_actions_sheet.dart';
import 'package:optombai/widgets/reel/reel_owner_card.dart';
import 'package:auto_route/auto_route.dart';
import 'package:optombai/app/router/app_router.dart';

@RoutePage()
class ReelsViewerScreen extends StatefulWidget {
  final List<ReelModel> reels;
  final int initialIndex;
  final bool isProductVideo;
  final bool isActive;

  const ReelsViewerScreen({
    super.key,
    required this.reels,
    this.initialIndex = 0,
    this.isProductVideo = false,
    this.isActive = true,
  });

  @override
  State<ReelsViewerScreen> createState() => _ReelsViewerScreenState();
}

class _ReelsViewerScreenState extends State<ReelsViewerScreen>
    with WidgetsBindingObserver {
  late PageController _pageController;
  int _currentIndex = 0;

  late final ReelPlaybackManager _playback;
  late final ReelImpressionTracker _tracker;

  bool _showLikeAnimation = false;
  bool _userPaused = false;
  final Map<String, int> _commentCounts = {};
  final _controllerRevision = ValueNotifier<int>(0);

  /// Debounce for "watched" progress — only fire after the user actually
  /// settles on a reel (~800ms), so fast scrolls don't mark everything seen.
  Timer? _progressTimer;
  static const Duration _progressDebounce = Duration(milliseconds: 800);

  String _streamUrlFor(ReelModel reel) => reel.playbackUrl;

  bool _isPlayableReel(ReelModel reel) =>
      reel.isProcessed && reel.playbackUrl.isNotEmpty;

  List<ReelModel> _prevReels = const [];

  /// How many reels ahead of the current one to keep warm in the pool.
  /// Kept small on purpose — the ready pool is capped (iOS 4 / Android 3)
  /// to stay within the OOM budget alongside the active ±2 controllers.
  static const int _preBufferAhead = 2;

  @override
  void initState() {
    super.initState();
    final maxInitialIndex = widget.reels.isEmpty ? 0 : widget.reels.length - 1;
    _currentIndex = widget.initialIndex.clamp(0, maxInitialIndex).toInt();

    final prefs = context.read<ReelBloc>().preferences;
    WidgetsBinding.instance.addObserver(this);
    _applyNetworkAwareConfig();
    _playback = ReelPlaybackManager(
      playerFactory: getIt<IPlayerFactory>(),
      preBufferService: getIt<IVideoPreBufferService>(),
    );
    _tracker = ReelImpressionTracker(
      dataSource: PromotionRemoteDataSource(
        ApiClient.I.dio,
        prefs,
      ),
      repository: getIt<IReelRepository>(),
      tokenProvider: () => prefs.getString(TOKEN_KEY) ?? '',
      currentUserId: context.read<UserBloc>().state.user.id,
    );

    final reels = _availableReels();
    if (reels.isNotEmpty) {
      _currentIndex = _currentIndex.clamp(0, reels.length - 1).toInt();
    } else {
      _currentIndex = 0;
    }
    _pageController = PageController(initialPage: _currentIndex);

    if (reels.isEmpty) return;

    _prevReels = reels;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _prefetchCovers(reels, 0, reels.length < 10 ? reels.length : 10);
    });

    debugPrint(
        '[REEL] initState: starting init for index=$_currentIndex reelCount=${reels.length} isActive=${widget.isActive}');
    _playback.initControllers(
      centerIndex: _currentIndex,
      reelCount: reels.length,
      urlsAt: (i) => _streamUrlFor(reels[i]),
      isActive: widget.isActive,
      onCurrentReady: () {
        talker.info('[REEL] onCurrentReady index=$_currentIndex');
        if (mounted) _controllerRevision.value++;
      },
    );

    _preBufferWindow(_currentIndex, reels);

    final initialReel = reels[_currentIndex];
    _tracker.registerView(initialReel.id, context.read<ReelBloc>());
    _tracker.recordImpressionIfNeeded(initialReel);
    _scheduleProgress(initialReel);
  }

  /// Mark [reel] as watched after a short dwell so quick fly-by scrolls aren't
  /// counted. Any new reel cancels the previous pending mark.
  void _scheduleProgress(ReelModel reel) {
    _progressTimer?.cancel();
    _progressTimer = Timer(_progressDebounce, () {
      _tracker.reportProgress(reel.id);
    });
  }

  void _prefetchCovers(List<ReelModel> reels, int start, int end) {
    // Stagger image decodes across frames. precacheImage decodes the
    // image on the UI thread; firing 10 of them at once on a slow
    // device can block the build phase for >10 seconds and trigger an
    // iOS watchdog kill (see crash_log analysis 2026-05-15: 20s build
    // freeze right after `precaching 10 cover images`).
    for (var i = start; i < end && i < reels.length; i++) {
      final url = reels[i].coverMediumUrl ?? reels[i].coverUrl;
      if (url == null || url.isEmpty) continue;
      final offsetMs = (i - start) * 80; // 80ms between decodes
      Future<void>.delayed(Duration(milliseconds: offsetMs), () {
        if (!mounted) return;
        precacheImage(
          CachedNetworkImageProvider(url),
          context,
          // A cover URL can 404 (deleted/stale media). Handle it here so the
          // non-fatal image failure degrades to a placeholder instead of
          // bubbling to FlutterError.onError and being reported to Crashlytics.
          onError: (exception, stackTrace) {
            debugPrint('[REEL] cover precache failed ($url): $exception');
          },
        );
      });
    }
  }

  /// Tune pre-buffer concurrency based on the current network type.
  /// Slow networks get fewer parallel inits; fast networks get more.
  Future<void> _applyNetworkAwareConfig() async {
    final config = getIt<IConnectivityConfig>();
    final concurrency = await config.optimalPreBufferConcurrency();
    if (!mounted) return;

    getIt<IVideoPreBufferService>().setMaxConcurrent(concurrency);
    debugPrint(
      '[REEL] network-aware config applied: concurrency=$concurrency',
    );
  }

  /// Warms the pre-buffer pool with the next [_preBufferAhead] reels AHEAD of
  /// [rawIndex]. Indices are wrapped to match the infinite-scroll PageView
  /// (raw index can exceed reels.length). This both enqueues (adds to the
  /// pool) AND prioritizes — the previous code only called prioritize(), which
  /// merely reorders already-queued urls and silently no-opped on an empty
  /// queue, so the pool never filled and every reel cold-started.
  void _preBufferWindow(int rawIndex, List<ReelModel> reels) {
    if (reels.isEmpty) return;
    final len = reels.length;
    final urls = <String>[];
    for (var offset = 1; offset <= _preBufferAhead; offset++) {
      final reel = reels[_wrap(rawIndex + offset, len)];
      final url = reel.playbackUrl;
      if (_isPlayableReel(reel) && !urls.contains(url)) urls.add(url);
    }
    if (urls.isEmpty) return;

    final preBuffer = getIt<IVideoPreBufferService>();
    // Active foreground scrolling is the signal to keep the queue running.
    // It may have been paused by a background/memory-pressure flush or by the
    // failure throttle — a user swipe must resume it (the throttle is designed
    // to be cleared by the next user-driven event), otherwise the pool stays
    // dead for the rest of the session and every reel cold-starts.
    preBuffer.resume();
    preBuffer.enqueue(urls);
    preBuffer.prioritize(urls);
    talker.info('[REEL-PREBUF] window @raw=$rawIndex → ${urls.length} urls');
    debugPrint('[PB] window @raw=$rawIndex enqueue=${urls.length}');
  }

  List<ReelModel> _availableReels() {
    final stateReels = context.read<ReelBloc>().state.reels;
    final source = stateReels.isNotEmpty ? stateReels : widget.reels;
    return source.where(_isPlayableReel).toList(growable: false);
  }

  @override
  void didUpdateWidget(covariant ReelsViewerScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    final reels = _availableReels();
    _clampCurrentIndex(reels);

    _reconcilePlayback(reels);

    if (oldWidget.isActive != widget.isActive) {
      if (!widget.isActive) {
        _playback.pauseAll();
      } else {
        _userPaused = false;
        if (reels.isNotEmpty) {
          _playback.initControllers(
            centerIndex: _currentIndex,
            reelCount: reels.length,
            urlsAt: (i) => _streamUrlFor(reels[i]),
            isActive: true,
            onCurrentReady: () {
              if (mounted) _controllerRevision.value++;
            },
          );
        }
      }
    }
  }

  bool _reelListsMatch(List<ReelModel> a, List<ReelModel> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id) return false;
    }
    return true;
  }

  /// Syncs the player pool to a changed reel list. Called both from
  /// [didUpdateWidget] (parent rebuilds) and from the ReelBloc listener
  /// (state-only changes such as an optimistic removal after a report) — the
  /// latter is what makes a reported reel disappear and the next one play
  /// immediately instead of waiting for the 5-min feed refetch.
  void _reconcilePlayback(List<ReelModel> reels) {
    if (_reelListsMatch(_prevReels, reels)) return;
    final oldReels = _prevReels;
    _prevReels = reels;
    _playback.reconcile(
      newReelCount: reels.length,
      oldReelCount: oldReels.length,
      reelIdAt: (i) => reels[i].id,
      oldReelIdAt: (i) => oldReels[i].id,
    );
    if (widget.isActive &&
        reels.isNotEmpty &&
        !_playback.players.containsKey(_currentIndex)) {
      _playback.initControllers(
        centerIndex: _currentIndex.clamp(0, reels.length - 1),
        reelCount: reels.length,
        urlsAt: (i) => _streamUrlFor(reels[i]),
        isActive: true,
        onCurrentReady: () {
          if (mounted) _controllerRevision.value++;
        },
      );
    }
  }

  /// Wraps any (potentially infinite) PageView index into a valid
  /// index for [_availableReels]. When the user passes the last reel
  /// the viewer loops back to the beginning instead of dead-ending,
  /// so playback never stalls "all reels watched".
  int _wrap(int rawIndex, int len) =>
      len == 0 ? 0 : ((rawIndex % len) + len) % len;

  void _clampCurrentIndex(List<ReelModel> reels) {
    if (reels.isEmpty) {
      _currentIndex = 0;
      return;
    }
    // PageView is now infinite — leave the raw page index alone so
    // swiping wraps naturally via _wrap(). Only normalise out-of-range
    // negatives that can never come from real user input.
    if (_currentIndex < 0) _currentIndex = 0;
  }

  /// Pause on interruption (incoming call, app switcher, backgrounding) and
  /// auto-resume when the user comes back — as long as the reels tab is still
  /// active and the user hadn't manually paused. Without `audio_session` this
  /// covers calls/backgrounding via the platform lifecycle; pure audio-focus
  /// loss without a lifecycle change is not handled (acceptable trade-off).
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        _playback.pauseAll();
        // Deliver queued progress/impressions while we still have a moment.
        _tracker.flush();
      case AppLifecycleState.resumed:
        if (widget.isActive && !_userPaused) {
          final reels = _availableReels();
          if (reels.isNotEmpty) {
            _playback.initControllers(
              centerIndex: _currentIndex,
              reelCount: reels.length,
              urlsAt: (i) => _streamUrlFor(reels[_wrap(i, reels.length)]),
              isActive: true,
              onCurrentReady: () {
                if (mounted) _controllerRevision.value++;
              },
            );
          }
        }
      case AppLifecycleState.detached:
        break;
    }
  }

  @override
  void dispose() {
    // Stop pre-buffer downloads when leaving reels — no point spending
    // bandwidth on videos the user isn't watching anymore.
    getIt<IVideoPreBufferService>().cancelAll();
    _progressTimer?.cancel();
    _tracker.flush();
    _tracker.dispose();
    WidgetsBinding.instance.removeObserver(this);
    _controllerRevision.dispose();
    _pageController.dispose();
    _playback.dispose();
    super.dispose();
  }

  void _toggleLike(String reelId, bool isLiked) {
    if (isLiked) {
      context.read<ReelBloc>().add(UnlikeReelEvent(reelId: reelId));
    } else {
      context.read<ReelBloc>().add(LikeReelEvent(reelId: reelId));
      _showLikeAnimationEffect();
    }
  }

  void _showLikeAnimationEffect() {
    setState(() => _showLikeAnimation = true);
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _showLikeAnimation = false);
    });
  }

  void _openComments(String postId) {
    if (!_isUserAuthorized()) {
      debugPrint('[AUTH] reels comments gate -> sign in');
      context.router.push(const SignInRoute());
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CommentsBottomSheet(
        postId: postId,
        onCommentCountChanged: (count) {
          if (!mounted || _commentCounts[postId] == count) return;
          setState(() => _commentCounts[postId] = count);
        },
      ),
    );
  }

  bool _isUserAuthorized() {
    // `isAgree` is stale on most production accounts — what we really
    // care about here is "is the viewer logged in", which is signalled
    // by the user object actually having an id.
    final user = context.read<UserBloc>().state.user;
    return user.id.isNotEmpty;
  }

  void _handleTap(int index) {
    final isNowPlaying = _playback.togglePlayPause(index);
    _userPaused = !isNowPlaying;
    setState(() {});
  }

  void _handleDoubleTap(ReelModel reel) {
    if (!reel.isLiked) {
      _toggleLike(reel.id, reel.isLiked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRegister = context.select((ThemeNotifier n) => n.isRegister);

    return MediaQuery.removePadding(
      context: context,
      removeTop: true,
      removeBottom: true,
      child: Scaffold(
        backgroundColor: Colors.black,
        extendBody: true,
        extendBodyBehindAppBar: true,
        body: BlocConsumer<ReelBloc, ReelState>(
          listenWhen: (prev, curr) => prev.reels != curr.reels,
          listener: (context, state) {
            // The reel list changed without a parent rebuild — e.g. the
            // optimistic removal after a report. Resync the player pool so
            // the now-current slot plays the next reel instead of the
            // removed one's last frame (didUpdateWidget won't fire here).
            _reconcilePlayback(_availableReels());
          },
          buildWhen: (prev, curr) =>
              prev.reels != curr.reels ||
              prev.isLoading != curr.isLoading ||
              prev.errors != curr.errors,
          builder: (context, state) {
            final reels = _availableReels();
            debugPrint(
                '[REEL] BlocBuilder: reels=${reels.length} stateReels=${state.reels.length} isLoading=${state.isLoading} isActive=${widget.isActive}');
            if (reels.isEmpty && state.isLoading) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            }
            if (reels.isEmpty && state.errors.isNotEmpty) {
              return _ReelsFetchErrorState(
                onRetry: () => context
                    .read<ReelBloc>()
                    .add(FetchReelsEvent(forceRefresh: true)),
              );
            }
            if (reels.isEmpty) {
              return const Center(
                child: Text(
                  'Видео пока нет',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              );
            }
            _clampCurrentIndex(reels);

            return SizedBox.expand(
              child: PageView.builder(
                controller: _pageController,
                scrollDirection: Axis.vertical,
                // null itemCount = infinite scroll. Once the user reaches
                // the last reel, swiping down keeps going and wraps back
                // to the first via `_wrap(index, reels.length)`. The
                // backend already de-dupes already-viewed reels server
                // side, so once it stops returning new ones we keep
                // looping the locally-loaded set instead of dead-ending.
                onPageChanged: (index) {
                  final swipeSw = Stopwatch()..start();
                  _currentIndex = index;
                  _userPaused = false;
                  final reel = reels[_wrap(index, reels.length)];
                  _tracker.registerView(reel.id, context.read<ReelBloc>());
                  _tracker.recordImpressionIfNeeded(reel);
                  _scheduleProgress(reel);
                  _playback.initControllers(
                    centerIndex: index,
                    reelCount: reels.length,
                    urlsAt: (i) => _streamUrlFor(reels[_wrap(i, reels.length)]),
                    isActive: widget.isActive,
                    onCurrentReady: () {
                      debugPrint(
                          '[TIMING] swipe→ready index=$index ${swipeSw.elapsedMilliseconds}ms');
                      if (mounted) _controllerRevision.value++;
                    },
                  );
                  context
                      .read<ReelBloc>()
                      .add(SaveLastViewedReelIndexEvent(index: index));
                  _preBufferWindow(index, reels);
                  // The reels-feed is cyclic — `next` is always present, so we
                  // keep pulling fresh pages whenever the user nears the end of
                  // the loaded buffer, on every loop pass. The bloc guards
                  // re-entry (isLoadingMore) and appending only grows the tail
                  // (off-screen), so the current page never jumps. This is what
                  // makes the infinite loop surface new content instead of
                  // replaying the same locally-loaded set forever.
                  final wrapped = _wrap(index, reels.length);
                  if (reels.length - wrapped <= 5) {
                    context.read<ReelBloc>().add(FetchMoreReelsEvent());
                  }
                },
                itemBuilder: (context, index) {
                  final wrapped = _wrap(index, reels.length);
                  final updatedReel = reels[wrapped];
                  final currentUserId = context.read<UserBloc>().state.user.id;

                  return ValueListenableBuilder<int>(
                    valueListenable: _controllerRevision,
                    builder: (_, __, ___) {
                      return _ReelPage(
                        key: ValueKey('${updatedReel.id}_$index'),
                        reel: updatedReel,
                        controller: _playback.players[index],
                        isInitialized: _playback.initialized[index] ?? false,
                        isProcessed: updatedReel.isProcessed,
                        coverUrl:
                            updatedReel.coverMediumUrl ?? updatedReel.coverUrl,
                        isProductVideo: widget.isProductVideo,
                        isRegister: isRegister,
                        currentUserId: currentUserId,
                        showLikeAnimation: _showLikeAnimation,
                        isPaused: _userPaused && index == _currentIndex,
                        onTap: () => _handleTap(index),
                        onDoubleTap: () => _handleDoubleTap(updatedReel),
                        onToggleLike: () =>
                            _toggleLike(updatedReel.id, updatedReel.isLiked),
                        onOpenComments: () => _openComments(updatedReel.id),
                        commentCount: _commentCounts[updatedReel.id] ?? 0,
                        isUserAuthorized: _isUserAuthorized(),
                      );
                    },
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Private extracted widgets
// ---------------------------------------------------------------------------

/// Full-screen gradient overlays (top and bottom) for UI readability
class _GradientsOverlay extends StatelessWidget {
  const _GradientsOverlay();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 120.h,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.5),
                Colors.transparent,
              ],
            ),
          ),
        ),
        const Spacer(),
        Container(
          height: 200.h,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withValues(alpha: 0.7),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Single action button used in the right-side action column
class _ReelActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  const _ReelActionButton({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 32.sp,
          ),
          if (label.isNotEmpty) ...[
            SizedBox(height: 4.h),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Video player with shimmer placeholder while loading.
///
/// Layers (bottom -> top):
/// 1. Cover / shimmer — always visible underneath
/// 2. Video widget — mounted early (opacity 0) for texture pre-allocation,
///    fades in when player has decoded frames AND texture is rendered
/// 3. Loading spinner — visible until video fades in
/// 4. Buffering spinner — debounced, shown only after 800ms of continuous buffering
class _ReelVideoPlayer extends StatefulWidget {
  final VideoPlayerController? controller;
  final bool isInitialized;
  final bool isProcessed;
  final String? coverUrl;

  const _ReelVideoPlayer({
    required this.controller,
    required this.isInitialized,
    this.isProcessed = true,
    this.coverUrl,
  });

  @override
  State<_ReelVideoPlayer> createState() => _ReelVideoPlayerState();
}

class _ReelVideoPlayerState extends State<_ReelVideoPlayer> {
  bool _showBuffering = false;
  bool _showLoading = false;
  Timer? _bufferDebounce;
  Timer? _loadingDebounce;
  VoidCallback? _controllerListener;
  Timer? _watchdog;
  Duration _lastPos = Duration.zero;
  int _stuckTicks = 0;
  final Stopwatch _stallSw = Stopwatch();
  int _stallCount = 0;
  int _totalStallMs = 0;
  bool _wasBuffering = false;

  @override
  void initState() {
    super.initState();
    _subscribeBuffering();
    _scheduleLoadingIndicator();
  }

  @override
  void didUpdateWidget(covariant _ReelVideoPlayer old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      _detachListener(old.controller);
      _watchdog?.cancel();
      _bufferDebounce?.cancel();
      _showBuffering = false;
      _wasBuffering = false;
      _stallSw.stop();
      _subscribeBuffering();
    }
    // Reset loading debounce when initialization state changes.
    if (old.isInitialized != widget.isInitialized) {
      _loadingDebounce?.cancel();
      if (widget.isInitialized) {
        _showLoading = false;
      } else {
        _scheduleLoadingIndicator();
      }
    }
  }

  /// Show loading spinner only after 1s — cover image is visible meanwhile.
  void _scheduleLoadingIndicator() {
    if (widget.isInitialized) return;
    _loadingDebounce?.cancel();
    _loadingDebounce = Timer(const Duration(seconds: 1), () {
      if (mounted && !widget.isInitialized) {
        setState(() => _showLoading = true);
      }
    });
  }

  void _detachListener(VideoPlayerController? controller) {
    final listener = _controllerListener;
    if (listener != null && controller != null) {
      controller.removeListener(listener);
    }
    _controllerListener = null;
  }

  void _subscribeBuffering() {
    final controller = widget.controller;
    if (controller == null) return;
    final tag = identityHashCode(controller);
    _stallCount = 0;
    _totalStallMs = 0;
    _wasBuffering = controller.value.isBuffering;

    void onValueChanged() {
      if (!mounted) return;
      final c = widget.controller;
      if (c == null) return;
      final buffering = c.value.isBuffering;
      if (buffering != _wasBuffering) {
        _wasBuffering = buffering;
        if (buffering) {
          // Track stall start for timing — even if UI debounce hides it.
          if (!_stallSw.isRunning) {
            _stallSw
              ..reset()
              ..start();
          }
          // Only show spinner after 800ms of continuous buffering.
          _bufferDebounce ??= Timer(const Duration(milliseconds: 800), () {
            if (mounted) setState(() => _showBuffering = true);
          });
        } else {
          if (_stallSw.isRunning) {
            _stallSw.stop();
            final ms = _stallSw.elapsedMilliseconds;
            if (ms >= 200) {
              _stallCount++;
              _totalStallMs += ms;
              debugPrint(
                '[STALL] player=$tag dur=${ms}ms count=$_stallCount totalMs=$_totalStallMs',
              );
            }
          }
          _bufferDebounce?.cancel();
          _bufferDebounce = null;
          if (_showBuffering && mounted) {
            setState(() => _showBuffering = false);
          }
        }
      }
      // Surface controller errors to the log (replacement for mpv error stream).
      final err = c.value.errorDescription;
      if (err != null && err.isNotEmpty) {
        talker.info('[VIDEO-ERR] player=$tag $err');
      }
    }

    _controllerListener = onValueChanged;
    controller.addListener(onValueChanged);

    // Watchdog: detect "playing=true but position frozen" stalls and
    // auto-recover via pause+play (the workaround user found manually).
    _watchdog?.cancel();
    _lastPos = Duration.zero;
    _stuckTicks = 0;
    _watchdog = Timer.periodic(const Duration(milliseconds: 300), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      final c = widget.controller;
      if (c == null) return;
      // Only trigger if controller claims it's playing AND not buffering —
      // buffering is legitimate network wait, position not moving is
      // expected then.
      final value = c.value;
      if (!value.isPlaying || value.isBuffering) {
        _stuckTicks = 0;
        _lastPos = value.position;
        return;
      }
      final pos = value.position;
      if (pos == _lastPos) {
        _stuckTicks++;
        if (_stuckTicks >= 10) {
          // 10 × 300ms = 3s frozen while playing=true && !buffering.
          // Only triggers on truly stuck silent stalls,
          // not natural micro-buffering during cold-start.
          debugPrint(
              '[STUCK-RECOVER] player=$tag pos=${pos.inMilliseconds}ms frozen 3s — pause+play');
          c.pause();
          Future<void>.delayed(const Duration(milliseconds: 80), () {
            if (!mounted) return;
            if (widget.controller == c) c.play();
          });
          _stuckTicks = 0;
        }
      } else {
        _stuckTicks = 0;
        _lastPos = pos;
      }
    });
  }

  @override
  void dispose() {
    _detachListener(widget.controller);
    _watchdog?.cancel();
    _bufferDebounce?.cancel();
    _loadingDebounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final hasController = controller != null;
    final isReady = hasController && controller.value.isInitialized;
    final size = isReady ? controller.value.size : Size.zero;
    final videoReady = widget.isInitialized && isReady && size.width > 0;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Cover/shimmer always underneath — visible until video fades in.
        _coverOrShimmer(),

        // Mount the video widget early so the platform texture allocates
        // BEFORE the first decoded frame arrives. This eliminates the gap
        // where audio plays but video is invisible.
        //
        // RepaintBoundary isolates the video layer from parent repaints
        // (PageView swipe, buffering setState). Without it, the platform
        // texture re-composites on every parent rebuild, which is what
        // causes the "UI freezes but audio keeps playing" jank on low-end
        // devices.
        if (hasController && isReady)
          RepaintBoundary(
            child: AnimatedOpacity(
              opacity: videoReady ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 150),
              child: FittedBox(
                fit: BoxFit.cover,
                clipBehavior: Clip.hardEdge,
                child: SizedBox(
                  width: size.width,
                  height: size.height,
                  child: VideoPlayer(controller),
                ),
              ),
            ),
          ),

        // Loading indicator — debounced 1s so cover image shows first.
        if (!hasController || !widget.isInitialized)
          if (!widget.isProcessed)
            Center(child: _buildProcessingBadge())
          else if (_showLoading)
            const Center(
              child: SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  color: Colors.white54,
                  strokeWidth: 2,
                ),
              ),
            ),

        // Debounced buffering indicator — hides brief rebuffers on resume.
        if (hasController && widget.isInitialized && _showBuffering)
          const Center(
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2,
            ),
          ),
      ],
    );
  }

  Widget _buildProcessingBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              color: Colors.white70,
              strokeWidth: 2,
            ),
          ),
          SizedBox(width: 10),
          Text(
            'Обрабатывается...',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _coverOrShimmer() {
    if (widget.coverUrl != null && widget.coverUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: widget.coverUrl!,
        fit: BoxFit.cover,
        placeholder: (_, __) => const _ReelShimmer(),
        errorWidget: (_, __, ___) => const _ReelShimmer(),
      );
    }
    return const _ReelShimmer();
  }
}

/// Dark shimmer placeholder for the reels feed.
class _ReelShimmer extends StatelessWidget {
  const _ReelShimmer();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFF1A1A1A),
      highlightColor: const Color(0xFF2A2A2A),
      child: const ColoredBox(color: Colors.white),
    );
  }
}

/// Filter button in the right-side action column (under Share).
/// Pushes a full-screen picker, then applies the user's choice to ReelBloc.
/// Uses the same visual layout as other action buttons (icon + optional label)
/// so it reads as one system; highlights in accent blue when a filter is on.
/// Saves the current reel to the user's favorites ("Сохранённые публикации").
/// Replaces the old category filter — a reel is a video post, so it is
/// favorited by its post id exactly like a product.
class _ReelFavoriteButton extends StatelessWidget {
  const _ReelFavoriteButton({required this.reel, required this.isRegister});

  final ReelModel reel;
  final bool isRegister;

  void _toggle(BuildContext context, FavoriteResult? favorite) {
    if (!isRegister) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Чтобы сохранить публикацию, зарегистрируйтесь'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final bloc = context.read<FavoriteBloc>();
    if (favorite != null) {
      bloc.add(FavoriteDelete(id: favorite.id));
    } else {
      bloc.add(
        FavoriteCreateEvent(
          post: reel.id,
          favoriteResult: FavoriteResult(
            post: Product(
              id: reel.id,
              name: reel.description,
              coverImage: reel.coverUrl,
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FavoriteBloc, FavoriteState>(
      buildWhen: (prev, curr) => prev.results != curr.results,
      builder: (context, state) {
        final favorite =
            state.results.firstWhereOrNull((r) => r.post.id == reel.id);
        final isSaved = favorite != null;
        return _ReelActionButton(
          icon: isSaved ? Icons.bookmark : Icons.bookmark_border,
          color: isSaved ? const Color(0xFF0095D5) : Colors.white,
          label: '',
          onTap: () => _toggle(context, favorite),
        );
      },
    );
  }
}

/// Right-side action column: promote, like, comment, share
class _ReelRightActions extends StatelessWidget {
  final ReelModel reel;
  final bool isRegister;
  final String currentUserId;
  final VoidCallback onToggleLike;
  final VoidCallback onOpenComments;
  final int commentCount;
  final bool isUserAuthorized;

  const _ReelRightActions({
    required this.reel,
    required this.isRegister,
    required this.currentUserId,
    required this.onToggleLike,
    required this.onOpenComments,
    required this.commentCount,
    required this.isUserAuthorized,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 10.w,
      bottom: 100.h,
      child: Column(
        children: [
          _ReelActionButton(
            icon: reel.isLiked ? Icons.favorite : Icons.favorite_border,
            color: reel.isLiked ? Colors.red : Colors.white,
            label: reel.likes.toCompactFormat(),
            onTap: () {
              if (!isRegister) {
                debugPrint('[AUTH] reels like gate -> sign in');
                context.router.push(const SignInRoute());
                return;
              }

              if (!isUserAuthorized) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Требуется авторизация')),
                );
                return;
              }

              onToggleLike();
            },
          ),
          SizedBox(height: 20.h),
          _ReelActionButton(
            icon: Icons.chat_bubble_outline,
            color: Colors.white,
            label: commentCount.toCompactFormat(),
            onTap: () {
              if (!isRegister) {
                debugPrint('[AUTH] reels comment gate -> sign in');
                context.router.push(const SignInRoute());
                return;
              }

              if (!isUserAuthorized) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Требуется авторизация')),
                );
                return;
              }

              onOpenComments();
            },
          ),
          SizedBox(height: 20.h),
          _ReelActionButton(
            icon: Icons.share,
            color: Colors.white,
            label: '',
            onTap: () {
              final deepLink = 'https://optombai.com/reel/${reel.id}';
              final description = reel.description.trim();
              final text = <String>[
                'Смотри в ',
                if (description.isNotEmpty) description,
                deepLink,
              ].join('\n');
              SharePlus.instance.share(ShareParams(text: text));
            },
          ),
          SizedBox(height: 20.h),
          // Empty currentUserId means a guest — block/report need an account,
          // so only show the actions menu to an authenticated, non-owner user.
          if (currentUserId.isNotEmpty && reel.owner.id != currentUserId) ...[
            _ReelActionButton(
              icon: Icons.more_vert,
              color: Colors.white,
              label: '',
              onTap: () {
                // Capture the bloc now (valid context) so the deferred
                // onReported callback doesn't read a stale element.
                final reelBloc = context.read<ReelBloc>();
                UserActionsSheet.show(
                  context,
                  userId: reel.owner.id,
                  username: reel.owner.username,
                  // Feed reels come from /v2/posts/reels/ — each reel IS a
                  // video post, so report it as `post` (reporting as `stream`
                  // 404s: "Стрим не найден"). Removal + advance are handled by
                  // onReported, so the post type is purely the server contract.
                  reportTargetType: ReportTargetType.post,
                  reportTargetId: reel.id,
                  // Host-driven removal: drop the reel from ReelBloc so it
                  // vanishes immediately and the viewer advances to the next
                  // one (via the BlocConsumer reconcile) — without leaving reels.
                  onReported: () =>
                      reelBloc.add(OptimisticRemoveReelEvent(reel.id)),
                );
              },
            ),
            SizedBox(height: 20.h),
          ],
          _ReelFavoriteButton(reel: reel, isRegister: isRegister),
        ],
      ),
    );
  }
}

/// A single reel page: video + overlays + actions + owner card
class _ReelPage extends StatelessWidget {
  final ReelModel reel;
  final VideoPlayerController? controller;
  final bool isInitialized;
  final bool isProcessed;
  final String? coverUrl;
  final bool isProductVideo;
  final bool isRegister;
  final String currentUserId;
  final bool showLikeAnimation;
  final VoidCallback onTap;
  final VoidCallback onDoubleTap;
  final VoidCallback onToggleLike;
  final VoidCallback onOpenComments;
  final int commentCount;
  final bool isUserAuthorized;
  final bool isPaused;

  const _ReelPage({
    super.key,
    required this.reel,
    required this.controller,
    required this.isInitialized,
    this.isProcessed = true,
    this.coverUrl,
    required this.isProductVideo,
    required this.isRegister,
    required this.currentUserId,
    required this.showLikeAnimation,
    required this.isPaused,
    required this.onTap,
    required this.onDoubleTap,
    required this.onToggleLike,
    required this.onOpenComments,
    required this.commentCount,
    required this.isUserAuthorized,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTap: onDoubleTap,
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _ReelVideoPlayer(
            controller: controller,
            isInitialized: isInitialized,
            isProcessed: isProcessed,
            coverUrl: coverUrl,
          ),
          const _GradientsOverlay(),
          if (showLikeAnimation)
            Center(
              child: AnimatedOpacity(
                opacity: showLikeAnimation ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: Icon(
                  Icons.favorite,
                  size: 120.sp,
                  color: Colors.white,
                ),
              ),
            ),
          if (isPaused)
            Center(
              child: Container(
                width: 74,
                height: 74,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.pause_rounded,
                  color: Colors.white,
                  size: 44,
                ),
              ),
            ),
          _ReelRightActions(
            reel: reel,
            isRegister: isRegister,
            currentUserId: currentUserId,
            onToggleLike: onToggleLike,
            onOpenComments: onOpenComments,
            commentCount: commentCount,
            isUserAuthorized: isUserAuthorized,
          ),
          Positioned(
            bottom: isProductVideo ? 110.h : 20.h,
            left: 12.w,
            right: 70.w,
            child: ReelOwnerCard(
              owner: reel.owner,
              views: reel.views,
              isPromoted: reel.isPromoCard,
              productName: reel.description,
            ),
          ),
        ],
      ),
    );
  }
}

/// Shown when the reels feed fetch fails and no reels are loaded yet.
/// Without this, a transient network error left the screen stuck on the
/// generic "Видео пока нет" text with no way to recover short of an app
/// restart — this gives the user a way to retry directly.
class _ReelsFetchErrorState extends StatelessWidget {
  const _ReelsFetchErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off_rounded, color: Colors.white54, size: 40),
          SizedBox(height: 12.h),
          const Text(
            'Не удалось загрузить видео',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 16.h),
          OutlinedButton(
            onPressed: onRetry,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white54),
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 10.h),
            ),
            child: const Text('Повторить'),
          ),
        ],
      ),
    );
  }
}
