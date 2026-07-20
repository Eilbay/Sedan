import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:optombai/core/debug/talker_instance.dart';
import 'package:optombai/services/i_player_factory.dart';
import 'package:optombai/services/i_video_pre_buffer_service.dart';
import 'package:video_player/video_player.dart';

/// Queue-based pre-buffer for `VideoPlayerController`s.
///
/// Maintains FIFO queue, at most [_maxConcurrent] parallel inits, and a
/// ready pool capped at [_maxReady] (FIFO eviction).
class VideoPreBufferService implements IVideoPreBufferService {
  VideoPreBufferService({required IPlayerFactory playerFactory})
      : _playerFactory = playerFactory;

  final IPlayerFactory _playerFactory;
  int _maxConcurrent = 1;

  // Platform-aware pool size. Each controller costs ~25-30 MB of
  // native heap (AVPlayer / ExoPlayer + decoded first frame). On
  // weaker Android devices (≤3 GB RAM), 10 controllers already cause
  // fast OOM kills (verified in crash_log 2026-05-15, ready=10/10 ⇒
  // OS kills the process within seconds, no memory-pressure warning
  // ever fires). Drop aggressively — the pre-buffer pool is a
  // smooth-scroll luxury, not a hard requirement.
  //
  // Tuned 2026-05-18 (down from iOS=8/Android=5) after crash_log showed
  // OOM kill at rss=865MB with pool=5/5 + active reels playing. The
  // active reel manager (±2 range = 5 controllers) is the floor we
  // can't compress; the pool is the part we control here.
  static final int _maxReady =
      defaultTargetPlatform == TargetPlatform.iOS ? 4 : 3;

  final _ready = <String, PreBufferedPlayer>{};
  final _readyOrder = <String>[];
  final _queue = <String>[];
  final _processing = <String>{};
  final _cancelled = <String>{};
  final _afterDisposeListeners = <void Function()>[];
  bool _paused = false;
  bool _disposed = false;

  // Adaptive throttling for slow networks. After N consecutive
  // init failures (TimeoutException, network errors), back off so the
  // app doesn't spawn dozens of futures that all eventually time out
  // and freeze the UI long enough for the OS watchdog to kill us.
  int _consecutiveFailures = 0;
  static const int _failureThreshold = 3;

  void _notifyAfterDispose() {
    for (final cb in _afterDisposeListeners) {
      try {
        cb();
      } catch (_) {}
    }
  }

  @override
  void Function() addAfterDisposeCallback(void Function() callback) {
    _afterDisposeListeners.add(callback);
    return () => _afterDisposeListeners.remove(callback);
  }

  @override
  void enqueue(List<String> urls) {
    if (_disposed) return;
    var added = 0;
    for (final url in urls) {
      if (_ready.containsKey(url) ||
          _processing.contains(url) ||
          _queue.contains(url)) {
        continue;
      }
      _queue.add(url);
      added++;
    }
    if (added > 0) {
      talker.info('[PRE-BUFFER] enqueued $added urls, queue=${_queue.length}');
      debugPrint(
          '[PB] enqueued=$added queue=${_queue.length} maxConc=$_maxConcurrent paused=$_paused');
    }
    _processQueue();
  }

  void _processQueue() {
    if (_paused) return;
    while (_processing.length < _maxConcurrent && _queue.isNotEmpty) {
      final url = _queue.removeAt(0);
      _processing.add(url);
      _initOne(url);
    }
  }

  Future<void> _initOne(String url) async {
    final sw = Stopwatch()..start();
    VideoPlayerController? controller;
    try {
      controller = _playerFactory.createPreBufferPlayer(url);
      // 5s (was 10s) — on slow networks 10s × 3 consecutive timeouts =
      // 30s of frozen futures, long enough for the OS watchdog to kill
      // the app. Fail fast and let adaptive throttling (below) hold
      // the queue until the network recovers.
      await controller.initialize().timeout(const Duration(seconds: 5));
      // Controller is now ready (first frame decoded). Stays paused —
      // consumer calls play() after take().

      _consecutiveFailures = 0;
      talker.info('[TIMING] pre-buffer init ${sw.elapsedMilliseconds}ms $url');

      _processing.remove(url);

      if (_disposed || _cancelled.remove(url)) {
        await controller.dispose();
        _notifyAfterDispose();
        talker.info('[PRE-BUFFER] cancelled after init: $url');
        if (!_disposed) _processQueue();
        return;
      }

      _evictIfNeeded();
      _ready[url] = PreBufferedPlayer(controller: controller);
      _readyOrder.add(url);
      talker.info('[PRE-BUFFER] ready: $url');
      debugPrint(
          '[PB] READY ${sw.elapsedMilliseconds}ms pool=${_ready.length}/$_maxReady');
      _logPoolState();
    } catch (e) {
      _processing.remove(url);
      _cancelled.remove(url);
      if (controller != null) {
        await controller.dispose();
        _notifyAfterDispose();
      }
      _consecutiveFailures++;
      talker.info(
        '[PRE-BUFFER] failed (#$_consecutiveFailures): $url — $e',
      );
      debugPrint('[PB] FAILED #$_consecutiveFailures: $e');
      if (_consecutiveFailures >= _failureThreshold && !_paused) {
        // Network is failing — pause the queue. enqueue/prioritize/
        // setMaxConcurrent calls from the UI still update internal
        // state; we just don't fire new inits until a manual resume()
        // or until the next user-driven event clears the failure
        // streak. This prevents UI watchdog kills on bad networks.
        talker.warning(
          '[PRE-BUFFER] adaptive throttle — $_consecutiveFailures consecutive '
          'failures, auto-pausing queue (call resume() to retry)',
        );
        debugPrint(
            '[PB] AUTO-PAUSED after $_consecutiveFailures failures — pool stops filling');
        _paused = true;
      }
    }
    if (!_disposed) _processQueue();
  }

  void _logPoolState() {
    // info() — persisted to crash_log.txt via TalkerFileObserver. This
    // is the single most useful breadcrumb for OOM debugging: the file
    // tail before a kill shows exactly how full the pool was.
    talker.info(
      '[POOL] ready=${_ready.length}/$_maxReady processing=${_processing.length}/$_maxConcurrent queue=${_queue.length}',
    );
  }

  void _evictIfNeeded() {
    var didDispose = false;
    while (_ready.length >= _maxReady && _readyOrder.isNotEmpty) {
      final oldest = _readyOrder.removeAt(0);
      final evicted = _ready.remove(oldest);
      unawaited(evicted?.controller.dispose());
      didDispose = true;
      talker.info('[PRE-BUFFER] evicted oldest: $oldest');
    }
    if (didDispose) _notifyAfterDispose();
  }

  @override
  void pause() {
    _paused = true;
    talker.info('[PRE-BUFFER] paused');
  }

  @override
  void resume() {
    _paused = false;
    // Reset failure counter so the throttle gate doesn't immediately
    // re-trip on the first new init. The UI calling resume() is a
    // signal that something changed — likely the network recovered
    // or the user moved to a different screen.
    _consecutiveFailures = 0;
    talker.info('[PRE-BUFFER] resumed');
    _processQueue();
  }

  @override
  bool isProcessing(String url) => _processing.contains(url);

  @override
  void cancel(String url) {
    if (_queue.remove(url)) {
      talker.info('[PRE-BUFFER] cancelled (queued): $url');
      return;
    }
    if (_processing.contains(url)) {
      _cancelled.add(url);
      talker.info('[PRE-BUFFER] cancelled (in-flight): $url');
    }
  }

  @override
  void cancelAll() {
    final droppedQueue = _queue.length;
    _queue.clear();
    _cancelled.addAll(_processing);
    debugPrint(
      '[PRE-BUFFER] cancelled all — dropped $droppedQueue queued, '
      '${_processing.length} in-flight marked for cleanup',
    );
  }

  @override
  PreBufferedPlayer? take(String url) {
    final entry = _ready.remove(url);
    if (entry != null) {
      _readyOrder.remove(url);
      talker.info('[PRE-BUFFER] claimed: $url');
      debugPrint('[PB] HIT claimed pool=${_ready.length}');
    }
    return entry;
  }

  @override
  void prioritize(List<String> urls) {
    if (_disposed || urls.isEmpty) return;
    var moved = 0;
    for (final url in urls.reversed) {
      if (_ready.containsKey(url) || _processing.contains(url)) continue;
      if (_queue.remove(url)) {
        _queue.insert(0, url);
        moved++;
      }
    }
    if (moved > 0) {
      talker.info('[PRE-BUFFER] prioritized $moved urls');
    }
  }

  @override
  void returnToPool(String url, PreBufferedPlayer entry) {
    if (_disposed || _ready.containsKey(url)) {
      entry.controller.dispose();
      _notifyAfterDispose();
      return;
    }
    // pause → seek → mute: pause stops decoding so seek has nothing in flight,
    // then mute is a no-op on display so its async ordering can't flash audio.
    unawaited(entry.controller.pause());
    unawaited(entry.controller.seekTo(Duration.zero));
    unawaited(entry.controller.setVolume(0));

    _evictIfNeeded();
    _ready[url] = entry;
    _readyOrder.add(url);
    talker.info('[PRE-BUFFER] returned to pool: $url');
  }

  @override
  void setMaxConcurrent(int value) {
    if (value < 1) return;
    _maxConcurrent = value;
    talker.info('[PRE-BUFFER] maxConcurrent set to $value');
    _processQueue();
  }

  @override
  void flushForBackground() {
    if (_disposed) return;
    final hadAny = _ready.isNotEmpty || _processing.isNotEmpty;
    talker.warning(
      '[PRE-BUFFER] flushForBackground — releasing '
      '${_ready.length} ready controllers + ${_processing.length} '
      'in-flight inits to minimise background memory footprint',
    );
    // Cancel in-flight inits — they will dispose themselves on the
    // next async tick via the _cancelled set check in _initOne.
    _cancelled.addAll(_processing);
    _queue.clear();
    // Dispose all already-ready controllers immediately.
    for (final entry in _ready.values) {
      unawaited(entry.controller.dispose());
    }
    _ready.clear();
    _readyOrder.clear();
    _paused = true;
    if (hadAny) _notifyAfterDispose();
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    talker.info('[PRE-BUFFER] disposing ${_ready.length} unclaimed controllers');
    final hadAny = _ready.isNotEmpty;
    for (final entry in _ready.values) {
      unawaited(entry.controller.dispose());
    }
    _ready.clear();
    _readyOrder.clear();
    _queue.clear();
    _processing.clear();
    _cancelled.clear();
    if (hadAny) _notifyAfterDispose();
    _afterDisposeListeners.clear();
  }
}
