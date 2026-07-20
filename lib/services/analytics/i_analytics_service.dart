/// Analytics sink for key product events (screen views, funnel steps).
///
/// Deliberately narrow: callers log meaningful business events, not every
/// tap — high-frequency instrumentation defeats the purpose of a funnel and
/// adds network chatter for no analytical value.
abstract class IAnalyticsService {
  Future<void> logScreenView({required String screenName});

  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  });

  Future<void> setUserId(String? userId);
}
