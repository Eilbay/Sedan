import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';
import 'package:optombai/core/debug/talker_instance.dart';
import 'package:optombai/core/error/global_error_handler.dart';
import 'package:optombai/core/error/reel_log_file.dart';
import 'package:optombai/services/i_player_factory.dart';
import 'package:optombai/services/i_video_pre_buffer_service.dart';

/// Manages the lifecycle of [VideoPlayerController]s for a reels feed.
///
/// Responsibilities: init, play, pause, dispose.
/// Does NOT know about BLoC, UI, or impression tracking.
///
/// Traffic policy: current reel is initialized immediately; the next reel
/// is preloaded after [_preloadDelay] when the user settles on a reel.
///
/// Fast-scroll safety: each call to [initControllers] bumps [_generation].
/// Async inits re-check generation after every await and abort early if the
/// user already scrolled away, preventing stale downloads from competing
/// for bandwidth with the current video.
class ReelPlaybackManager {
  ReelPlaybackManager({
    IPlayerFactory? playerFactory,
    IVideoPreBufferService? preBufferService,
  })  : _playerFactory = playerFactory,
        _preBufferService = preBufferService;

  /// Player instances keyed by reel index.
  final Map<int, VideoPlayerController> players = {};

  /// Whether the player at index is initialized (first frame ready).
  final Map<int, bool> initialized = {};

  final Set<int> _pendingInit = {};
  final Map<int, String> _playerUrls = {};
  final IPlayerFactory? _playerFactory;
  final IVideoPreBufferService? _preBufferService;

  int? _playingIndex;
  int? _currentCenterIndex;
  bool _isActive = false;
  int _generation = 0;
  bool _disposed = false;

  Timer? _preloadTimer;
  int _preloadReelCount = 0;
  String Function(int index)? _preloadUrlsAt;

  VoidCallback? _onCurrentReady;

  static const _preloadDelay = Duration(milliseconds: 100);

  /// Logs a per-video playback event to both Talker and the dedicated
  /// `reel_log.txt` — this is what actually explains a "Видео пока нет"
  /// report: cold-start misses, timeouts, and stale-generation aborts were
  /// previously only visible via `debugPrint`, which stdout-only builds
  /// (and crash reports) never capture.
  void _logReel(String message, {bool isWarning = false}) {
    if (isWarning) {
      talker.warning(message);
    } else {
      talker.info(message);
    }
    ReelLogFile.append('[${DateTime.now().toIso8601String()}] $message\n');
  }

  /// Initialize the current video immediately.
  /// After it starts playing and user stays for [_preloadDelay],
  /// the next video is preloaded in the background.
  /// When [isActive] is false (tab not visible), skip init entirely.
  void initControllers({
    required int centerIndex,
    required int reelCount,
    required String Function(int index) urlsAt,
    required bool isActive,
    required VoidCallback onCurrentReady,
  }) {
    if (_disposed ||
        reelCount == 0 ||
        centerIndex < 0 ||
        centerIndex >= reelCount) {
      return;
    }

    _preloadTimer?.cancel();
    _generation++;
    _currentCenterIndex = centerIndex;
    _isActive = isActive;
    _preloadReelCount = reelCount;
    _preloadUrlsAt = urlsAt;
    _onCurrentReady = onCurrentReady;

    _pausePrevious(centerIndex);

    if (!isActive) {
      pauseAll();
      return;
    }

    disposeOutOfRange(centerIndex);

    if (!players.containsKey(centerIndex)) {
      if (_pendingInit.contains(centerIndex)) {
        _logReel(
            '[REEL] initControllers: pending init for $centerIndex, waiting');
        return;
      }

      final centerUrl = urlsAt(centerIndex);
      if (centerUrl.isEmpty) return;

      final gen = _generation;
      _initPlayer(
        centerIndex,
        generation: gen,
        streamUrl: centerUrl,
        isActive: true,
        onReady: () {
          onCurrentReady();
          _schedulePreload(centerIndex, gen);
        },
      );
    } else {
      _logReel('[REEL] resume existing player index=$centerIndex');
      playVideo(centerIndex, isActive: true);
      _schedulePreload(centerIndex, _generation);
    }
  }

  void _schedulePreload(int centerIndex, int generation) {
    _preloadTimer?.cancel();
    _preloadTimer = null;

    final urlsAt = _preloadUrlsAt;
    if (urlsAt == null) return;

    _maybePreloadIndex(
      targetIndex: centerIndex + 1,
      centerIndex: centerIndex,
      generation: generation,
      urlsAt: urlsAt,
      withDelay: true,
    );

    _maybePreloadIndex(
      targetIndex: centerIndex - 1,
      centerIndex: centerIndex,
      generation: generation,
      urlsAt: urlsAt,
      withDelay: false,
    );
  }

  void _maybePreloadIndex({
    required int targetIndex,
    required int centerIndex,
    required int generation,
    required String Function(int) urlsAt,
    required bool withDelay,
  }) {
    if (targetIndex < 0 || targetIndex >= _preloadReelCount) return;
    if (players.containsKey(targetIndex) ||
        _pendingInit.contains(targetIndex)) {
      return;
    }

    void doPreload() {
      if (_disposed || _generation != generation || !_isActive) return;
      if (_currentCenterIndex != centerIndex) return;

      final url = urlsAt(targetIndex);
      if (url.isEmpty) return;

      _logReel('[REEL] preloading index=$targetIndex');
      _initPlayer(
        targetIndex,
        generation: generation,
        streamUrl: url,
        isActive: true,
        onReady: null,
      );
    }

    if (withDelay) {
      _preloadTimer = Timer(_preloadDelay, doPreload);
    } else {
      doPreload();
    }
  }

  void reconcile({
    required int newReelCount,
    required String Function(int index) reelIdAt,
    required String Function(int index) oldReelIdAt,
    required int oldReelCount,
  }) {
    final keysToRemove = <int>[];
    for (final key in players.keys) {
      if (key >= newReelCount) {
        keysToRemove.add(key);
      } else if (key < oldReelCount && oldReelIdAt(key) != reelIdAt(key)) {
        keysToRemove.add(key);
      }
    }
    for (final key in keysToRemove) {
      _pendingInit.remove(key);
      final controller = players.remove(key);
      if (controller != null) unawaited(controller.dispose());
      _playerUrls.remove(key);
      initialized.remove(key);
    }
  }

  Future<void> _initPlayer(
    int index, {
    required int generation,
    required String streamUrl,
    required bool isActive,
    required VoidCallback? onReady,
    bool isRetry = false,
  }) async {
    if (streamUrl.isEmpty) return;
    if (_pendingInit.contains(index) || players.containsKey(index)) return;

    _pendingInit.add(index);

    // Try pre-buffered player first (instant, no network).
    final preBuffered = _preBufferService?.take(streamUrl);
    if (preBuffered != null) {
      if (_disposed) {
        unawaited(preBuffered.controller.dispose());
        _pendingInit.remove(index);
        return;
      }
      if (_generation != generation) {
        // Stale generation — user scrolled away. Return controller to pool
        // instead of installing it.
        _preBufferService?.returnToPool(
          streamUrl,
          PreBufferedPlayer(controller: preBuffered.controller),
        );
        _pendingInit.remove(index);
        return;
      }
      _pendingInit.remove(index);
      _logReel('[REEL] using pre-buffered player index=$index');
      players[index] = preBuffered.controller;
      _playerUrls[index] = streamUrl;
      initialized[index] = true;
      if (_isActive && _currentCenterIndex == index) {
        _pausePrevious(index);
        unawaited(preBuffered.controller.setVolume(1));
        unawaited(preBuffered.controller.play());
        _playingIndex = index;
      }
      // Controller is already initialized — onReady is fired anyway so the
      // UI can rebuild and attach the VideoPlayer widget to the controller.
      onReady?.call();
      _schedulePreload(index, generation);
      return;
    }

    // Pre-buffer miss — creating player from scratch (this causes progress bar).
    final sw = Stopwatch()..start();
    _logReel(
        '[REEL] PRE-BUFFER MISS index=$index — cold start from network');

    try {
      // Stale generation, but user landed back on this exact index in the new
      // generation — keep the controller and reuse it instead of cold-restarting.
      if (_generation != generation && _currentCenterIndex != index) {
        _logReel(
            '[REEL] STALE before open index=$index (gen=$generation, cur=$_generation)',
            isWarning: true);
        _pendingInit.remove(index);
        return;
      }

      // Let in-flight pre-buffer finish — the controller will land in
      // the ready pool and serve a neighbouring reel. Cancelling here
      // would kill a nearly-done download and force a cold start.

      final controller = _playerFactory?.createReelPlayer(streamUrl) ??
          VideoPlayerController.networkUrl(Uri.parse(streamUrl));

      // initialize() resolves when the first frame is decoded and the
      // video size is known — no separate width-stream wait needed.
      try {
        await controller.initialize().timeout(const Duration(seconds: 10));
      } on TimeoutException {
        if (!controller.value.isInitialized) {
          throw TimeoutException(
            'Video opened, but first frame was not decoded',
            const Duration(seconds: 10),
          );
        }
      }

      // Preloaded controller stays paused at zero (will be resumed when
      // user scrolls to it). Wrapped in try because a controller can be
      // mid-disposal on slow devices; we don't want to crash a preload.
      final isCenterNow = _currentCenterIndex == index;
      if (!isCenterNow) {
        try {
          await controller.pause();
          await controller.seekTo(Duration.zero);
        } catch (e, st) {
          GlobalErrorHandler.handleError(
            e,
            st,
            source: ErrorSource.videoPlayer,
          );
        }
      }

      _logReel(
          '[TIMING] controller.initialize index=$index ${sw.elapsedMilliseconds}ms');

      _pendingInit.remove(index);
      if (_disposed) {
        await controller.dispose();
        return;
      }

      final isCurrent = _currentCenterIndex == index;
      // Stale generation, but user landed back on this exact index in the new
      // generation — keep the controller and reuse it instead of cold-restarting.
      if (_generation != generation && !isCurrent) {
        _logReel(
            '[REEL] STALE after init index=$index ${sw.elapsedMilliseconds}ms — disposing',
            isWarning: true);
        await controller.dispose();
        return;
      }

      _logReel('[REEL] init DONE index=$index ${sw.elapsedMilliseconds}ms');

      if (players.containsKey(index)) {
        await controller.dispose();
        return;
      }

      // Re-check _disposed immediately before installing the controller to
      // close the race window between the earlier check and this write.
      if (_disposed) {
        await controller.dispose();
        return;
      }

      players[index] = controller;
      _playerUrls[index] = streamUrl;
      initialized[index] = true;

      final isActiveAndCurrent = _isActive && isCurrent;
      if (isActive && isActiveAndCurrent) {
        _pausePrevious(index);
        // Unmute and play the center reel.
        unawaited(controller.setVolume(1));
        unawaited(controller.play());
        _playingIndex = index;
      }

      if (onReady != null) {
        onReady.call();
      } else if (isActiveAndCurrent) {
        _logReel('[REEL] preload became current index=$index — notifying UI');
        _onCurrentReady?.call();
        _schedulePreload(index, generation);
      }
    } catch (error) {
      _pendingInit.remove(index);
      _logReel('[REEL] init FAILED index=$index: $error', isWarning: true);
      players.remove(index);
      initialized.remove(index);

      if (!isRetry && !_disposed && _generation == generation) {
        await Future<void>.delayed(const Duration(seconds: 1));
        if (!_disposed &&
            !players.containsKey(index) &&
            _generation == generation) {
          unawaited(_initPlayer(index,
              generation: generation,
              streamUrl: streamUrl,
              isActive: isActive,
              onReady: onReady,
              isRetry: true));
        }
      }
    }
  }

  void playVideo(int index, {required bool isActive}) {
    _pausePrevious(index);

    if (!isActive) return;

    final controller = players[index];
    if (controller != null && initialized[index] == true) {
      unawaited(controller.setVolume(1));
      unawaited(controller.play());
      _playingIndex = index;
    }
  }

  void pauseAll() {
    _isActive = false;
    for (final controller in players.values) {
      if (controller.value.isPlaying) {
        unawaited(controller.pause());
      }
    }
    _playingIndex = null;
  }

  void resume(int index) {
    final controller = players[index];
    if (controller != null && initialized[index] == true) {
      _pausePrevious(index);
      unawaited(controller.setVolume(1));
      unawaited(controller.play());
      _playingIndex = index;
    }
  }

  bool togglePlayPause(int index) {
    final controller = players[index];
    if (controller == null || initialized[index] != true) return false;

    if (controller.value.isPlaying) {
      unawaited(controller.pause());
      return false;
    } else {
      _pausePrevious(index);
      unawaited(controller.setVolume(1));
      unawaited(controller.play());
      return true;
    }
  }

  /// Range of active reel-manager controllers around the current index.
  /// Total active = 2 * _activeRange + 1 (center + 2 above + 2 below = 5).
  /// Reduced from 3 to 2 (2026-05-18) — saves one controller (~30MB) on
  /// device while keeping the immediate-neighbour swipe instant. Further
  /// reels are still served by the pre-buffer pool (FIFO, capped).
  static const int _activeRange = 2;

  /// Return players outside the [_activeRange] back to the pre-buffer pool.
  /// Falls back to dispose if the pool is unavailable.
  void disposeOutOfRange(int centerIndex) {
    final keysToRemove = <int>[];
    for (final key in players.keys) {
      if ((key - centerIndex).abs() > _activeRange) {
        keysToRemove.add(key);
      }
    }
    for (final key in keysToRemove) {
      _pendingInit.remove(key);

      final controller = players.remove(key);
      final url = _playerUrls.remove(key);
      initialized.remove(key);

      // Return to pool instead of disposing — allows instant replay on backward scroll.
      if (controller != null && url != null && _preBufferService != null) {
        _preBufferService!.returnToPool(
          url,
          PreBufferedPlayer(controller: controller),
        );
      } else if (controller != null) {
        unawaited(controller.dispose());
      }
    }
  }

  void _pausePrevious(int newIndex) {
    if (_playingIndex != null && _playingIndex != newIndex) {
      final prev = players[_playingIndex];
      if (prev != null) _pauseAndRewind(prev);
      _playingIndex = null;
    } else if (_playingIndex == null) {
      for (final entry in players.entries) {
        if (entry.key != newIndex && entry.value.value.isPlaying) {
          _pauseAndRewind(entry.value);
        }
      }
    }
  }

  /// Pause a reel the user is navigating away from and rewind it to the start.
  /// Rewinding now — while the reel is off-screen — lets ExoPlayer re-buffer
  /// the opening frames in the background (its default back-buffer is 0, so a
  /// played-past start is otherwise dropped). A swipe back then replays
  /// instantly from 0 instead of cold-loading from the network on screen.
  void _pauseAndRewind(VideoPlayerController controller) {
    unawaited(controller.pause());
    unawaited(controller.seekTo(Duration.zero));
  }

  void dispose() {
    _disposed = true;
    _preloadTimer?.cancel();
    for (final controller in players.values) {
      unawaited(controller.dispose());
    }
    players.clear();
    _playerUrls.clear();
    initialized.clear();
    _pendingInit.clear();
    _onCurrentReady = null;
  }
}
