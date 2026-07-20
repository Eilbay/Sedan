import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:dio/dio.dart';
import 'package:optombai/core/debug/talker_instance.dart';
import 'package:optombai/core/theme_notifier.dart';
import 'package:optombai/core/di/injection.dart';
import 'package:optombai/app/router/app_router.dart';
import 'package:optombai/bloc/user_bloc/user_bloc.dart';
import 'package:optombai/bloc/reel_bloc/reel_bloc.dart';
import 'package:optombai/services/i_video_pre_buffer_service.dart';
import 'package:optombai/pages/reels/reels_viewer_screen.dart';
import 'package:optombai/features/live_stream/presentation/logic/stream_cubit.dart';
import 'package:optombai/features/live_stream/presentation/pages/watch_stream_page.dart';
import 'package:optombai/widgets/category_tabs.dart';
import 'package:auto_route/auto_route.dart';

@RoutePage()
class StreamPage extends StatefulWidget {
  const StreamPage({
    super.key,
    required this.userId,
    this.isActive = true,
    this.keepLivePlayerAlive = false,
  });

  final String userId;
  final bool isActive;
  final bool keepLivePlayerAlive;

  @override
  State<StreamPage> createState() => _StreamPageState();
}

class _StreamPageState extends State<StreamPage> {
  late PageController _pageController;
  int _currentIndex = 0;
  DateTime? _lastStreamRequestAt;
  bool _isStartingStream = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !widget.isActive) return;
      _ensureStreamsLoaded();
      _ensurePreBufferForReels();
    });
  }

  @override
  void didUpdateWidget(covariant StreamPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isActive && widget.isActive) {
      _ensureStreamsLoaded();
      _ensurePreBufferForReels();
      context.read<ReelBloc>().add(FetchReelsEvent());
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Resume pre-buffer and enqueue the first reel URLs so playback
  /// is ready as soon as the page opens.
  void _ensurePreBufferForReels() {
    final reels = context.read<ReelBloc>().state.reels;
    if (reels.isEmpty) return;

    final preBuffer = getIt<IVideoPreBufferService>();
    preBuffer.resume();

    final urls = reels
        .take(10)
        .map((r) => r.playbackUrl)
        .where((u) => u.isNotEmpty)
        .toList();

    if (urls.isNotEmpty) {
      preBuffer.enqueue(urls);
      talker.info('[PRE-BUFFER] enqueued ${urls.length} reel URLs');
    }
  }

  void _ensureStreamsLoaded() {
    final now = DateTime.now();
    if (_lastStreamRequestAt != null &&
        now.difference(_lastStreamRequestAt!) < const Duration(seconds: 5)) {
      return;
    }

    final streamCubit = context.read<StreamCubit>();
    final streamState = streamCubit.state;
    final hasStreams = (streamState.streams?.results.isNotEmpty ?? false);

    if (streamState.status == StreamStatus.loading) return;

    if (streamState.status == StreamStatus.initial ||
        streamState.status == StreamStatus.error ||
        !hasStreams) {
      _lastStreamRequestAt = now;
      streamCubit.getStreams();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isRegister = context.select((ThemeNotifier n) => n.isRegister);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
              if (index == 1) {
                _ensureStreamsLoaded();
              }
            },
            children: <Widget>[
              BlocBuilder<ReelBloc, ReelState>(
                buildWhen: (previous, current) =>
                    previous.reels != current.reels ||
                    previous.isLoading != current.isLoading,
                builder: (context, state) {
                  if (state.isLoading && state.reels.isEmpty) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Colors.blue,
                      ),
                    );
                  }

                  if (state.reels.isEmpty) {
                    return const Center(
                      child: Text(
                        'Видео пока нет',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }

                  return ReelsViewerScreen(
                    reels: state.reels,
                    initialIndex: 0,
                    isActive: widget.isActive && _currentIndex == 0,
                  );
                },
              ),
              WatchStreamPage(
                isActive: widget.isActive && _currentIndex == 1,
                keepPlayersAlive:
                    widget.keepLivePlayerAlive && _currentIndex == 1,
              ),
            ],
          ),
          Positioned(
            top: MediaQuery.paddingOf(context).top + 10.h,
            left: 0,
            right: 0,
            child: Center(
              child: Stack(
                children: [
                  Center(
                    child: CategoryTabs(
                      currentIndex: _currentIndex,
                      labels: const ['Рилсы', 'Прямые эфиры'],
                      backgroundColor: Colors.transparent,
                      spacing: 6.w.toInt().toDouble(),
                      onTap: (index) => _pageController.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      ),
                    ),
                  ),
                  if (_currentIndex == 1)
                    Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: InkWell(
                          onTap: () {
                            if (!isRegister) {
                              debugPrint('[AUTH] stream gate -> sign in');
                              context.router.push(const SignInRoute());
                              return;
                            }
                            final token = context.read<UserBloc>().getToken();
                            if (token.isNotEmpty) {
                              _startStream(context, token);
                            }
                          },
                          child: const Icon(Icons.live_tv, color: Colors.white),
                        ),
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

  Future<void> _startStream(BuildContext context, String token) async {
    if (_isStartingStream) return;
    _isStartingStream = true;

    try {
      if (token.isEmpty) return;

      final streamCubit = context.read<StreamCubit>();
      final stream = await streamCubit.createStream(ownerId: widget.userId);
      if (stream == null) return;

      if (!context.mounted) {
        await streamCubit.endStream(stream.id);
        return;
      }

      // Derive SRS native publish URL from the webrtc stream URL.
      // stream.webrtc.apiUrl is always empty; the native SRS API works without auth.
      final webrtcUri = Uri.tryParse(
        stream.webrtc.url.replaceFirst('webrtc://', 'https://'),
      );
      final srsHost = webrtcUri?.host ?? 'optombai.com';
      final publishUrl = 'https://$srsHost/rtc/v1/publish/';

      await context.router.push(CreateStreamRoute(
        onEndStream: (v) async {
          await streamCubit.endStream(v);
        },
        isHost: true,
        streamId: stream.id,
        streamKey: stream.streamKey,
        publishApiUrl: publishUrl,
        streamUrl: stream.webrtc.url,
        authToken: token,
      ));

      if (context.mounted) {
        await streamCubit.getStreams(force: true);
      }
    } on DioException catch (e) {
      if (!context.mounted) return;
      final code = e.response?.statusCode;
      final message = code != null
          ? 'Ошибка запуска эфира ($code)'
          : 'Ошибка запуска эфира';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ошибка запуска эфира')),
      );
    } finally {
      _isStartingStream = false;
    }
  }
}
