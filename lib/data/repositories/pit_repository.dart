import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:optombai/core/error/app_exception.dart';
import 'package:optombai/data/api_client.dart';
import 'package:optombai/data/domain_set.dart';
import 'package:optombai/data/models/pit/pit_model.dart';
import 'package:optombai/data/repositories/i_pit_repository.dart';

class PitRepository implements IPitRepository {
  final Dio _dio = ApiClient.I.dio;

  static String get _adWalletEndpoint =>
      '${ApiEndpoints.baseApi}/ad-wallet/me/';
  static String get _topUpEndpoint => '${ApiEndpoints.baseApi}/pay/up/';
  static String get _topUpIAPEndpoint => '${ApiEndpoints.baseApi}/pay/up/iap/';

  /// Get current user's advertising wallet balance
  /// GET /api/v1/ad-wallet/me/
  Future<PitModel> getMyPit(String token) async {
    try {
      final response = await _dio.get(
        _adWalletEndpoint,
        options: options(token),
      );
      debugPrint(
          '[TOPUP-DEBUG] GET ad-wallet/me status=${response.statusCode} data=${response.data}');
      // API returns { "wallet": {...}, "transactions": [...] }
      final walletData = response.data['wallet'] as Map<String, dynamic>?;
      if (walletData == null) {
        throw const ServerException(message: 'Invalid wallet response: missing wallet field');
      }
      return PitModel.fromJson(walletData);
    } on DioException catch (e) {
      debugPrint(
          '[TOPUP-DEBUG] getMyPit DioException status=${e.response?.statusCode} data=${e.response?.data} type=${e.type}');
      throw ErrorHandler.handle(e);
    }
  }

  /// Initialize top-up: create Pmt only (no provider call)
  /// POST /api/v1/pay/up/
  Future<PitInitResponse> initPit({
    required double amount,
    required String provider, // "finik" or "freedompay"
    String currency = 'KGS',
    required String token,
  }) async {
    try {
      final request = PitInitRequest(
        amount: amount.toStringAsFixed(2),
        provider: provider,
        currency: currency,
      );

      debugPrint('[TOPUP-DEBUG] POST pay/up request=${request.toJson()}');
      final response = await _dio.post(
        _topUpEndpoint,
        data: request.toJson(),
        options: options(token),
      );
      debugPrint(
          '[TOPUP-DEBUG] POST pay/up status=${response.statusCode} data=${response.data}');

      return PitInitResponse.fromJson(response.data);
    } on DioException catch (e) {
      debugPrint(
          '[TOPUP-DEBUG] initPit DioException status=${e.response?.statusCode} data=${e.response?.data} type=${e.type}');
      throw ErrorHandler.handle(e);
    }
  }

  /// Top up wallet via IAP (In-App Purchase)
  /// POST /api/v1/pay/up/iap/
  Future<IAPPitResponse> pitViaIAP({
    required String receiptData,
    required String productId,
    required String platform,
    required String transactionId,
    required String token,
  }) async {
    try {
      final platformValue = platform == 'ios' ? 'apple' : 'google';

      final requestData = {
        'platform': platformValue,
        'receipt_data': receiptData,
        'product_id': productId,
        'transaction_id': transactionId,
        if (platform == 'android') 'token': receiptData,
      };

      debugPrint(
          'PitRepository: Sending IAP top-up request to $_topUpIAPEndpoint');
      debugPrint('PitRepository: Request data: $requestData');

      final response = await _dio.post(
        _topUpIAPEndpoint,
        data: requestData,
        options: options(token),
      );

      debugPrint('PitRepository: Response status=${response.statusCode}');
      debugPrint('PitRepository: Response data=${response.data}');

      return IAPPitResponse.fromJson(response.data);
    } on DioException catch (e) {
      debugPrint('pitViaIAP DioException: ${e.response?.statusCode}');
      debugPrint('pitViaIAP error data: ${e.response?.data}');
      throw ErrorHandler.handle(e);
    }
  }
}
