import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:optombai/configs/constrants.dart';
import 'package:optombai/data/repositories/i_pit_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:optombai/bloc/pit_bloc/pit_event.dart';
import 'package:optombai/bloc/pit_bloc/pit_state.dart';

class PitBloc extends Bloc<PitEvent, PitState> {
  final IPitRepository _repository;
  final SharedPreferences preferences;

  PitBloc({required IPitRepository repository, required this.preferences})
      : _repository = repository,
        super(const PitState()) {
    on<LoadPitEvent>(_onLoadPit);
    on<InitPitEvent>(_onInitPit);
    on<IAPPitEvent>(_onIAPPit);
    on<ResetPitStateEvent>(_onResetState);
    on<MockCreditPitEvent>(_onMockCreditPit);
    on<MockDebitPitEvent>(_onMockDebitPit);
  }

  String _getToken() => preferences.getString(TOKEN_KEY) ?? '';

  // DEMO MODE: the wallet balance is a purely local mock
  void _onLoadPit(
    LoadPitEvent event,
    Emitter<PitState> emit,
  ) {
    emit(state.copyWith(isLoading: false, isSuccess: true, errors: []));
  }

  Future<void> _onInitPit(
    InitPitEvent event,
    Emitter<PitState> emit,
  ) async {
    emit(state.copyWith(isProcessing: true, errors: [], isSuccess: false));

    try {
      final response = await _repository.initPit(
        amount: event.amount,
        provider: event.provider,
        currency: event.currency,
        token: _getToken(),
      );

      emit(state.copyWith(
        isProcessing: false,
        isSuccess: true,
        pitResponse: response,
      ));
    } catch (e) {
      debugPrint('InitPitEvent error: $e');
      emit(state.copyWith(
        isProcessing: false,
        errors: [e.toString()],
      ));
    }
  }

  Future<void> _onIAPPit(
    IAPPitEvent event,
    Emitter<PitState> emit,
  ) async {
    emit(state.copyWith(
      isProcessing: true,
      errors: [],
      isIAPSuccess: false,
    ));

    try {
      final response = await _repository.pitViaIAP(
        receiptData: event.receiptData,
        productId: event.productId,
        platform: event.platform,
        transactionId: event.transactionId,
        token: _getToken(),
      );

      if (response.success) {
        emit(state.copyWith(
          isProcessing: false,
          isIAPSuccess: true,
          iapPitResponse: response,
          balance: response.newBalance ?? state.balance,
        ));
      } else {
        emit(state.copyWith(
          isProcessing: false,
          errors: [
            response.message.isNotEmpty ? response.message : 'Ошибка пополнения'
          ],
        ));
      }
    } catch (e) {
      debugPrint('IAPPitEvent error: $e');
      emit(state.copyWith(
        isProcessing: false,
        errors: [e.toString()],
      ));
    }
  }

  void _onMockCreditPit(
    MockCreditPitEvent event,
    Emitter<PitState> emit,
  ) {
    emit(state.copyWith(
      balance: state.balance + event.amount,
      isSuccess: true,
      isProcessing: false,
    ));
  }

  void _onMockDebitPit(
    MockDebitPitEvent event,
    Emitter<PitState> emit,
  ) {
    emit(state.copyWith(
      balance: (state.balance - event.amount).clamp(0, double.infinity),
    ));
  }

  void _onResetState(
    ResetPitStateEvent event,
    Emitter<PitState> emit,
  ) {
    emit(state.copyWith(
      isSuccess: false,
      isIAPSuccess: false,
      errors: [],
      pitResponse: null,
      iapPitResponse: null,
    ));
  }
}
