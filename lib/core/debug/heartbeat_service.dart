import 'dart:async';
import 'dart:io' show Platform, ProcessInfo;

import 'package:optombai/core/debug/talker_instance.dart';
import 'package:optombai/core/di/injection.dart';
import 'package:optombai/services/i_video_pre_buffer_service.dart';

/// Periodic "alive" beacon. Writes a snapshot to the Talker file every
/// [_interval] so that, after a native kill, the **last heartbeat
/// timestamp tells us the exact moment of death**. The snapshot also
/// surfaces growth in Dart memory and pool size — useful for spotting
/// leaks or unbounded growth before the kill.
///
/// Also acts as a **self-defense watchdog**: when RSS crosses
/// [_rssCriticalMB], proactively flushes the video pre-buffer pool
/// without waiting for an OS memory-pressure signal (which is unreliable
/// on lower-RAM devices — the OS often kills the process before
/// emitting the warning).
class HeartbeatService {
  HeartbeatService._();
  static final HeartbeatService instance = HeartbeatService._();

  static const _interval = Duration(seconds: 2);

  /// RSS threshold (megabytes) above which the watchdog forces a
  /// pre-buffer pool flush. Calibrated from observed crash_log values:
  /// iOS kills around 800-1000MB on 3GB devices, Android around
  /// 600-700MB on 3GB devices. Trigger ~150MB below the kill zone to
  /// give the flush time to free memory before the OS strikes.
  static final int _rssCriticalMB = Platform.isIOS ? 650 : 500;

  /// Minimum interval between two forced flushes. Without this we'd
  /// flush every 2s while RSS slowly decays after the first call.
  static const _watchdogCooldown = Duration(seconds: 10);

  Timer? _timer;
  int _tick = 0;
  DateTime? _lastWatchdogFlushAt;

  void start() {
    if (_timer != null) return;
    _timer = Timer.periodic(_interval, (_) => _emit());
    talker.info('[HEARTBEAT] service started, interval=${_interval.inSeconds}s');
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  void _emit() {
    _tick++;
    try {
      final rssBytes = ProcessInfo.currentRss;
      final rssMB = (rssBytes / (1024 * 1024)).toStringAsFixed(1);
      final maxRssMB =
          (ProcessInfo.maxRss / (1024 * 1024)).toStringAsFixed(1);

      String poolSummary;
      try {
        final pre = getIt<IVideoPreBufferService>();
        poolSummary = pre.runtimeType.toString();
      } catch (_) {
        poolSummary = 'unavailable';
      }

      talker.info(
        '[HEARTBEAT] tick=$_tick rss=${rssMB}MB maxRss=${maxRssMB}MB svc=$poolSummary',
      );

      _maybeTriggerWatchdog(rssBytes);
    } catch (e) {
      talker.handle(e, null, '[HEARTBEAT] emit failed');
    }
  }

  void _maybeTriggerWatchdog(int rssBytes) {
    final rssMB = rssBytes / (1024 * 1024);
    if (rssMB < _rssCriticalMB) return;

    final now = DateTime.now();
    if (_lastWatchdogFlushAt != null &&
        now.difference(_lastWatchdogFlushAt!) < _watchdogCooldown) {
      // Already flushed recently — give the OS time to actually reclaim
      // before triggering again. Re-fire only if memory keeps climbing
      // past the next cooldown window.
      return;
    }
    _lastWatchdogFlushAt = now;

    talker.warning(
      '[WATCHDOG] *** RSS=${rssMB.toStringAsFixed(1)}MB exceeds critical '
      'threshold ${_rssCriticalMB}MB — forcing pre-buffer flush ***',
    );

    try {
      final pre = getIt<IVideoPreBufferService>();
      pre.flushForBackground();
      // flushForBackground pauses the service; resume so subsequent
      // scrolling refills the pool naturally. We're still foreground.
      pre.resume();
    } catch (e, st) {
      talker.handle(e, st, '[WATCHDOG] flush failed');
    }
  }
}
