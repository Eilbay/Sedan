import 'package:optombai/data/models/subscription/subscription_plan_model.dart';

abstract interface class ISubscriptionRepository {
  Future<List<SubscriptionPlan>> fetchPlans({required String token});
}
