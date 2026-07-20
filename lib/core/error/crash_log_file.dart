import 'dart:ui' show Rect;

import 'package:flutter/foundation.dart';
import 'package:optombai/core/error/append_only_log_file.dart';
import 'package:optombai/core/error/reel_log_file.dart';
import 'package:optombai/core/error/stream_log_file.dart';
import 'package:share_plus/share_plus.dart';

/// Persistent on-device crash log. Append-only, size-capped, shareable.
///
/// Use case: testers (or you) install the app, use it normally, eventually
/// see a bug. They open the Debug screen or Settings, tap Share, and send
/// you the `.txt` via WhatsApp/Telegram/AirDrop. You read it and fix.
///
/// File location: `<app documents dir>/crash_log.txt`
/// On rotation, the previous file moves to `crash_log.prev.txt` so we keep
/// two generations (the current one and the one before the most recent
/// rotation).
class CrashLogFile {
  CrashLogFile._();

  static final _log = AppendOnlyLogFile(fileName: 'crash_log.txt');

  static Future<void> append(String message) => _log.append(message);

  /// Opens the system share sheet so the user can send the log to you.
  /// Pass `BuildContext`-derived [sharePositionOrigin] from a Builder if
  /// you want a popover on iPad (otherwise iPad shows a fullscreen sheet).
  /// Bundles the reel-specific log alongside the general crash log —
  /// they're separate files so reel diagnostics aren't diluted by the
  /// much higher-volume HTTP/lifecycle noise, but testers only need to
  /// remember one share button.
  static Future<void> share({Rect? sharePositionOrigin}) async {
    try {
      final files = [
        ...await _log.existingFiles(),
        ...await ReelLogFile.existingFiles(),
        ...await StreamLogFile.existingFiles(),
      ];

      if (files.isEmpty) {
        debugPrint('[CRASH-LOG] no log files to share');
        return;
      }

      await SharePlus.instance.share(
        ShareParams(
          files: files.map((f) => XFile(f.path)).toList(),
          subject: 'Kitaydan crash log',
          text: 'Crash & error log from the app.',
          sharePositionOrigin: sharePositionOrigin,
        ),
      );
    } catch (e, st) {
      debugPrint('[CRASH-LOG] share failed: $e');
      debugPrint(st.toString());
    }
  }

  /// Returns the path of the current log file (for diagnostics/UI).
  static Future<String> currentPath() => _log.currentPath();

  /// Wipes both files. Useful for "Clear log" button in Settings.
  static Future<void> clear() => _log.clear();
}
