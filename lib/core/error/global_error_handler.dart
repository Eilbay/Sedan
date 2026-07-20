import 'dart:io';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:optombai/core/debug/talker_instance.dart';
import 'package:optombai/core/error/crash_log_file.dart';

/// Source of a caught error — useful for routing decisions in [handleError].
///
/// `flutter` — Framework errors (build, layout, paint) caught by
///             FlutterError.onError. Often non-fatal UI glitches.
/// `platform` — Async errors outside any zone (PlatformDispatcher.onError).
///              Usually plugin/platform-channel issues.
/// `zone` — Uncaught errors inside the runZonedGuarded wrapper around
///          runApp(). Catches Dart logic errors that escape try-catch.
/// `videoPlayer` — Manually reported from `ReelPlaybackManager` /
///                 `VideoPreBufferService` when a controller operation
///                 throws. Most frequent in production.
enum ErrorSource { flutter, platform, zone, videoPlayer }

/// Single funnel for every error the app would otherwise crash on.
///
/// LEARNING-MODE CONTRIBUTION POINT — implement the body below.
/// See trade-offs in the inline comment.
class GlobalErrorHandler {
  GlobalErrorHandler._();

  /// Handles a caught error so the app does not crash.
  ///
  /// Called from:
  ///   - FlutterError.onError              (source: flutter)
  ///   - PlatformDispatcher.instance.onError (source: platform)
  ///   - runZonedGuarded errorCallback      (source: zone)
  ///   - ReelPlaybackManager catch blocks   (source: videoPlayer)
  ///
  /// TRADE-OFFS to think through before writing the body:
  ///
  /// 1. Silent log + swallow
  ///      Pros: best UX (zero user-visible failures), simplest code.
  ///      Cons: bugs hide; you can never tell prod is broken.
  ///
  /// 2. Log + show SnackBar/Toast "Что-то пошло не так"
  ///      Pros: user knows something failed; user can refresh.
  ///      Cons: annoying for video errors that happen every 5 reels;
  ///            requires BuildContext or root navigator key.
  ///
  /// 3. Log + report to Firebase Crashlytics + swallow
  ///      Pros: production observability; can prioritize fixes.
  ///      Cons: requires Crashlytics setup (not yet in project — check
  ///            firebase_core is imported, Crashlytics is separate pod).
  ///
  /// 4. Bipartite: silent for known/recoverable errors (e.g. PlatformException
  ///    'VideoError'), show UI for unknown ones.
  ///      Pros: best of both worlds.
  ///      Cons: must maintain a list of "known errors".
  ///
  /// CONTEXT for the call:
  ///   - error: the thrown object (often PlatformException, FormatException,
  ///            Exception, or a String).
  ///   - stack: stack trace, or null for some platform errors.
  ///   - source: one of [ErrorSource] — useful to gate behavior (e.g. show
  ///             SnackBar only for [ErrorSource.flutter] but not [videoPlayer]).
  ///
  /// IMPLEMENTATION (5-10 lines): write the strategy that fits the project.
  /// Below is a minimal placeholder — REPLACE with your choice.
  static void handleError(
    Object error,
    StackTrace? stack, {
    required ErrorSource source,
  }) {
    // A failed image fetch (deleted / stale media URL → 404) is a non-fatal UI
    // glitch: the widget already falls back to a placeholder. Reporting it to
    // Crashlytics floods the dashboard and hides real crashes, so log it to the
    // console only and stop here.
    if (_isRecoverableImageError(error)) {
      debugPrint('[image] non-fatal load failure: $error');
      return;
    }

    // 1. Console — fast feedback in `flutter logs`.
    debugPrint('[ERROR/${source.name}] $error');
    if (stack != null && kDebugMode) {
      debugPrint(stack.toString());
    }

    // 2. Talker — in-memory ring buffer (last 500 events) viewable via the
    //    Debug screen (10 taps on bottom nav). Lets testers reproduce a
    //    bug and inspect the chain of events without a developer machine.
    talker.handle(error, stack, 'ErrorSource.${source.name}');

    // 3. On-device file — survives app restart. Tester taps "Share log"
    //    in Debug screen → sends you the .txt over WhatsApp/Telegram.
    //
    // TODO(user-contribution): if you want strategy 2/3/4 from the
    // trade-offs above (SnackBar / Crashlytics / bipartite), add it here.
    final record = StringBuffer()
      ..writeln('=== ${DateTime.now().toIso8601String()} ===')
      ..writeln('source: ${source.name}')
      ..writeln('error : $error');
    if (stack != null) {
      record
        ..writeln('stack :')
        ..writeln(stack.toString());
    }
    record.writeln();
    // Fire-and-forget — append() catches its own errors internally.
    CrashLogFile.append(record.toString());

    // 4. Firebase Crashlytics — server-side aggregation across all users.
    //    Non-fatal so the app keeps running. Crashes that escape ALL
    //    handlers (native crashes, isolate errors) are caught by
    //    Crashlytics SDK at the native layer separately.
    try {
      FirebaseCrashlytics.instance.recordError(
        error,
        stack,
        reason: 'ErrorSource.${source.name}',
        fatal: false,
      );
    } catch (_) {
      // Crashlytics may not be initialized in early bootstrap or in
      // tests — swallow to avoid recursive failure.
    }
  }

  /// True for non-fatal image-fetch failures. CachedNetworkImage / NetworkImage
  /// surface a missing or stale media URL as an [HttpException] with a non-2xx
  /// status (or a NetworkImageLoadException). The widget recovers via its
  /// placeholder, so these must not be treated as crashes.
  static bool _isRecoverableImageError(Object error) {
    if (error is HttpException) {
      return error.message.contains('Invalid statusCode');
    }
    return error.runtimeType.toString() == 'NetworkImageLoadException';
  }
}
