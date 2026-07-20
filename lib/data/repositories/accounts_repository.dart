import 'package:dio/dio.dart';
import 'package:optombai/core/error/app_exception.dart';
import 'package:optombai/data/api_client.dart';
import 'package:optombai/data/domain_set.dart';

class AccountsRepository {
  final Dio _dio = ApiClient.I.dio;

  Future<int> fetchUsersCount({
    required int userType,
  }) async {
    try {
      final res = await _dio.get(
        "${ApiEndpoints.accountsApi}/users/",
        queryParameters: {"user_type": userType, "limit": 1, "offset": 0},
      );

      return (res.data["count"] as num?)?.toInt() ?? 0;
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<int> fetchCustomerCount() async {
    try {
      final res = await _dio.get(
        "${ApiEndpoints.accountsApi}/users/customers/",
        queryParameters: {"limit": 1, "offset": 0},
      );

      return (res.data["count"] as num?)?.toInt() ?? 0;
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }
}
