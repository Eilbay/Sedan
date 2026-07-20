import 'dart:io';

import 'package:flutter/foundation.dart';

/// Validates video files by format and raw size.
///
/// Rejects files exceeding [maxRawFileSize] before any processing to prevent
/// OOM kills and long compression waits on very large files.
class VideoValidator {
  /// Hard cap on the uploaded (post-compression) file size. Must match the
  /// backend limit on POST /api/v2/post-media/ — anything larger is rejected
  /// server-side, so there is no point uploading it.
  static const int maxUploadSize = 300 * 1024 * 1024; // 300 MB
  static const int maxRawFileSize = 2 * 1024 * 1024 * 1024; // 2 GB
  static const List<String> supportedFormats = [
    'mp4',
    'mov',
    'webm',
    'm4v',
    '3gp',
  ];

  static Future<int> _getFileSize(String path) async {
    return File(path).length();
  }

  /// Checks if a file path points to a video by its extension.
  static bool isVideoFile(String path) {
    final extension = path.split('.').last.toLowerCase();
    return supportedFormats.contains(extension);
  }

  /// Validates video format and raw file size (before compression).
  Future<({bool isValid, String? error})> validate(File video) async {
    try {
      if (!isVideoFile(video.path)) {
        return (
          isValid: false,
          error:
              'Неподдерживаемый формат видео. Используйте: ${supportedFormats.join(", ")}'
        );
      }

      // The picker copies the selection into the volatile OS cache, which can
      // be purged before the upload runs (notably under memory pressure).
      // Catch it here with a clear, actionable message instead of leaking a
      // raw PathNotFoundException from the size check below.
      if (!await video.exists()) {
        return (
          isValid: false,
          error: 'Файл видео больше недоступен — выберите видео заново.',
        );
      }

      // Early size check — reject files too large for processing
      final rawSize = await compute(_getFileSize, video.path);
      if (rawSize > maxRawFileSize) {
        final sizeMb = (rawSize / (1024 * 1024)).toStringAsFixed(0);
        return (
          isValid: false,
          error: 'Видео слишком большое ($sizeMb MB). Максимум: 2 GB',
        );
      }

      return (isValid: true, error: null);
    } catch (e) {
      return (isValid: false, error: 'Ошибка при проверке видео: $e');
    }
  }
}
