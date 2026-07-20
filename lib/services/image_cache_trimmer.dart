import 'package:flutter/painting.dart';
import 'package:optombai/core/debug/talker_instance.dart';

/// Frees decoded-image RAM (reel covers, avatars, thumbnails) held by Flutter's
/// [ImageCache]. Deliberately scoped to the painting cache only — it never
/// touches the video pre-buffer pool or the active player, so reels playback
/// logic is untouched. Re-display simply re-decodes from disk/network.
class ImageCacheTrimmer {
  const ImageCacheTrimmer();

  /// Evicts both pending and live decoded images. Call on memory pressure or
  /// when the app goes to background to keep the resident footprint from
  /// creeping up over a long session.
  void trim() {
    final cache = PaintingBinding.instance.imageCache;
    final freed = cache.currentSizeBytes;
    cache.clear();
    cache.clearLiveImages();
    talker.info(
      '[IMAGE-CACHE] trimmed — freed ~${(freed / (1024 * 1024)).toStringAsFixed(1)}MB',
    );
  }
}
