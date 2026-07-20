import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:optombai/core/debug/talker_instance.dart';
import 'package:optombai/services/i_video_pre_buffer_service.dart';
import 'package:optombai/services/image_cache_trimmer.dart';

/// Listens for iOS/Android memory-pressure notifications and frees the
/// `VideoPreBufferService` pool before the OS kills the app.
///
/// On iOS the OS sends `UIApplicationDidReceiveMemoryWarningNotification`;
/// on Android it sends `onTrimMemory`/`onLowMemory`. Flutter funnels both
/// through `SystemChannels.system` with `{ "type": "memoryPressure" }`.
///
/// When triggered, we cancel everything in the pre-buffer queue. The
/// active reel survives because `ReelPlaybackManager` owns its
/// controllers separately from the pool.
class MemoryPressureHandler {
  MemoryPressureHandler({required IVideoPreBufferService preBufferService})
      : _preBufferService = preBufferService;

  final IVideoPreBufferService _preBufferService;
  final ImageCacheTrimmer _imageCacheTrimmer = const ImageCacheTrimmer();
  bool _attached = false;

  /// Register the system handler. Idempotent.
  void attach() {
    if (_attached) return;
    _attached = true;

    SystemChannels.system.setMessageHandler((message) async {
      if (message is Map && message['type'] == 'memoryPressure') {
        _onMemoryPressure();
      }
      return;
    });
  }

  void _onMemoryPressure() {
    // warning() so this is visible in red in Talker UI and in the file
    // share — these events are the single best predictor of crashes.
    talker.warning('[MEMORY] *** OS memory pressure event received ***');
    talker.warning(
      '[MEMORY] flushing pre-buffer pool (ready + in-flight + queue)',
    );
    try {
      // flushForBackground frees every ready controller AND drops the
      // queue. The active reel is unaffected — ReelPlaybackManager owns
      // its controllers separately.
      _preBufferService.flushForBackground();
      // Also drop decoded image RAM (covers/avatars) — the second-largest
      // resident contributor after the video pool. Safe for playback.
      _imageCacheTrimmer.trim();
      // flushForBackground also pauses the service; resume so the next
      // enqueue (e.g. from continued reel scrolling) refills the pool
      // organically. The user is *still in the foreground* — this
      // wasn't a background eviction, it was an in-flight pressure
      // signal, and we want pre-buffer back online for smooth scroll.
      _preBufferService.resume();
    } catch (e, st) {
      debugPrint('[MEMORY] flushForBackground failed: $e');
      debugPrint(st.toString());
    }
  }
}
