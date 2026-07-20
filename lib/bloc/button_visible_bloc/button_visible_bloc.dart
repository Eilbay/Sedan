import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import 'package:optombai/bloc/user_bloc/user_bloc.dart';
import 'package:optombai/utils/extensions/country_model_extension.dart';

import 'package:optombai/core/form_status.dart';
import 'package:optombai/firebase/service.dart';

part 'button_visible_event.dart';
part 'button_visible_state.dart';

class ButtonVisibleBloc extends Bloc<ButtonVisibleEvent, ButtonVisibleState> {
  final FirebaseService _firebaseService;
  final UserBloc _userBloc;

  StreamSubscription<bool>? isVisibleSubscription;
  StreamSubscription<UserState>? _userSub;

  bool _firebaseVisible = false;
  bool _allowedByCountry = false;
  bool _isAuthenticated = false;

  ButtonVisibleBloc(this._firebaseService, this._userBloc)
      : super(const ButtonVisibleState()) {
    on<LoadButtonVisible>(_onLoadButtonVisible);
    on<ButtonVisibleChanged>(_onButtonVisibleChanged);
    on<UpdateButtonVisible>(_onUpdateButtonVisible);
    on<_RecombineVisibility>(_onRecombineVisibility);

    _isAuthenticated = _userBloc.state.user.id.isNotEmpty;
    _allowedByCountry =
        _userBloc.state.user.country.isTariffAllowed;

    _userSub = _userBloc.stream.listen((uState) {
      _isAuthenticated = uState.user.id.isNotEmpty;
      _allowedByCountry = uState.user.country.isTariffAllowed;
      add(const _RecombineVisibility());
    });
  }

  void _emitCombined(Emitter<ButtonVisibleState> emit) {
    // Unauth users have no country data — show if Firebase allows it.
    // Auth users — also check country whitelist.
    final showTariffs = _firebaseVisible &&
        (!_isAuthenticated || _allowedByCountry);

    emit(state.copyWith(
      status: FormStatus.submissionSuccess,
      isVisible: showTariffs,
    ));
  }

  void _onRecombineVisibility(
      _RecombineVisibility event, Emitter<ButtonVisibleState> emit) {
    _emitCombined(emit);
  }

  Future<void> _onLoadButtonVisible(
      LoadButtonVisible event, Emitter<ButtonVisibleState> emit) async {
    emit(state.copyWith(status: FormStatus.submissionInProgress));

    try {
      _firebaseVisible = await _firebaseService.getButtonVisibility();
      _emitCombined(emit);

      isVisibleSubscription =
          _firebaseService.listenToButtonVisibility().listen((mode) {
        _firebaseVisible = mode;
        add(ButtonVisibleChanged(isVisible: mode));
      });
    } catch (e) {
      emit(state.copyWith(
        status: FormStatus.submissionFailure,
        error: e.toString(),
      ));
    }
  }

  void _onButtonVisibleChanged(
      ButtonVisibleChanged event, Emitter<ButtonVisibleState> emit) {
    _firebaseVisible = event.isVisible;
    emit(state.copyWith(statusChangeMode: FormStatus.submissionInProgress));
    emit(state.copyWith(statusChangeMode: FormStatus.submissionSuccess));
    _emitCombined(emit);
  }

  Future<void> _onUpdateButtonVisible(
      UpdateButtonVisible event, Emitter<ButtonVisibleState> emit) async {
    try {
      await _firebaseService.setButtonVisibility(event.isVisible);
    } catch (e) {
      emit(state.copyWith(
        status: FormStatus.submissionFailure,
        error: e.toString(),
      ));
    }
  }

  @override
  Future<void> close() {
    isVisibleSubscription?.cancel();
    _userSub?.cancel();
    return super.close();
  }
}
