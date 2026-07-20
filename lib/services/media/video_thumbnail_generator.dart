import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

/// Generates thumbnail images from video files.
class VideoThumbnailGenerator {
  static Future<File> _writeThumbnailFile(
    (String path, Uint8List bytes) args,
  ) async {
    final file = File(args.$1);
    await file.writeAsBytes(args.$2);
    return file;
  }

  /// Time offset for the captured frame. Most short reels open with a
  /// 0.5–1s fade-in, so frame 0 is almost always pure black. Grabbing
  /// at ~1.5s skips the fade-in and gives a representative cover.
  static const int _frameOffsetMs = 1500;

  /// Generates a JPEG thumbnail from a video. Captures at [_frameOffsetMs]
  /// and falls back to frame 0 for very short clips where that offset
  /// returns null.
  Future<File?> generate(File video) async {
    try {
      final bytes = await _captureFrame(video.path, _frameOffsetMs) ??
          await _captureFrame(video.path, 0);

      if (bytes == null) return null;

      final tempDir = await getTemporaryDirectory();
      final path =
          '${tempDir.path}/thumb_${DateTime.now().millisecondsSinceEpoch}.jpg';

      return compute(_writeThumbnailFile, (path, bytes));
    } catch (e) {
      return null;
    }
  }

  Future<Uint8List?> _captureFrame(String videoPath, int timeMs) {
    return VideoThumbnail.thumbnailData(
      video: videoPath,
      imageFormat: ImageFormat.JPEG,
      maxHeight: 200,
      maxWidth: 200,
      quality: 75,
      timeMs: timeMs,
    );
  }
}
