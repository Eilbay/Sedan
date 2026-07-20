import 'dart:io';

import 'package:optombai/core/debug/talker_instance.dart';
import 'package:optombai/core/error/append_only_log_file.dart';

/// Persistent on-device log dedicated to live streams — separate from
/// `crash_log.txt` so stream diagnostics aren't buried under the much
/// higher-volume HTTP/lifecycle noise there. Shared via
/// `CrashLogFile.share()`, which bundles this file alongside the other logs.
///
/// Why this exists: the live-stream feature used to log through
/// `dart:developer log()` (viewer) and `debugPrint` (host) — neither of
/// which reaches Talker or any on-device file, so crash logs from testers
/// contained zero information about failed stream sessions.
///
/// File location: `<app documents dir>/stream_log.txt`
class StreamLogFile {
  StreamLogFile._();

  static final _log = AppendOnlyLogFile(fileName: 'stream_log.txt');

  /// Logs a stream diagnostic event to both Talker (in-memory ring +
  /// general crash log via its file observer) and the dedicated
  /// `stream_log.txt`.
  static void log(String message, {bool isWarning = false}) {
    if (isWarning) {
      talker.warning(message);
    } else {
      talker.info(message);
    }
    _log.append('[${DateTime.now().toIso8601String()}] $message\n');
  }

  static Future<List<File>> existingFiles() => _log.existingFiles();

  static Future<String> currentPath() => _log.currentPath();

  static Future<void> clear() => _log.clear();
}
