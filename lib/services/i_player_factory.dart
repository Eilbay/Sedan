import 'package:video_player/video_player.dart';

/// Abstract factory for creating video player controller instances.
abstract class IPlayerFactory {
  /// Reel player: looping, muted-by-default, network HLS.
  /// Caller owns the controller and must dispose it.
  VideoPlayerController createReelPlayer(String url);

  /// Pre-buffer player: same as reel, paused initially.
  VideoPlayerController createPreBufferPlayer(String url);

  /// Silent preview for product cards.
  VideoPlayerController createPreviewPlayer(String url);

  /// Full-screen viewer.
  VideoPlayerController createViewerPlayer(String url);
}
