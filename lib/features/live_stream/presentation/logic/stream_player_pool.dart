import 'dart:async';

import 'package:optombai/features/live_stream/domain/repositories/live_stream_repository.dart';
import 'package:optombai/features/live_stream/presentation/logic/stream_player/stream_player_cubit.dart';

/// Manages a pool of StreamPlayerCubit instances to prevent memory leaks.
/// Keeps the currently visible stream and one neighbor active.
class StreamPlayerPool {
  StreamPlayerPool({
    required this.repository,
  });

  final LiveStreamRepository repository;
  final Map<String, StreamPlayerCubit> _cubits = {};
  final Map<String, int> _streamIndexMap = {};

  /// Get or create a StreamPlayerCubit for the given stream.
  StreamPlayerCubit getOrCreate({
    required String streamId,
    required String playApiUrl,
    required String streamUrl,
    required int index,
  }) {
    _streamIndexMap[streamId] = index;

    if (_cubits.containsKey(streamId)) {
      return _cubits[streamId]!;
    }

    final cubit = StreamPlayerCubit(
      streamId: streamId,
      playApiUrl: playApiUrl,
      streamUrl: streamUrl,
      repository: repository,
    );

    _cubits[streamId] = cubit;
    return cubit;
  }

  /// Initialize the player cubit only when stream becomes active.
  void ensureInitialized(String streamId) {
    _cubits[streamId]?.init();
  }

  /// Keep the active stream and both adjacent pages; dispose the rest.
  /// PageView fires onPageChanged while the previous page is still partly
  /// visible, so closing that renderer immediately produces a black half-page
  /// and makes a reverse swipe point at an already closed cubit.
  void keepWithNeighbors(
    String activeStreamId, {
    String? previousStreamId,
    String? nextStreamId,
  }) {
    final keysToKeep = <String>{activeStreamId};
    if (previousStreamId != null) keysToKeep.add(previousStreamId);
    if (nextStreamId != null) keysToKeep.add(nextStreamId);

    final keysToRemove = <String>[];
    for (final streamId in _cubits.keys) {
      if (!keysToKeep.contains(streamId)) {
        keysToRemove.add(streamId);
      }
    }

    for (final key in keysToRemove) {
      _closeCubit(key);
    }
  }

  /// Keep only the currently active stream player; dispose others immediately.
  void keepOnly(String activeStreamId) {
    keepWithNeighbors(activeStreamId);
  }

  /// Mark only the visible stream as an active viewer. Neighbor players can
  /// stay preloaded, but they must not increment the viewer count.
  void setActiveStream(String activeStreamId) {
    for (final entry in _cubits.entries) {
      entry.value.setActive(entry.key == activeStreamId);
    }
  }

  /// Dispose all cubits in the pool. Tracks are stopped synchronously
  /// inside cubit.close() so audio won't leak after this call.
  void disposeAll() {
    for (final cubit in _cubits.values) {
      unawaited(cubit.close());
    }
    _cubits.clear();
    _streamIndexMap.clear();
  }

  /// Mute every cubit without tearing down its WebRTC connection.
  /// Used when this tab is merely covered by another route (e.g. opening
  /// LiveRoomPage for the currently visible stream, which reuses the exact
  /// same cubit) rather than truly left — disposeAll() there would kill the
  /// connection the room is actively displaying.
  void pauseAll() {
    for (final cubit in _cubits.values) {
      cubit.setActive(false);
    }
  }

  void _closeCubit(String streamId) {
    final cubit = _cubits.remove(streamId);
    _streamIndexMap.remove(streamId);
    if (cubit != null) {
      unawaited(cubit.close());
    }
  }
}
