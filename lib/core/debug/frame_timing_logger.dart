import 'dart:ui' show FrameTiming;

import 'package:flutter/scheduler.dart';
import 'package:optombai/core/debug/talker_instance.dart';

/// Hooks Flutter's scheduler timings to detect UI freezes.
///
/// A frame normally takes < 16ms (60fps). When the UI thread is
/// blocked by heavy synchronous work, GC pause, or a native plugin
/// hang, frames stretch. Slow frames are logged so we can correlate
/// them with crashes — a [_critThreshold] freeze right before a
/// session ends signals a watchdog kill (not OOM).
class FrameTimingLogger {
  FrameTimingLogger._();
  static final FrameTimingLogger instance = FrameTimingLogger._();

  static const _warnThreshold = Duration(milliseconds: 500);
  static const _critThreshold = Duration(milliseconds: 2000);

  bool _attached = false;

  void attach() {
    if (_attached) return;
    _attached = true;
    SchedulerBinding.instance.addTimingsCallback(_onTimings);
    talker.info('[FRAME] timing logger attached');
  }

  void _onTimings(List<FrameTiming> timings) {
    for (final t in timings) {
      final span = t.totalSpan;
      if (span < _warnThreshold) continue;

      final ms = span.inMilliseconds;
      if (span >= _critThreshold) {
        talker.warning(
          '[FRAME] *** UI FREEZE *** frame=${ms}ms '
          '(build=${t.buildDuration.inMilliseconds}ms '
          'raster=${t.rasterDuration.inMilliseconds}ms) — '
          'likely watchdog precursor',
        );
      } else {
        talker.info(
          '[FRAME] slow frame=${ms}ms '
          '(build=${t.buildDuration.inMilliseconds}ms '
          'raster=${t.rasterDuration.inMilliseconds}ms)',
        );
      }
    }
  }
}
