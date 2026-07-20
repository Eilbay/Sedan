import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:optombai/data/models/media_file.dart';
import 'package:optombai/services/media/video_validator.dart';
import 'package:optombai/services/media/video_thumbnail_generator.dart';

/// Orchestrates the media processing pipeline: validation -> thumbnail.
///
/// Video compression is delegated to the backend — the original file is
/// uploaded as-is and the server re-encodes it.
class MediaProcessor {
  final VideoValidator _validator = VideoValidator();
  final VideoThumbnailGenerator _thumbnailGenerator = VideoThumbnailGenerator();

  static Future<int> _getFileSize(String path) async {
    return File(path).length();
  }

  /// Processes a video: validate -> generate thumbnail.
  ///
  /// The original file is kept as-is; compression happens server-side, so we
  /// do NOT pre-reject by size here — oversized files are sent to the API and
  /// the server's rejection is surfaced to the user with its detail.
  ///
  /// Progress stages reported via [onProgress] (0–100):
  /// - 0–10: validation
  /// - 10–90: thumbnail generation
  /// - 90–100: finalization
  ///
  /// [onStatusChanged] reports the current stage name for UI display.
  Future<MediaFile?> processVideo(
    File videoFile, {
    Function(double)? onProgress,
    Function(VideoProcessingStage)? onStatusChanged,
  }) async {
    // 1. Validate format and raw size (OOM guard only).
    onStatusChanged?.call(VideoProcessingStage.validating);
    onProgress?.call(2);

    final validation = await _validator.validate(videoFile);
    if (!validation.isValid) {
      throw MediaProcessingException(
        validation.error ?? 'Unknown validation error',
      );
    }
    onProgress?.call(10);

    final finalSize = await compute(_getFileSize, videoFile.path);

    // 2. Generate thumbnail from the original file.
    try {
      onStatusChanged?.call(VideoProcessingStage.generatingThumbnail);
      final thumbnail = await _thumbnailGenerator.generate(videoFile);
      onProgress?.call(90);

      // 3. Build result.
      onStatusChanged?.call(VideoProcessingStage.finalizing);
      final mediaFile = MediaFile(
        file: videoFile,
        type: MediaType.video,
        thumbnail: thumbnail,
        size: finalSize,
      );

      onProgress?.call(100);
      return mediaFile;
    } catch (e) {
      if (e is MediaProcessingException) rethrow;
      throw MediaProcessingException('Ошибка при обработке видео: $e');
    }
  }

  /// Wraps an image file in a MediaFile.
  Future<MediaFile?> processImage(File imageFile) async {
    try {
      final size = await compute(_getFileSize, imageFile.path);
      return MediaFile(
        file: imageFile,
        type: MediaType.image,
        size: size,
      );
    } catch (e) {
      return null;
    }
  }

  /// Determines the media type from a file path.
  MediaType determineMediaType(String filePath) {
    return VideoValidator.isVideoFile(filePath)
        ? MediaType.video
        : MediaType.image;
  }

  /// Deletes a temporary file safely.
  Future<void> deleteTemporaryFile(File? file) async {
    try {
      if (file != null && await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }
}

/// Stages of video processing, used for UI status text.
enum VideoProcessingStage {
  validating,
  generatingThumbnail,
  finalizing,
}

/// Human-readable exception for media processing errors.
class MediaProcessingException implements Exception {
  final String message;
  const MediaProcessingException(this.message);

  @override
  String toString() => message;
}
