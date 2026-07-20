import 'package:optombai/data/models/report/report_category.dart';
import 'package:optombai/data/models/report/report_model.dart';
import 'package:optombai/data/models/report/report_target_type.dart';

abstract interface class IReportRepository {
  /// POST /reports/ — submit a report. If [alsoBlock] is true the backend
  /// will also block the target's author in the same call.
  ///
  /// Returns 201 for new reports, 200 if user has already reported the same
  /// target — both cases yield a valid [ReportModel]. The UI should treat
  /// both as success without distinction.
  Future<ReportModel> createReport({
    required ReportTargetType targetType,
    required String targetId,
    required ReportCategory category,
    String? reason,
    bool alsoBlock = false,
    required String token,
  });
}
