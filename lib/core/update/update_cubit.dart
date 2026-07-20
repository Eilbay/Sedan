import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:optombai/core/update/app_update_checker.dart';
import 'package:optombai/core/update/app_update_info.dart';
import 'package:optombai/core/update/update_type.dart';

part 'update_state.dart';

class UpdateCubit extends Cubit<UpdateState> {
  UpdateCubit({required AppUpdateChecker checker})
      : _checker = checker,
        super(const UpdateState());

  final AppUpdateChecker _checker;

  Future<void> check() async {
    final info = await _checker.check();
    emit(state.copyWith(info: info));
  }

  /// Soft update dismissed for the current app session only — reappears on
  /// next launch, matching a typical "Позже" soft-update prompt.
  void dismissSoft() {
    if (state.info.type != UpdateType.soft) return;
    emit(state.copyWith(dismissed: true));
  }
}
