import 'dart:developer' show log;

import 'package:flutter/foundation.dart';
import 'package:optombai/core/debug/compact_logger_formatter.dart';
import 'package:optombai/core/error/talker_file_observer.dart';
import 'package:talker_flutter/talker_flutter.dart';

/// Global Talker instance shared by the Dio interceptor and the debug
/// screen. One instance so logs from all subsystems land in a single
/// in-memory history that the UI can replay.
///
/// `TalkerFileObserver` mirrors every event to `crash_log.txt` so the
/// file survives an OOM kill — testers can then share the file.
///
/// Console output uses [CompactLoggerFormatter] — coloured line-based
/// output without the trailing `─────` divider that Talker's stock
/// formatter inserts after every message. The divider made copy/paste
/// awkward because each selection had to be cleaned up manually; the
/// `[Talker] [level] | hh:mm:ss |` prefix already separates entries.
final talker = TalkerFlutter.init(
  settings: TalkerSettings(
    maxHistoryItems: 500,
  ),
  observer: TalkerFileObserver(),
  logger: TalkerLogger(
    formatter: const CompactLoggerFormatter(),
    output: _consoleOutput,
  ),
);

/// Console sink. Mirrors TalkerFlutter's default platform routing: native
/// `dart:developer.log` on Apple platforms (clean output in Xcode), and
/// `debugPrint` elsewhere.
void _consoleOutput(String message) {
  if (kIsWeb) {
    // ignore: avoid_print
    print(message);
    return;
  }
  switch (defaultTargetPlatform) {
    case TargetPlatform.iOS:
    case TargetPlatform.macOS:
      log(message, name: 'Talker');
      break;
    default:
      debugPrint(message);
  }
}
