import 'package:optombai/services/analytics/i_analytics_service.dart';

class NoopAnalyticsService implements IAnalyticsService {
  @override
  Future<void> logScreenView({required String screenName}) async {}

  @override
  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {}

  @override
  Future<void> setUserId(String? userId) async {}
}
