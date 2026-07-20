import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:optombai/configs/constrants.dart';
import 'package:optombai/core/debug/talker_instance.dart';
import 'package:optombai/core/error/app_exception.dart';
import 'package:optombai/data/models/block/block_model.dart';
import 'package:optombai/data/repositories/i_block_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'block_event.dart';
part 'block_state.dart';

class BlockBloc extends Bloc<BlockEvent, BlockState> {
  final IBlockRepository _repository;
  final SharedPreferences _preferences;

  BlockBloc({
    required IBlockRepository repository,
    required SharedPreferences preferences,
  })  : _repository = repository,
        _preferences = preferences,
        super(const BlockState()) {
    on<LoadBlocksEvent>(_onLoadBlocks);
    on<BlockUserEvent>(_onBlockUser);
    on<UnblockUserEvent>(_onUnblockUser);
    on<ResetBlockStatusEvent>(_onReset);
  }

  String get _token => _preferences.getString(TOKEN_KEY) ?? '';

  Future<void> _onLoadBlocks(
    LoadBlocksEvent event,
    Emitter<BlockState> emit,
  ) async {
    if (!event.forceRefresh && state.results.isNotEmpty && !state.isLoading) {
      return;
    }
    emit(state.copyWith(isLoading: true, errors: const []));
    try {
      final response = await _repository.fetchBlocks(token: _token);
      emit(state.copyWith(
        isLoading: false,
        isSuccess: true,
        results: response.results,
        blockedIds: response.results.map((b) => b.blocked.id).toSet(),
      ));
    } on AppException catch (e) {
      emit(state.copyWith(isLoading: false, errors: e.messages));
    } catch (e, st) {
      // Non-domain errors (e.g. response parsing) must still clear the
      // loading flag — otherwise the blocks screen stays stuck loading.
      talker.handle(e, st, 'loadBlocks failed');
      emit(state.copyWith(
        isLoading: false,
        errors: const ['Не удалось загрузить список блокировок'],
      ));
    }
  }

  Future<void> _onBlockUser(
    BlockUserEvent event,
    Emitter<BlockState> emit,
  ) async {
    emit(state.copyWith(
      isMutating: true,
      errors: const [],
      justBlockedUserId: '',
    ));
    try {
      final block = await _repository.blockUser(
        userId: event.userId,
        reason: event.reason,
        token: _token,
      );
      final exists = state.results.any((b) => b.blocked.id == event.userId);
      final updated = exists
          ? state.results
              .map((b) => b.blocked.id == event.userId ? block : b)
              .toList()
          : [block, ...state.results];
      emit(state.copyWith(
        isMutating: false,
        results: updated,
        blockedIds: {...state.blockedIds, event.userId},
        justBlockedUserId: event.userId,
      ));
    } on AppException catch (e) {
      emit(state.copyWith(isMutating: false, errors: e.messages));
    } catch (e, st) {
      // Non-domain errors (e.g. response parsing) must still clear the
      // mutating flag — otherwise the block action spins forever.
      talker.handle(e, st, 'blockUser failed');
      emit(state.copyWith(
        isMutating: false,
        errors: const ['Не удалось заблокировать пользователя'],
      ));
    }
  }

  Future<void> _onUnblockUser(
    UnblockUserEvent event,
    Emitter<BlockState> emit,
  ) async {
    emit(state.copyWith(
      isMutating: true,
      errors: const [],
      justUnblockedUserId: '',
    ));
    try {
      await _repository.unblockUser(userId: event.userId, token: _token);
      final updated = state.results
          .where((b) => b.blocked.id != event.userId)
          .toList();
      final updatedIds = {...state.blockedIds}..remove(event.userId);
      emit(state.copyWith(
        isMutating: false,
        results: updated,
        blockedIds: updatedIds,
        justUnblockedUserId: event.userId,
      ));
    } on AppException catch (e) {
      emit(state.copyWith(isMutating: false, errors: e.messages));
    } catch (e, st) {
      // Non-domain errors (e.g. response parsing) must still clear the
      // mutating flag — otherwise the unblock action spins forever.
      talker.handle(e, st, 'unblockUser failed');
      emit(state.copyWith(
        isMutating: false,
        errors: const ['Не удалось разблокировать пользователя'],
      ));
    }
  }

  void _onReset(ResetBlockStatusEvent event, Emitter<BlockState> emit) {
    emit(state.copyWith(
      errors: const [],
      justBlockedUserId: '',
      justUnblockedUserId: '',
    ));
  }

  /// Sync helper for widgets that need a fast "is user blocked?" check.
  bool isUserBlocked(String userId) => state.blockedIds.contains(userId);
}
