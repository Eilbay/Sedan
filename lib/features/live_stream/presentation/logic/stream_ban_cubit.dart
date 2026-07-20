import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:optombai/features/live_stream/data/models/stream_ban_model.dart';
import 'package:optombai/features/live_stream/domain/repositories/live_stream_repository.dart';

class StreamBanState {
  const StreamBanState({
    this.isLoading = false,
    this.lastBan,
    this.error,
  });

  final bool isLoading;
  final StreamBanModel? lastBan;
  final String? error;

  StreamBanState copyWith({
    bool? isLoading,
    StreamBanModel? lastBan,
    String? error,
  }) {
    return StreamBanState(
      isLoading: isLoading ?? this.isLoading,
      lastBan: lastBan ?? this.lastBan,
      error: error,
    );
  }
}

/// Handles ban/unban actions performed by the stream owner.
class StreamBanCubit extends Cubit<StreamBanState> {
  StreamBanCubit({
    required LiveStreamRepository repository,
    required String token,
    required String streamId,
  })  : _repository = repository,
        _token = token,
        _streamId = streamId,
        super(const StreamBanState());

  final LiveStreamRepository _repository;
  final String _token;
  final String _streamId;

  Future<void> banUser(
    String userId, {
    int? minutes,
    String? reason,
  }) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final result = await _repository.banUser(
        token: _token,
        streamId: _streamId,
        userId: userId,
        minutes: minutes,
        reason: reason,
      );
      emit(state.copyWith(isLoading: false, lastBan: result));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> unbanUser(String userId) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      await _repository.unbanUser(
        token: _token,
        streamId: _streamId,
        userId: userId,
      );
      emit(state.copyWith(isLoading: false));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }
}
