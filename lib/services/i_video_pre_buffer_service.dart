import 'package:video_player/video_player.dart';

/// A pre-buffered video controller, initialized and paused.
class PreBufferedPlayer {
  PreBufferedPlayer({required this.controller});
  final VideoPlayerController controller;
}

/// Abstract interface for video pre-buffering.
///
/// Pre-buffers [VideoPlayerController]s so reels start instantly.
/// Controllers are created on the splash screen and extended via rolling
/// pre-buffer in [ReelsViewerScreen]. [ReelPlaybackManager] claims them
/// via [take] — caller becomes the owner and must dispose them.
abstract class IVideoPreBufferService {
  /// Add URLs to the pre-buffer queue. Deduplicates automatically.
  void enqueue(List<String> urls);

  /// Take a ready controller. Returns null if not ready yet.
  /// Caller becomes owner and must dispose the controller.
  PreBufferedPlayer? take(String url);

  /// Pause the pre-buffer queue (gives priority to active downloads).
  void pause();

  /// Resume the pre-buffer queue after a pause.
  void resume();

  /// Whether the given [url] is currently being initialized (in-flight).
  bool isProcessing(String url);

  /// Remove a URL from the queue or cancel its in-flight init.
  void cancel(String url);

  /// Cancel everything pending: drop the queue and mark in-flight inits
  /// for disposal once they finish. Does not touch already-ready
  /// controllers (use [dispose] for that). Use on reels-screen exit to
  /// stop background downloads when the user leaves the feed.
  void cancelAll();

  /// Move [urls] to the front of the queue so they are initialized next.
  /// Does not duplicate — if a URL is already queued it is moved forward.
  /// URLs that are already ready or processing are ignored.
  void prioritize(List<String> urls);

  /// Update the maximum number of concurrent pre-buffer initializations.
  void setMaxConcurrent(int value);

  /// Return a previously claimed controller back to the ready pool.
  /// The controller is paused, seeked to zero, and muted.
  /// If the pool is full, the oldest entry is evicted.
  void returnToPool(String url, PreBufferedPlayer entry);

  /// Dispose all unclaimed controllers and clear the queue.
  void dispose();

  /// Release every ready controller + drop the queue **without killing
  /// the service itself**. Called on app-backgrounded so iOS sees a
  /// minimal memory footprint and does not prioritise our app for
  /// background eviction. After `resume()` the pool refills on the
  /// next `enqueue` call.
  void flushForBackground();

  /// Subscribe to be notified just after the service disposes any internal
  /// controller, so the listener can resync its currently active sibling
  /// controller (workaround for legacy media_kit silent-pause bug, kept
  /// for symmetry — video_player doesn't have this bug).
  /// Returns a function to unregister the callback.
  void Function() addAfterDisposeCallback(void Function() callback);
}
