import 'package:flutter/foundation.dart';
import 'package:optombai/core/error/crash_log_file.dart';
import 'package:talker_flutter/talker_flutter.dart';

/// Pipes every Talker event into the on-device `crash_log.txt` file
/// in addition to its in-memory ring buffer.
///
/// Why this exists:
///   - Talker's default ring buffer only lives in RAM (500 entries).
///     A native OOM kill destroys the process before we can read it.
///   - The file is flushed on every event, so even if iOS kills the
///     app the next millisecond, the previous event is on disk.
class TalkerFileObserver extends TalkerObserver {
  @override
  void onLog(TalkerData log) {
    _write(log);
  }

  @override
  void onError(TalkerError err) {
    _write(err);
  }

  @override
  void onException(TalkerException err) {
    _write(err);
  }

  void _write(TalkerData data) {
    try {
      final line = StringBuffer()
        ..write('[')
        ..write(data.time.toIso8601String())
        ..write('] [')
        ..write(data.logLevel?.name ?? data.title ?? data.key ?? 'log')
        ..write('] ')
        ..write(data.generateTextMessage())
        ..writeln();
      // Fire-and-forget; append() swallows its own errors.
      CrashLogFile.append(line.toString());
    } catch (e) {
      debugPrint('[TalkerFileObserver] write failed: $e');
    }
  }
}
