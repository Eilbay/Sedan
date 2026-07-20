import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:visibility_detector/visibility_detector.dart';

class VideoViewerScreen extends StatefulWidget {
  const VideoViewerScreen({
    super.key,
    required this.url,
    this.coverUrl,
    this.autoPlay = true,
    this.loop = true,
    this.borderRadius = 10,
    this.showFullscreenButton = false,
    this.fullscreenButtonRight = 10,
  });

  final String url;
  final String? coverUrl;
  final bool autoPlay;
  final bool loop;
  final double borderRadius;
  final bool showFullscreenButton;
  final double fullscreenButtonRight;

  @override
  State<VideoViewerScreen> createState() => _VideoViewerScreenState();
}

class _VideoViewerScreenState extends State<VideoViewerScreen>
    with WidgetsBindingObserver {
  Player? _player;
  VideoController? _videoController;
  bool _inited = false;

  // While true, fullscreen owns the shared player/controller — the inline
  // surface hides its Video widget so the same texture isn't bound twice,
  // and ignores visibility-driven pausing.
  bool _suspendedForFullscreen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initVideo();
  }

  Future<void> _initVideo() async {
    final player = Player(
      configuration: const PlayerConfiguration(
        bufferSize: 4 * 1024 * 1024,
        logLevel: MPVLogLevel.warn,
      ),
    );

    if (widget.loop) {
      final native = player.platform;
      if (native is NativePlayer) {
        native.setProperty('loop-file', 'inf');
      }
    }

    // VideoController MUST be created BEFORE open() so the native
    // video output texture exists when the decoder starts.
    final vc = VideoController(player);

    await player.open(Media(widget.url), play: widget.autoPlay);

    // Wait for first frame.
    try {
      await player.stream.width
          .firstWhere((w) => w != null && w > 0)
          .timeout(const Duration(seconds: 8));
    } catch (_) {}

    if (!mounted) {
      await player.dispose();
      return;
    }

    _player = player;
    _videoController = vc;
    setState(() => _inited = true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _player?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      _player?.pause();
    }
  }

  void _pause() {
    final p = _player;
    if (p != null && p.state.playing) p.pause();
  }

  Future<void> _toggle() async {
    final p = _player;
    if (!_inited || p == null) return;

    if (p.state.playing) {
      await p.pause();
    } else {
      await p.play();
    }
  }

  // Pushes a fullscreen route showing the SAME player/controller — not a new
  // player — so entering/leaving fullscreen never restarts playback; it
  // continues from whatever second it was at, exactly like a movie.
  Future<void> _openFullscreen() async {
    final player = _player;
    final controller = _videoController;
    if (player == null || controller == null) return;

    setState(() => _suspendedForFullscreen = true);

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => VideoFullScreenPage(
          player: player,
          controller: controller,
        ),
      ),
    );

    if (!mounted) return;
    setState(() => _suspendedForFullscreen = false);
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key('video-viewer-${widget.url}'),
      onVisibilityChanged: (info) {
        if (!mounted || _suspendedForFullscreen) return;

        if (info.visibleFraction == 0) {
          _pause();
        }
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Layer 1: Cover image (visible until video plays, and while
            // fullscreen owns the shared texture).
            if (widget.coverUrl != null)
              CachedNetworkImage(
                imageUrl: widget.coverUrl!,
                fit: BoxFit.cover,
                placeholder: (_, __) =>
                    const ColoredBox(color: Color(0xFF0B0B0F)),
                errorWidget: (_, __, ___) =>
                    const ColoredBox(color: Color(0xFF0B0B0F)),
              )
            else
              const ColoredBox(color: Color(0xFF0B0B0F)),

            if (_inited && _videoController != null && !_suspendedForFullscreen)
              _VideoSurface(
                player: _player!,
                controller: _videoController!,
                fit: BoxFit.cover,
                onTap: _toggle,
              ),

            if (!_inited)
              const Center(
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              ),

            if (widget.showFullscreenButton && !_suspendedForFullscreen)
              Positioned(
                top: 5,
                right: widget.fullscreenButtonRight,
                child: Material(
                  color: const Color(0xff89898a).withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 50.w,
                    height: 45.h,
                    child: IconButton(
                      tooltip: 'На весь экран',
                      onPressed: _openFullscreen,
                      icon: const Icon(
                        Icons.fullscreen_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Fullscreen page over the SAME [player]/[controller] passed in — never
/// creates its own, so closing it leaves the caller's player exactly where
/// this page left it (position + playing state), and vice versa.
class VideoFullScreenPage extends StatelessWidget {
  const VideoFullScreenPage({
    super.key,
    required this.player,
    required this.controller,
  });

  final Player player;
  final VideoController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _VideoSurface(
            player: player,
            controller: controller,
            fit: BoxFit.contain,
            onTap: () async {
              if (player.state.playing) {
                await player.pause();
              } else {
                await player.play();
              }
            },
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Material(
                  color: Colors.black45,
                  shape: const CircleBorder(),
                  child: IconButton(
                    icon: Transform.translate(
                      offset: const Offset(-2.5, 0),
                      child: const Icon(Icons.arrow_back_ios_new,
                          color: Colors.white),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Video texture + buffering spinner + play/pause overlay, shared by the
/// inline card and the fullscreen page so both always agree on state —
/// there is only ever one [Player] driving either surface.
class _VideoSurface extends StatelessWidget {
  const _VideoSurface({
    required this.player,
    required this.controller,
    required this.fit,
    required this.onTap,
  });

  final Player player;
  final VideoController controller;
  final BoxFit fit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Video(
            controller: controller,
            fit: fit,
            controls: NoVideoControls,
          ),
          StreamBuilder<bool>(
            stream: player.stream.buffering,
            initialData: player.state.buffering,
            builder: (_, snapshot) {
              if (snapshot.data != true) return const SizedBox.shrink();
              return const Center(
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              );
            },
          ),
          StreamBuilder<bool>(
            stream: player.stream.playing,
            initialData: player.state.playing,
            builder: (_, snapshot) {
              final isPlaying = snapshot.data ?? false;
              final isBuffering = player.state.buffering;
              if (isPlaying || isBuffering) return const SizedBox.shrink();
              return const Center(child: _PlayPauseOverlay(isPlaying: false));
            },
          ),
        ],
      ),
    );
  }
}

class _PlayPauseOverlay extends StatelessWidget {
  const _PlayPauseOverlay({required this.isPlaying});

  final bool isPlaying;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: 62,
          height: 62,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.35),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.18),
              width: 1,
            ),
          ),
          child: Icon(
            isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
            color: Colors.white,
            size: 40,
          ),
        ),
      ),
    );
  }
}
