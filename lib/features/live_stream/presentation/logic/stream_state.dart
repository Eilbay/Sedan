part of 'stream_cubit.dart';

enum StreamStatus { initial, loading, success, error }

class StreamState {
  const StreamState({
    this.status = StreamStatus.initial,
    this.stream,
    this.streams,
    this.error,
    this.currentIndex = 0,
    this.bannedStreamIds = const {},
  });

  final StreamStatus status;
  final StreamModel? stream;
  final Streams? streams;
  final String? error;
  final int currentIndex;
  /// Stream IDs from which the current user was banned this session.
  /// Persists across list refreshes so banned streams never re-appear.
  final Set<String> bannedStreamIds;

  /// The live stream owned by [ownerId], if that user is currently live.
  /// Used to show the "on air" ring around their avatar app-wide.
  StreamModel? liveStreamForOwner(String ownerId) {
    if (ownerId.isEmpty) return null;
    final results = streams?.results;
    if (results == null) return null;
    for (final stream in results) {
      if (stream.isLive && stream.owner.id.trim() == ownerId.trim()) {
        return stream;
      }
    }
    return null;
  }

  StreamState copyWith({
    StreamStatus? status,
    StreamModel? stream,
    Streams? streams,
    String? error,
    int? currentIndex,
    Set<String>? bannedStreamIds,
  }) {
    return StreamState(
      status: status ?? this.status,
      stream: stream ?? this.stream,
      streams: streams ?? this.streams,
      error: error ?? this.error,
      currentIndex: currentIndex ?? this.currentIndex,
      bannedStreamIds: bannedStreamIds ?? this.bannedStreamIds,
    );
  }
}
