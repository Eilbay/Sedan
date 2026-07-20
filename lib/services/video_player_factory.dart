import 'dart:async';

import 'package:video_player/video_player.dart';
import 'package:optombai/services/i_player_factory.dart';

/// `IPlayerFactory` impl built on `video_player` (AVPlayer/ExoPlayer).
///
/// Native HLS ABR is automatic — no per-rendition selection from Dart.
/// Caller owns each returned controller and is responsible for
/// `initialize()` + `dispose()`.
class VideoPlayerFactory implements IPlayerFactory {
  /// Standard reel player options:
  /// - mixWithOthers=true so background audio (music apps) is not preempted
  /// - allowBackgroundPlayback=false (reels are foreground-only)
  static final _reelOptions = VideoPlayerOptions(
    mixWithOthers: true,
    allowBackgroundPlayback: false,
  );

  static final _viewerOptions = VideoPlayerOptions(
    mixWithOthers: false,
    allowBackgroundPlayback: false,
  );

  @override
  VideoPlayerController createReelPlayer(String url) {
    final controller = VideoPlayerController.networkUrl(
      Uri.parse(url),
      videoPlayerOptions: _reelOptions,
    );
    // `setLooping` and `setVolume` return Futures we deliberately don't await.
    // They are no-ops at the platform layer until `initialize()` completes, but
    // they DO update the in-memory `value.isLooping` / `value.volume`, which
    // video_player re-applies once initialized. This pre-seeds the desired
    // state without requiring callers to await anything.
    unawaited(controller.setLooping(true));
    unawaited(controller.setVolume(0)); // muted by default — ReelPlaybackManager unmutes
    return controller;
  }

  @override
  VideoPlayerController createPreBufferPlayer(String url) {
    final controller = VideoPlayerController.networkUrl(
      Uri.parse(url),
      videoPlayerOptions: _reelOptions,
    );
    unawaited(controller.setLooping(true));
    unawaited(controller.setVolume(0));
    return controller;
  }

  /// Single-shot: NO looping (preview is one-pass; reel widget calls
  /// dispose() when off-screen).
  @override
  VideoPlayerController createPreviewPlayer(String url) {
    final controller = VideoPlayerController.networkUrl(
      Uri.parse(url),
      videoPlayerOptions: _reelOptions,
    );
    unawaited(controller.setVolume(0));
    return controller;
  }

  @override
  VideoPlayerController createViewerPlayer(String url) {
    return VideoPlayerController.networkUrl(
      Uri.parse(url),
      videoPlayerOptions: _viewerOptions,
    );
  }
}
