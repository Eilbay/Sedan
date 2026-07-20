import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:optombai/data/api_client.dart';
import 'package:optombai/data/domain_set.dart';

import 'package:optombai/data/repositories/i_iap_repository.dart';

String get iapValidateUrl => ApiEndpoints.iapValidateApi;

class IAPRepository implements IIapRepository {
  final Dio _dio = ApiClient.I.dio;

  Future<IAPValidationResult> validateReceipt({
    required String receiptData,
    required String productId,
    required String platform,
    required String transactionId,
    required String token,
    required String packageName,
  }) async {
    // Backend expects "apple" or "google", not "ios" or "android"
    final platformValue = platform == 'ios' ? 'apple' : 'google';

    final requestData = {
      'platform': platformValue,
      'receipt_data': receiptData,
      'subscription_id': productId,
      'package_name': packageName,
      'transaction_id': transactionId,
      if (platform == 'android') 'token': receiptData,
    };

    debugPrint('IAPRepository: Sending validation request to $iapValidateUrl');
    debugPrint('IAPRepository: Request data: $requestData');
    debugPrint('IAPRepository: receipt_data length=${receiptData.length}');

    try {
      final response = await _dio.post(
        iapValidateUrl,
        data: requestData,
        options: options(token),
      );

      debugPrint('IAPRepository: Response status=${response.statusCode}');
      debugPrint('IAPRepository: Response data=${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;
        final isSuccess = data is Map && data['success'] == true;

        return IAPValidationResult(
          isValid: isSuccess,
          data: data,
          error: isSuccess ? null : (data['error']?.toString() ?? data['message']?.toString() ?? 'Validation failed'),
        );
      }

      return IAPValidationResult(
        isValid: false,
        error: 'Validation failed: ${response.statusCode}',
      );
    } on DioException catch (e) {
      debugPrint('IAPRepository: Error status=${e.response?.statusCode}');
      debugPrint('IAPRepository: Error data=${e.response?.data}');
      return IAPValidationResult(
        isValid: false,
        error: e.response?.data?.toString() ?? e.message ?? 'Unknown error',
      );
    }
  }
}

class IAPValidationResult {
  final bool isValid;
  final dynamic data;
  final String? error;

  IAPValidationResult({
    required this.isValid,
    this.data,
    this.error,
  });
}
