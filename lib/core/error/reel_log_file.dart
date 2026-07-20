import 'dart:io';

import 'package:optombai/core/error/append_only_log_file.dart';

/// Persistent on-device log dedicated to the Reels feed — separate from
/// `crash_log.txt` so its events aren't buried under the much higher-volume
/// HTTP/lifecycle noise there. Shared via `CrashLogFile.share()`, which
/// bundles this file alongside the general crash log.
///
/// File location: `<app documents dir>/reel_log.txt`
class ReelLogFile {
  ReelLogFile._();

  static final _log = AppendOnlyLogFile(fileName: 'reel_log.txt');

  static Future<void> append(String message) => _log.append(message);

  static Future<List<File>> existingFiles() => _log.existingFiles();

  static Future<String> currentPath() => _log.currentPath();

  static Future<void> clear() => _log.clear();
}
