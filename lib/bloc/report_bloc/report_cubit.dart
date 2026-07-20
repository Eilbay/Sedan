import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:optombai/configs/constrants.dart';
import 'package:optombai/core/debug/talker_instance.dart';
import 'package:optombai/core/error/app_exception.dart';
import 'package:optombai/data/models/report/report_category.dart';
import 'package:optombai/data/models/report/report_model.dart';
import 'package:optombai/data/models/report/report_target_type.dart';
import 'package:optombai/data/repositories/i_report_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'report_state.dart';

/// Stateless cubit-like wrapper over [IReportRepository]. UI flows submit a
/// report once and listen for the resulting [ReportState] to show a snackbar.
class ReportCubit extends Cubit<ReportState> {
  final IReportRepository _repository;
  final SharedPreferences _preferences;

  ReportCubit({
    required IReportRepository repository,
    required SharedPreferences preferences,
  })  : _repository = repository,
        _preferences = preferences,
        super(const ReportState());

  String get _token => _preferences.getString(TOKEN_KEY) ?? '';

  Future<void> submitReport({
    required ReportTargetType targetType,
    required String targetId,
    required ReportCategory category,
    String? reason,
    bool alsoBlock = false,
  }) async {
    emit(state.copyWith(isSubmitting: true, isSuccess: false, errors: const []));
    try {
      final report = await _repository.createReport(
        targetType: targetType,
        targetId: targetId,
        category: category,
        reason: reason,
        alsoBlock: alsoBlock,
        token: _token,
      );
      emit(state.copyWith(
        isSubmitting: false,
        isSuccess: true,
        lastReport: report,
        alsoBlocked: alsoBlock,
      ));
    } on AppException catch (e) {
      emit(state.copyWith(isSubmitting: false, errors: e.messages));
    } catch (e, st) {
      // Any non-domain error (e.g. response parsing) must still clear the
      // submitting flag — otherwise the submit button spins forever.
      talker.handle(e, st, 'submitReport failed');
      emit(state.copyWith(
        isSubmitting: false,
        errors: const ['Не удалось отправить жалобу, повторите попытку'],
      ));
    }
  }

  void reset() => emit(const ReportState());
}
