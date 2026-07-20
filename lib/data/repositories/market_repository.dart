import 'package:dio/dio.dart';
import 'package:optombai/core/error/app_exception.dart';
import 'package:optombai/data/api_client.dart';
import 'package:optombai/data/domain_set.dart';
import 'package:optombai/data/models/market/market_model.dart';
import 'package:optombai/data/repositories/i_market_repository.dart';

final String endpointMarkets = '${ApiEndpoints.marketApi}/markets/';
final String endpointSupplierRequests = '${ApiEndpoints.marketApi}/supplier_requests/';
final String endpointSupplierRequestsList =
    '${ApiEndpoints.marketApi}/supplier_requests/list/';
final String endpointSupplierDetail = '${ApiEndpoints.marketApi}/suppliers/';

class MarketRepository implements IMarketRepository {
  final Dio _dio = ApiClient.I.dio;

  Future<List<MarketModel>> getMarkets() async {
    try {
      final res = await _dio.get(endpointMarkets);
      return (res.data['results'] as List)
          .map((e) => MarketModel.fromJson(e))
          .toList();
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<List<SupplierRequestModel>> getMySupplierRequests(String token) async {
    try {
      final res =
          await _dio.get(endpointSupplierRequestsList, options: options(token));
      return (res.data['results'] as List)
          .map((e) => SupplierRequestModel.fromJson(e))
          .toList();
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<void> createSupplierRequest(String token, int marketId) async {
    try {
      await _dio.post(
        endpointSupplierRequests,
        data: {'market': marketId},
        options: options(token),
      );
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<Map<String, dynamic>?> getSupplierByUsername(
    String token,
    String username, {
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final res = await _dio.get(
        endpointSupplierDetail,
        queryParameters: {
          'search': username,
          'limit': limit,
          'offset': offset,
        },
        options: options(token),
      );

      final results = (res.data['results'] as List).cast<Map<String, dynamic>>();

      final exact = results.cast<Map<String, dynamic>?>().firstWhere(
            (x) =>
                (x?['user']?['username'] as String?)?.toLowerCase() ==
                username.toLowerCase(),
            orElse: () => null,
          );

      return exact ?? (results.isNotEmpty ? results.first : null);
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }
}
