import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:optombai/core/import_links.dart';
import 'package:optombai/features/live_stream/data/models/live_stream_model.dart';
import 'package:optombai/features/live_stream/presentation/logic/stream_cubit.dart';
import 'package:optombai/features/live_stream/presentation/logic/stream_player_pool.dart';
import 'package:optombai/features/live_stream/presentation/pages/stream_reel_preview.dart';
import 'package:optombai/widgets/translation/text_translated.dart';

class WatchStreamPage extends StatefulWidget {
  const WatchStreamPage({
    super.key,
    this.isActive = true,
    this.keepPlayersAlive = false,
  });

  final bool isActive;
  final bool keepPlayersAlive;

  @override
  State<WatchStreamPage> createState() => _WatchStreamPageState();
}

class _WatchStreamPageState extends State<WatchStreamPage> {
  late final PageController _controller;
  StreamPlayerPool? _pool;
  int _visiblePageIndex = 0;
  Timer? _autoRefreshTimer;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
    if (widget.isActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _bootstrapStreamsIfNeeded();
      });
      _startAutoRefresh();
    }
  }

  @override
  void didUpdateWidget(covariant WatchStreamPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive && !widget.isActive) {
      if (widget.keepPlayersAlive) {
        // LiveRoomPage reuses this pool's cubit/renderer while its route is on
        // top. Keep the connection but hand audio ownership to that route.
        _pool?.pauseAll();
      } else {
        _pool?.disposeAll();
        _pool = null;
      }
      _autoRefreshTimer?.cancel();
      return;
    }

    if (!widget.isActive &&
        oldWidget.keepPlayersAlive &&
        !widget.keepPlayersAlive) {
      _pool?.disposeAll();
      _pool = null;
    }

    if (!oldWidget.isActive && widget.isActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _bootstrapStreamsIfNeeded();
      });
      _startAutoRefresh();
    }
  }

  /// Refresh stream list every 30 s to remove ended streams that the player
  /// hasn't detected yet (e.g. streams the user hasn't opened).
  void _startAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted) return;
      context.read<StreamCubit>().getStreams(force: true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _pool?.disposeAll();
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  StreamPlayerPool _getPool() {
    _pool ??= StreamPlayerPool(
      repository: context.read<StreamCubit>().repository,
    );
    return _pool!;
  }

  void _bootstrapStreamsIfNeeded() {
    final streamCubit = context.read<StreamCubit>();
    if (streamCubit.state.status == StreamStatus.loading) return;
    // Always fetch fresh data — getStreams() has its own 10s debounce,
    // so this won't cause excessive network calls. The cache is shown
    // immediately while the fresh response arrives.
    streamCubit.getStreams();
  }

  void _preparePlayerWindow(List<StreamModel> items, int activeIndex) {
    if (!mounted || !widget.isActive || items.isEmpty) return;

    final pool = _getPool();
    final activeStream = items[activeIndex];

    String? prepareAt(int index) {
      if (index < 0 || index >= items.length) return null;
      final stream = items[index];
      pool.getOrCreate(
        streamId: stream.id,
        playApiUrl: stream.playApiUrl,
        streamUrl: stream.webrtc.url,
        index: index,
      );
      pool.ensureInitialized(stream.id);
      return stream.id;
    }

    final previousStreamId = prepareAt(activeIndex - 1);
    final activeStreamId = prepareAt(activeIndex)!;
    final nextStreamId = prepareAt(activeIndex + 1);

    pool.keepWithNeighbors(
      activeStreamId,
      previousStreamId: previousStreamId,
      nextStreamId: nextStreamId,
    );
    pool.setActiveStream(activeStream.id);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isActive) {
      return const ColoredBox(color: Colors.black);
    }

    return MediaQuery.removePadding(
      context: context,
      removeTop: true,
      removeBottom: true,
      child: RefreshIndicator.adaptive(
        onRefresh: () => context.read<StreamCubit>().getStreams(force: true),
        child: BlocBuilder<StreamCubit, StreamState>(
          buildWhen: (previous, current) =>
              previous.status != current.status ||
              previous.streams != current.streams,
          builder: (context, state) {
            final Streams? model = state.streams;
            if ((state.status == StreamStatus.loading ||
                    state.status == StreamStatus.initial) &&
                model == null) {
              return const _RefreshableEmptyState(
                icon: Icons.live_tv,
                text: 'Загрузка эфиров...',
              );
            }

            if (state.status == StreamStatus.error && model == null) {
              return const _RefreshableEmptyState(
                icon: Icons.video_library_outlined,
                text: 'Пока нет активных эфиров',
              );
            }

            final now = DateTime.now();
            final currentUserId = context.read<UserBloc>().state.user.id;
            final bannedIds = state.bannedStreamIds;
            // A stream marked live but started more than 24 hours ago is
            // considered a ghost — the backend failed to close it cleanly.
            // Real live streams almost never exceed 24 hours.
            // Also hide the current user's own stream and streams they're banned from.
            final deduplicated = model == null
                ? const <StreamModel>[]
                : deduplicateStreamsByOwner(model).results;
            final List<StreamModel> items = deduplicated
                .where((s) => s.isLive == true)
                .where((s) => s.owner.id != currentUserId)
                .where((s) => !bannedIds.contains(s.id))
                .where((s) {
              if (s.startedAt == null) return true;
              return now.difference(s.startedAt!) < const Duration(hours: 24);
            }).toList();

            if (items.isEmpty) {
              return const _RefreshableEmptyState(
                icon: Icons.video_library_outlined,
                text: 'Пока нет активных эфиров',
              );
            }

            final pool = _getPool();
            final int activeIndex = _visiblePageIndex < 0
                ? 0
                : (_visiblePageIndex >= items.length
                    ? items.length - 1
                    : _visiblePageIndex);

            WidgetsBinding.instance.addPostFrameCallback((_) {
              _preparePlayerWindow(items, activeIndex);
            });

            return PageView.builder(
              controller: _controller,
              scrollDirection: Axis.vertical,
              itemCount: items.length,
              onPageChanged: (index) {
                if (_visiblePageIndex != index) {
                  setState(() => _visiblePageIndex = index);
                }
                context.read<StreamCubit>().setCurrentIndex(index);
                _preparePlayerWindow(items, index);
              },
              itemBuilder: (context, index) {
                final stream = items[index];
                final isActive = index == activeIndex;
                final cubit = pool.getOrCreate(
                  streamId: stream.id,
                  playApiUrl: stream.playApiUrl,
                  streamUrl: stream.webrtc.url,
                  index: index,
                );
                cubit.setActive(widget.isActive && isActive);
                if (widget.isActive && isActive) {
                  pool.ensureInitialized(stream.id);
                }

                return BlocProvider.value(
                  key: ValueKey('live-stream-${stream.id}'),
                  value: cubit,
                  child: StreamReelPreview(
                    stream: stream,
                    isActive: isActive,
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

/// Loading/error/empty placeholder for the streams list.
/// Wrapped in a scrollable so the parent `RefreshIndicator` (which only
/// reacts to scroll gestures from a Scrollable descendant) still responds
/// to pull-to-refresh when there's nothing to show yet.
class _RefreshableEmptyState extends StatelessWidget {
  const _RefreshableEmptyState({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: constraints.maxHeight,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 80.sp, color: Colors.grey),
                  SizedBox(height: 16.h),
                  TextTranslated(
                    text,
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
