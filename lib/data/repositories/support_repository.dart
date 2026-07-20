import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:optombai/core/error/app_exception.dart';
import 'package:optombai/data/api_client.dart';
import 'package:optombai/data/domain_set.dart';
import 'package:optombai/data/models/support/support_session_model.dart';
import 'package:optombai/data/repositories/i_support_repository.dart';

class SupportRepository implements ISupportRepository {
  final Dio _dio = ApiClient.I.dio;

  /// GET /support/my
  Future<SupportSession?> getActiveSession(String token) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.supportMyApi,
        options: options(token),
      );

      return SupportSession.fromJson(response.data);
    } on DioException catch (e) {
      final appException = ErrorHandler.handle(e);
      if (appException is NotFoundException) return null;
      throw appException;
    }
  }

  /// POST /support/start
  Future<SupportSession> startSupportSession({
    required String text,
    required String token,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.supportStartApi,
        data: jsonEncode({
          'type': 'text',
          'text': text,
        }),
        options: Options(
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
            "Cache-Control": "no-cache",
            "Pragma": "no-cache",
          },
        ),
      );

      return SupportSession.fromJson(response.data);
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  /// POST /support/sessions/{sessionId}/close
  Future<SupportSession> closeSession({
    required String sessionId,
    required String comment,
    required String token,
  }) async {
    try {
      final response = await _dio.post(
        '${ApiEndpoints.supportApi}/sessions/$sessionId/close',
        data: jsonEncode({
          'comment': comment,
        }),
        options: Options(
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
            "Cache-Control": "no-cache",
            "Pragma": "no-cache",
          },
        ),
      );

      return SupportSession.fromJson(response.data);
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }
}
