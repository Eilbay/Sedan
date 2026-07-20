import 'package:dio/dio.dart';
import 'package:optombai/core/error/app_exception.dart';
import 'package:optombai/data/api_client.dart';
import 'package:optombai/data/domain_set.dart';
import 'package:optombai/data/models/subscription/subscription_plan_model.dart';
import 'package:optombai/data/repositories/i_subscription_repository.dart';

class SubscriptionRepository implements ISubscriptionRepository {
  final Dio _dio = ApiClient.I.dio;

  Future<List<SubscriptionPlan>> fetchPlans({required String token}) async {
    try {
      final response = await _dio.get(
        '${ApiEndpoints.accountsApi}/premium_settings/',
        options: token.isNotEmpty ? options(token) : null,
      );

      final data = response.data;

      if (data is List) {
        return data.map((json) => SubscriptionPlan.fromJson(json as Map<String, dynamic>)).toList();
      } else if (data is Map<String, dynamic>) {
        return [SubscriptionPlan.fromJson(data)];
      }

      return [];
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }
}
