import 'package:flutter/foundation.dart';
import 'package:optombai/configs/constrants.dart';
import 'package:optombai/core/error/app_exception.dart';
import 'package:optombai/data/models/pmt/pmt_model.dart';
import 'package:optombai/data/repositories/i_pmt_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:optombai/bloc/pmt_bloc/pmt_event.dart';
import 'package:optombai/bloc/pmt_bloc/pmt_state.dart';

class PmtBloc extends Bloc<PmtEvent, PmtState> {
  final IPmtRepository _repository;
  final SharedPreferences preferences;

  PmtBloc({required IPmtRepository repository, required this.preferences})
      : _repository = repository,
        super(const PmtState()) {
    on<PmtCreateEvent>(onPmtCreate);
    on<PmtHistoryEvent>(getPmtHistory);
    on<PmtStatusEvent>(getPmtStatus);
    on<PmtStatusUpdateEvent>(onPmtStatusUpdate);
    on<PmtByIdEvent>(getPmtById);
  }

  String getToken() => preferences.getString(TOKEN_KEY) ?? "";

  Future<void> onPmtCreate(PmtCreateEvent event, emit) async {
    emit(state.copyWith(isLoadingSend: true));
    try {
      var pmt = await _repository.createPmt(event.pmt, getToken());

      String redirectUrl = _repository.getPmtRedirectUrl(pmt.pmtId);

      emit(state.copyWith(
        isSuccess: true,
        list: [pmt, ...state.list],
        pmtRedirectUrl: redirectUrl,
      ));
    } catch (e) {
      emit(state.copyWith(
        isSuccess: false,
        isLoadingSend: false,
        errors: [e.toString()],
      ));
    }
  }

  Future<void> getPmtHistory(PmtHistoryEvent event, emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      var list = await _repository.getPmtHistory(getToken());
      emit(state.copyWith(list: list, isLoading: false));
    } catch (e) {
      emit(state.copyWith(errors: [e.toString()]));
    }
  }

  Future<void> getPmtStatus(PmtStatusEvent event, emit) async {
    try {
      final response = await _repository.getPmtStatus(getToken());

      if (response == null) {
        emit(state.copyWith(pmtStatus: null, currentPmt: null));
      } else {
        final pmt = PmtModel.fromJson(response.data);
        emit(state.copyWith(
          pmtStatus: pmt.status,
          currentPmt: pmt,
        ));
      }
    } on NotFoundException catch (_) {
      emit(state.copyWith(pmtStatus: null, currentPmt: null));
    } catch (e) {
      emit(state.copyWith(errors: [e.toString()]));
    }
  }

  Future<void> onPmtStatusUpdate(PmtStatusUpdateEvent event, emit) async {
    try {
      final updatedPmt = await _repository.updatePmtStatus(
          event.pmtId, "success", event.amount, event.pmtMethod, getToken());

      emit(state.copyWith(
        isSuccess: true,
        list: state.list.map((pmt) {
          return pmt.pmtId == event.pmtId ? updatedPmt : pmt;
        }).toList(),
      ));
    } catch (e) {
      emit(state.copyWith(errors: [e.toString()]));
    }
  }

  Future<void> getPmtById(PmtByIdEvent event, emit) async {
    try {
      PmtModel pmt = await _repository.getPmtById(event.pmtId, getToken());

      debugPrint("Received payment: ${pmt.toJson()}");
    } catch (e) {
      emit(state.copyWith(errors: [e.toString()]));
    }
  }

}
