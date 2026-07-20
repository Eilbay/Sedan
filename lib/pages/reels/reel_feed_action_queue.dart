import 'dart:async';
import 'dart:collection';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Kind of best-effort reel feed event delivered to the backend.
enum ReelFeedActionKind { progress, impression }

/// A single pending reel feed action (progress mark or promo impression).
@immutable
class PendingReelAction {
  const PendingReelAction(this.kind, this.postId);

  final ReelFeedActionKind kind;
  final String postId;

  /// Dedup key — one delivery per (kind, post) per session.
  String get key => '${kind.name}:$postId';
}

/// Reliable, offline-aware delivery of reel feed events (progress + promo
/// impressions).
///
/// Responsibilities (single purpose: guaranteed delivery):
/// - Deduplicates each (kind, post) so an event is never sent twice.
/// - Tries to send immediately; on failure (typically offline) keeps the
///   action in an in-memory queue.
/// - Flushes the queue when connectivity returns and on demand (e.g. when the
///   app is backgrounded).
///
/// The queue is intentionally in-memory: a lost trailing progress mark only
/// means the feed resumes a reel or two earlier — not worth disk persistence.
class ReelFeedActionQueue {
  ReelFeedActionQueue({
    required Future<void> Function(PendingReelAction action) sender,
    Connectivity? connectivity,
  })  : _send = sender,
        _connectivity = connectivity ?? Connectivity() {
    _connectivitySub =
        _connectivity.onConnectivityChanged.listen(_onConnectivityChanged);
  }

  final Future<void> Function(PendingReelAction action) _send;
  final Connectivity _connectivity;

  final Queue<PendingReelAction> _pending = Queue<PendingReelAction>();
  final Set<String> _seen = <String>{};

  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  bool _draining = false;
  bool _disposed = false;

  /// Number of actions still waiting to be delivered (for tests/diagnostics).
  @visibleForTesting
  int get pendingCount => _pending.length;

  /// Enqueue an action. Ignored if an identical action was already accepted
  /// this session. Triggers an immediate delivery attempt.
  void enqueue(PendingReelAction action) {
    if (_disposed) return;
    if (!_seen.add(action.key)) return; // already accepted
    _pending.add(action);
    unawaited(_drain());
  }

  /// Attempt to deliver every queued action now. Stops at the first failure
  /// (assumes the network is down) and leaves the rest queued.
  Future<void> flush() => _drain();

  Future<void> _drain() async {
    if (_disposed || _draining || _pending.isEmpty) return;
    _draining = true;
    try {
      while (_pending.isNotEmpty) {
        final action = _pending.first;
        try {
          await _send(action);
          _pending.removeFirst();
        } catch (e) {
          // Likely offline / transient — keep this and the rest for a later
          // flush (connectivity change or app pause).
          debugPrint('[REEL-QUEUE] delivery failed (${action.key}): $e');
          break;
        }
      }
    } finally {
      _draining = false;
    }
  }

  void _onConnectivityChanged(List<ConnectivityResult> results) {
    final online =
        results.any((r) => r != ConnectivityResult.none) && results.isNotEmpty;
    if (online) unawaited(_drain());
  }

  void dispose() {
    _disposed = true;
    _connectivitySub?.cancel();
    _connectivitySub = null;
    _pending.clear();
  }
}
