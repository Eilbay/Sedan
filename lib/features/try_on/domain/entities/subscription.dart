enum SubscriptionType { standard, business, aiOnly, businessAi }

SubscriptionType parseSub(String s) {
  switch (s.toLowerCase()) {
    case 'примерка ии':
    case 'ai_try_on':
    case 'ai':
      return SubscriptionType.aiOnly;
    case 'бизнес + примерка ии':
    case 'business_ai':
      return SubscriptionType.businessAi;
    case 'бизнес':
    case 'business':
      return SubscriptionType.business;
    default:
      return SubscriptionType.standard;
  }
}

class SubscriptionInfo {
  final SubscriptionType type;
  final int? generationsLeft;
  SubscriptionInfo({required this.type, this.generationsLeft});
}
