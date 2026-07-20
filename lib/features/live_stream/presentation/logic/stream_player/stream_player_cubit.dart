import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:optombai/core/error/stream_log_file.dart';
import 'package:optombai/features/live_stream/data/data_sources/live_stream_web_rtc_player.dart';
import 'package:optombai/features/live_stream/domain/repositories/live_stream_repository.dart';

part 'stream_player_state.dart';

class StreamPlayerCubit extends Cubit<StreamPlayerState> {
  StreamPlayerCubit({
    required this.streamId,
    required this.playApiUrl,
    required this.streamUrl,
    required LiveStreamRepository repository,
  })  : _repository = repository,
        super(const StreamPlayerState());

  final String streamId;
  final String playApiUrl;
  final String streamUrl;

  LiveStreamWebRtcPlayer? _player;
  bool _isActive = false;
  Timer? _liveCheckTimer;
  final LiveStreamRepository _repository;

  Future<void> init() async {
    if (isClosed) return;
    if (state.status == StreamPlayerStatus.loading ||
        state.status == StreamPlayerStatus.success) {
      return;
    }

    if (state.status == StreamPlayerStatus.ended) {
      return;
    }

    emit(state.copyWith(status: StreamPlayerStatus.loading));

    StreamLogFile.log(
        '[LS_PLAYER] init stream=$streamId playApi=$playApiUrl url=$streamUrl');

    try {
      _player = LiveStreamWebRtcPlayer(
        playApiUrl: playApiUrl,
        streamUrl: streamUrl,
        onStreamEnded: _handleStreamEnded,
      );

      await _player!.init();
      if (isClosed || (_player?.isDisposed ?? true)) return;

      await _player!.play();
      if (isClosed || (_player?.isDisposed ?? true)) return;

      _applyAudioState();

      StreamLogFile.log('[LS_PLAYER] playing stream=$streamId');
      emit(state.copyWith(
        status: StreamPlayerStatus.success,
        renderer: _player!.renderer,
      ));

      _startLiveCheck();
    } catch (e) {
      StreamLogFile.log('[LS_PLAYER] init FAILED stream=$streamId: $e',
          isWarning: true);
      final failedPlayer = _player;
      _player = null;
      failedPlayer?.stopImmediately();
      await failedPlayer?.dispose();
      if (!isClosed) {
        emit(state.copyWith(
          status: StreamPlayerStatus.error,
          error: e.toString(),
        ));
      }
    }
  }

  void _handleStreamEnded() {
    if (isClosed) return;
    StreamLogFile.log(
        '[LS_PLAYER] stream ended detected via WebRTC for $streamId');
    _stopLiveCheck();
    emit(state.copyWith(status: StreamPlayerStatus.ended));
  }

  /// Periodically check if the stream is still live via API.
  /// WebRTC disconnect detection is unreliable — the SRS server may
  /// not immediately close the peer connection when the streamer stops.
  void _startLiveCheck() {
    _liveCheckTimer?.cancel();
    _liveCheckTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _checkIfStillLive(),
    );
  }

  void _stopLiveCheck() {
    _liveCheckTimer?.cancel();
    _liveCheckTimer = null;
  }

  Future<void> _checkIfStillLive() async {
    if (isClosed || state.status == StreamPlayerStatus.ended) {
      _stopLiveCheck();
      return;
    }

    try {
      final isLive = await _repository.isStreamLive(streamId: streamId);
      if (isClosed) return;

      if (!isLive) {
        StreamLogFile.log(
            '[LS_PLAYER] stream $streamId is no longer live (API poll)');
        _handleStreamEnded();
      }
    } catch (e) {
      debugPrint('[StreamPlayerCubit] Live check error: $e');
    }
  }

  void setActive(bool isActive) {
    if (_isActive == isActive) return;
    _isActive = isActive;
    _applyAudioState();
  }

  void _applyAudioState() {
    _player?.setAudioEnabled(_isActive);
  }

  @override
  Future<void> close() async {
    _stopLiveCheck();
    final player = _player;
    _player = null;
    player?.stopImmediately();
    await player?.dispose();
    return super.close();
  }
}
