import 'dart:io';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/widgets.dart';
import 'package:optombai/core/debug/talker_instance.dart';
import 'package:optombai/core/di/injection.dart';
import 'package:optombai/core/error/crash_log_file.dart';
import 'package:optombai/services/i_video_pre_buffer_service.dart';
import 'package:optombai/services/image_cache_trimmer.dart';

/// Catches `AppLifecycleState` transitions and logs them. Two purposes:
///
/// 1. **Clean-shutdown marker** — on `detached` we write a sentinel
///    that the next startup checks. Missing sentinel = previous session
///    was killed by the OS (OOM, foreground watchdog, force-quit).
///
/// 2. **Visibility into background/foreground state** — many "the app
///    just disappeared" bug reports turn out to be backgrounded by
///    iOS for memory/battery reasons. Now we can see this in the log.
class AppLifecycleLogger extends WidgetsBindingObserver {
  static const _shutdownMarker = '[SHUTDOWN] clean exit';

  /// Call once at startup to wire the observer.
  static void attach() {
    final logger = AppLifecycleLogger();
    WidgetsBinding.instance.addObserver(logger);
  }

  /// Reads the tail of the previous log file. If the last meaningful
  /// line is not the [_shutdownMarker], assumes the previous session
  /// was killed by the OS and logs a `[CRASH-DETECTED]` entry through
  /// Talker (which the file observer mirrors to disk).
  static Future<void> detectPreviousCrash() async {
    try {
      final path = await CrashLogFile.currentPath();
      final file = File(path);
      if (!await file.exists()) return;

      final content = await file.readAsString();
      if (content.isEmpty) return;

      final tail = content.length > 4096
          ? content.substring(content.length - 4096)
          : content;
      final hasShutdown = tail.contains(_shutdownMarker);
      if (!hasShutdown) {
        talker.warning(
          '[CRASH-DETECTED] previous session did not exit cleanly '
          '(likely native kill: OOM / watchdog / force-quit). '
          'Inspect the tail of the previous log file for the last '
          'event before death.',
        );
        // iOS background-eviction kills do NOT trigger SIGABRT, so
        // Crashlytics native handler never sees them. Surface as a
        // **fatal** report (fatal=true) so Crashlytics flushes it
        // immediately at next launch instead of batching with the
        // non-fatal queue (which often gets dropped on iOS).
        try {
          FirebaseCrashlytics.instance.recordError(
            Exception(
              'Previous session ended without clean shutdown marker '
              '— likely iOS background eviction or OOM kill.',
            ),
            StackTrace.current,
            reason: 'ErrorSource.postmortem',
            fatal: true,
          );
          FirebaseCrashlytics.instance.sendUnsentReports();
        } catch (_) {}
      } else {
        talker.info('[STARTUP] previous session shut down cleanly');
      }
    } catch (e) {
      talker.handle(e, null, 'detectPreviousCrash failed');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        talker.info('[LIFECYCLE] resumed (foreground)');
        break;
      case AppLifecycleState.inactive:
        talker.info('[LIFECYCLE] inactive');
        break;
      case AppLifecycleState.paused:
        talker.info('[LIFECYCLE] paused (background)');
        // Flush video pool to minimise our memory footprint. iOS picks
        // background apps to kill in priority order by memory — by
        // releasing 5×30MB AVPlayer instances we drop ourselves to
        // the bottom of the kill list.
        _flushVideoPool();
        break;
      case AppLifecycleState.hidden:
        talker.info('[LIFECYCLE] hidden');
        _flushVideoPool();
        break;
      case AppLifecycleState.detached:
        // Clean shutdown sentinel. If next startup does NOT see this,
        // the app was killed by the OS.
        talker.info(_shutdownMarker);
        break;
    }
  }

  void _flushVideoPool() {
    try {
      getIt<IVideoPreBufferService>().flushForBackground();
      // Backgrounding is the safest moment to drop decoded image RAM —
      // nothing is visible, so there is no re-decode flash. Shrinks the
      // resident footprint and lowers the OS background-kill risk.
      const ImageCacheTrimmer().trim();
    } catch (e) {
      talker.handle(e, null, 'flushForBackground failed');
    }
  }
}
