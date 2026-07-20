import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:optombai/core/error/app_exception.dart';
import 'package:optombai/data/api_client.dart';
import 'package:optombai/data/domain_set.dart';

import 'package:optombai/data/repositories/i_admin_request_repository.dart';

String get endpointDocumentImageAboutUs => '${ApiEndpoints.accountsApi}/documents/';

class AdminRequestRepository implements IAdminRequestRepository {
  final Dio _dio = ApiClient.I.dio;

  Future<void> requestToAdmin(String token, String request) async {
    try {
      Map<String, dynamic> map = {"request": request};
      debugPrint(request);
      await _dio.post(
        endpointDocumentImageAboutUs,
        data: FormData.fromMap(map),
        options: optionsFormData(token),
      );
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }
}
