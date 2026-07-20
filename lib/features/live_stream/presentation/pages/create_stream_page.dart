import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:optombai/bloc/auth_bloc/auth_cubit.dart';
import 'package:optombai/bloc/user_bloc/user_bloc.dart';
import 'package:optombai/features/live_stream/data/data_sources/web_rtc.dart';
import 'package:optombai/features/live_stream/presentation/logic/live_chat_cubit.dart';
import 'package:optombai/features/live_stream/presentation/logic/stream_ban_cubit.dart';
import 'package:optombai/features/live_stream/presentation/logic/stream_cubit.dart';
import 'package:optombai/features/live_stream/presentation/widgets/ban_user_bottom_sheet.dart';
import 'package:optombai/features/live_stream/presentation/widgets/countdown_overlay.dart';
import 'package:optombai/features/live_stream/presentation/widgets/live_chat_widget.dart';
import 'package:optombai/features/live_stream/presentation/widgets/live_badge.dart';
import 'package:optombai/features/live_stream/presentation/widgets/viewers_bottom_sheet.dart';
import 'package:auto_route/auto_route.dart';

@RoutePage()
class CreateStreamPage extends StatefulWidget {
  const CreateStreamPage({
    super.key,
    required this.isHost,
    required this.streamId,
    required this.streamKey,
    required this.publishApiUrl,
    required this.streamUrl,
    required this.authToken,
    required this.onEndStream,
  });

  final bool isHost;
  final String streamId;
  final String streamKey;

  /// SRS publish API URL from create response, e.g. `https://optombai.com/rtc/v1/publish/`.
  final String publishApiUrl;

  /// WebRTC stream URL, e.g. `webrtc://optombai.com/live/STREAM_KEY`.
  final String streamUrl;

  final String? authToken;
  final Future<void> Function(String) onEndStream;

  @override
  State<CreateStreamPage> createState() => _CreateStreamPageState();
}

class _CreateStreamPageState extends State<CreateStreamPage>
    with WidgetsBindingObserver {
  late final LiveStreamWebRtcPublisher _publisher;

  bool _showCountdown = false;
  bool _isLoading = false;
  bool _streamEnded = false;
  String? _errorMessage;
  Timer? _heartbeatTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _publisher = LiveStreamWebRtcPublisher(
      publishApiUrl: widget.publishApiUrl,
      streamUrl: widget.streamUrl,
    );

    _showCountdown = widget.isHost;

    // Mark this stream as actively broadcasting so it can be cleaned up
    // on next launch if the app gets killed.
    context.read<StreamCubit>().setActiveBroadcast(widget.streamId);

    _init();
  }

  Future<void> _init() async {
    try {
      await _publisher.init();

      if (!widget.isHost) {}
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Ошибка инициализации камеры: $e';
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      // `hidden` fires on iOS when the app moves to background (before `paused`).
      // Starting cleanup here gives the HTTP request more time before OS suspension.
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _endStreamSilently();
      case AppLifecycleState.inactive:
      case AppLifecycleState.resumed:
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _heartbeatTimer?.cancel();
    _endStreamSilently();
    _publisher.dispose();
    super.dispose();
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    final streamCubit = context.read<StreamCubit>();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 25), (_) {
      streamCubit.sendHeartbeat(widget.streamId);
    });
  }

  /// Server already ended the broadcast (superseded/admin/timeout) — stop
  /// publishing and leave without re-sending the outbound end-stream call.
  void _onStreamForceEnded(String? reason) {
    debugPrint(
        '[CreateStreamPage] stream.ended reason=$reason for ${widget.streamId}');
    _heartbeatTimer?.cancel();
    _streamEnded = true;
    try {
      _publisher.stop();
    } catch (e) {
      debugPrint('[CreateStreamPage] Error stopping publisher: $e');
    }
    if (!mounted) return;
    context.router.maybePop();
  }

  /// End the stream without navigating away. Safe to call multiple times.
  ///
  /// The publisher is stopped synchronously so WebRTC disconnects immediately.
  /// The API call is fire-and-forget: if the OS suspends the app before it
  /// completes, [StreamCubit.endLeftoverBroadcast] will finish the job on the
  /// next app launch (the stream ID is stored in SharedPreferences).
  void _endStreamSilently() {
    if (_streamEnded) return;
    _streamEnded = true;
    _heartbeatTimer?.cancel();

    debugPrint('[CreateStreamPage] Ending stream ${widget.streamId}...');

    try {
      _publisher.stop();
      debugPrint('[CreateStreamPage] Publisher stopped');
    } catch (e) {
      debugPrint('[CreateStreamPage] Error stopping publisher: $e');
    }

    // Fire-and-forget — do NOT await; OS may suspend before completion.
    widget.onEndStream(widget.streamId).then((_) {
      debugPrint(
          '[CreateStreamPage] endStream API completed for ${widget.streamId}');
    }).catchError((Object e) {
      debugPrint('[CreateStreamPage] Error ending stream via API: $e');
    });
  }

  void _onCountdownFinished() {
    setState(() => _showCountdown = false);
    _startHostPublish();
  }

  Future<void> _startHostPublish() async {
    final streamCubit = context.read<StreamCubit>();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _publisher.start().timeout(const Duration(seconds: 20));
      final started = await streamCubit.startStream(widget.streamId);
      if (!started) {
        debugPrint(
          'CreateStreamPage: stream started in WebRTC, but API startStream returned null/error for ${widget.streamId}',
        );
      } else {
        _startHeartbeat();
      }

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    } on TimeoutException {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Превышено время ожидания. Проверьте соединение.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Не удалось запустить эфир: $e';
      });
    }
  }

  Future<void> _onClosePressed() async {
    debugPrint('[CreateStreamPage] Close pressed');
    _endStreamSilently();
    debugPrint('[CreateStreamPage] Stream ended, navigating back');

    if (!mounted) return;
    context.router.maybePop();
  }

  void _showBanSheet(BuildContext ctx, ChatMessage message) {
    if (message.userId.isEmpty) return;
    BanUserBottomSheet.show(
      ctx,
      username: message.username,
      userId: message.userId,
      messenger: ScaffoldMessenger.of(ctx),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<UserBloc>().state.user;

    if (widget.isHost && _showCountdown) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: CountdownOverlay(onCountdownFinished: _onCountdownFinished),
      );
    }

    if (_isLoading || _errorMessage != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: _errorMessage != null
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    const Icon(Icons.error_outline,
                        color: Colors.red, size: 48),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: _startHostPublish,
                          child: const Text('Повторить'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: _onClosePressed,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[800],
                          ),
                          child: const Text('Закрыть'),
                        ),
                      ],
                    ),
                  ],
                )
              : const CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    final RTCVideoRenderer renderer =
        widget.isHost ? _publisher.localRenderer : RTCVideoRenderer();

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => LiveChatCubit(
            streamUuid: widget.streamId,
            token: widget.authToken ?? '',
          )..connect(),
        ),
        BlocProvider(
          create: (ctx) => StreamBanCubit(
            repository: ctx.read<StreamCubit>().repository,
            token: ctx.read<AuthCubit>().getToken(),
            streamId: widget.streamId,
          ),
        ),
      ],
      child: Builder(builder: (ctx) {
        return BlocListener<LiveChatCubit, LiveChatState>(
          listenWhen: (previous, current) =>
              !previous.streamEnded && current.streamEnded,
          listener: (_, state) => _onStreamForceEnded(state.endReason),
          child: Scaffold(
            backgroundColor: Colors.black,
            body: Stack(
              children: <Widget>[
                Positioned.fill(
                  child: widget.isHost
                      ? _StreamVideoPreview(renderer: renderer, mirror: true)
                      : const ColoredBox(color: Colors.black),
                ),
                Positioned(
                  top: 10,
                  left: 10,
                  right: 10,
                  child: SafeArea(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        BlocBuilder<LiveChatCubit, LiveChatState>(
                          buildWhen: (previous, current) =>
                              previous.viewerCount != current.viewerCount,
                          builder: (context, chatState) {
                            final count = widget.isHost
                                ? (chatState.viewerCount > 0
                                    ? chatState.viewerCount - 1
                                    : 0)
                                : chatState.viewerCount;
                            final pill = Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.black26,
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.remove_red_eye_outlined,
                                    color: Colors.white70,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '$count',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            );
                            final counter = widget.isHost
                                ? GestureDetector(
                                    onTap: () =>
                                        ViewersBottomSheet.show(context),
                                    child: pill,
                                  )
                                : pill;
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const LiveBadge(),
                                const SizedBox(width: 8),
                                counter,
                              ],
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.close,
                              size: 30, color: Colors.white),
                          onPressed: _onClosePressed,
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 12,
                  right: 90,
                  bottom: 12,
                  child: LiveChatWidget(
                    currentUsername: currentUser.username,
                    currentUserAvatarUrl: currentUser.image,
                    isStreamOwner: widget.isHost,
                    onBanRequest:
                        widget.isHost ? (msg) => _showBanSheet(ctx, msg) : null,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

// ---------------------------------------------------------------------------
// Private extracted widgets
// ---------------------------------------------------------------------------

class _StreamVideoPreview extends StatelessWidget {
  final RTCVideoRenderer renderer;
  final bool mirror;

  const _StreamVideoPreview({
    required this.renderer,
    required this.mirror,
  });

  @override
  Widget build(BuildContext context) {
    if (renderer.textureId == null && renderer.srcObject == null) {
      return const ColoredBox(color: Colors.black);
    }
    return ColoredBox(
      color: Colors.black,
      child: RTCVideoView(
        renderer,
        objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
        mirror: mirror,
      ),
    );
  }
}
