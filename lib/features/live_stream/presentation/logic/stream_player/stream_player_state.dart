part of 'stream_player_cubit.dart';

enum StreamPlayerStatus { initial, loading, success, error, ended }

class StreamPlayerState {
  const StreamPlayerState({
    this.status = StreamPlayerStatus.initial,
    this.renderer,
    this.error,
    this.streamCountViewers = 0,
  });

  final StreamPlayerStatus status;
  final RTCVideoRenderer? renderer;
  final String? error;
  final int streamCountViewers;

  StreamPlayerState copyWith({
    StreamPlayerStatus? status,
    RTCVideoRenderer? renderer,
    String? error,
    int? streamCountViewers,
  }) {
    return StreamPlayerState(
      status: status ?? this.status,
      renderer: renderer ?? this.renderer,
      error: error ?? this.error,
      streamCountViewers: streamCountViewers ?? this.streamCountViewers,
    );
  }
}
