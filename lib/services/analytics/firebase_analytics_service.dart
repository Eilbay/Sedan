import 'package:flutter/foundation.dart';
import 'package:optombai/services/analytics/i_analytics_service.dart';

class FirebaseAnalyticsService implements IAnalyticsService {
  FirebaseAnalyticsService();

  @override
  Future<void> logScreenView({required String screenName}) async {
    debugPrint('[Analytics] mock screen: $screenName');
  }

  @override
  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    debugPrint('[Analytics] mock event: $name');
  }

  @override
  Future<void> setUserId(String? userId) async {
    debugPrint('[Analytics] mock user: $userId');
  }
}
