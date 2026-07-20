import 'package:bloc/bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:optombai/configs/constrants.dart';
import 'package:optombai/core/error/app_exception.dart';
import 'package:optombai/data/repositories/i_support_repository.dart';
import 'package:optombai/bloc/support_bloc/support_event.dart';
import 'package:optombai/bloc/support_bloc/support_state.dart';

class SupportBloc extends Bloc<SupportEvent, SupportState> {
  final ISupportRepository _repository;
  final SharedPreferences preferences;

  SupportBloc({required ISupportRepository repository, required this.preferences})
      : _repository = repository,
        super(const SupportState()) {
    on<CheckActiveSupportSessionEvent>(_onCheckActiveSession);
    on<StartSupportSessionEvent>(_onStartSession);
    on<CloseSupportSessionEvent>(_onCloseSession);
    on<ClearSupportEvent>(_onClearSupport);
  }

  String getToken() => preferences.getString(TOKEN_KEY) ?? "";
  _onCheckActiveSession(CheckActiveSupportSessionEvent event, emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      final session = await _repository.getActiveSession(getToken());
      emit(state.copyWith(
        isLoading: false,
        isSuccess: true,
        activeSession: session,
      ));
    } on AppException catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errors: e.messages,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errors: [e.toString()],
      ));
    }
  }

  _onStartSession(StartSupportSessionEvent event, emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      final session = await _repository.startSupportSession(
        text: event.text,
        token: getToken(),
      );
      emit(state.copyWith(
        isLoading: false,
        isSuccess: true,
        activeSession: session,
      ));
    } on AppException catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errors: e.messages,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errors: [e.toString()],
      ));
    }
  }

  _onCloseSession(CloseSupportSessionEvent event, emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      final closedSession = await _repository.closeSession(
        sessionId: event.sessionId,
        comment: event.comment,
        token: getToken(),
      );
      emit(state.copyWith(
        isLoading: false,
        isSuccess: true,
        activeSession: closedSession,
        clearActiveSession: true,
      ));
    } on AppException catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errors: e.messages,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errors: [e.toString()],
      ));
    }
  }

  _onClearSupport(ClearSupportEvent event, emit) {
    emit(const SupportState());
  }
}
