import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:optombai/core/error/app_exception.dart';
import 'package:optombai/data/repositories/i_admin_request_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:optombai/configs/constrants.dart';

part 'admin_request_event.dart';

part 'admin_request_state.dart';

class AdminRequestBloc extends Bloc<AdminRequestEvent, AdminRequestState> {
  final IAdminRequestRepository _repository;
  final SharedPreferences preferences;

  AdminRequestBloc({required IAdminRequestRepository repository, required this.preferences})
      : _repository = repository,
        super(const AdminRequestState()) {
    on<SendRequest>(sendRequest);
  }

  String getToken() => preferences.getString(TOKEN_KEY) ?? "";

  sendRequest(SendRequest event, emit) async {
    debugPrint("sendRequest");
    emit(state.copyWith(isLoading: true));
    try {
      await _repository.requestToAdmin(getToken(), event.requset);
      emit(state.copyWith(isSuccess: true));
    } on AppException catch (e) {
      emit(state.copyWith(errors: e.messages));
    }
  }
}
