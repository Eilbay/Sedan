import 'package:optombai/features/try_on/domain/entities/subscription.dart';

abstract class SubscriptionRepository {
  Future<SubscriptionInfo> getSubscription();
}
