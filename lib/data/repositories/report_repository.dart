import 'package:dio/dio.dart';
import 'package:optombai/core/error/app_exception.dart';
import 'package:optombai/data/api_client.dart';
import 'package:optombai/data/domain_set.dart';
import 'package:optombai/data/models/report/report_category.dart';
import 'package:optombai/data/models/report/report_model.dart';
import 'package:optombai/data/models/report/report_target_type.dart';
import 'package:optombai/data/repositories/i_report_repository.dart';

class ReportRepository implements IReportRepository {
  final Dio _dio = ApiClient.I.dio;

  static String get _baseUrl => '${ApiEndpoints.baseApi}/reports/';

  @override
  Future<ReportModel> createReport({
    required ReportTargetType targetType,
    required String targetId,
    required ReportCategory category,
    String? reason,
    bool alsoBlock = false,
    required String token,
  }) async {
    try {
      final response = await _dio.post(
        _baseUrl,
        data: {
          'target_type': targetType.wireValue,
          'target_id': targetId,
          'category': category.wireValue,
          'reason': reason ?? '',
          'also_block': alsoBlock,
        },
        options: optionsNoCache(token),
      );
      return ReportModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }
}
