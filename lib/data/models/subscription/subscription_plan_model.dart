class SubscriptionPlan {
  final int id;
  final String title;
  final String description;
  final double price;
  final int durationDays;
  final bool tryonEnabled;
  final bool canViewOrders;
  final int tryonMonthlyQuota;
  final int visitLimitManufacturer;
  final bool isFree;

  SubscriptionPlan({
    required this.id,
    required this.title,
    this.description = '',
    required this.price,
    this.durationDays = 30,
    this.tryonEnabled = false,
    this.canViewOrders = false,
    this.tryonMonthlyQuota = 0,
    this.visitLimitManufacturer = 0,
    this.isFree = false,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    final features = json['features'] as Map<String, dynamic>? ?? {};

    return SubscriptionPlan(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description']?.toString() ?? '',
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      durationDays: json['duration_days'] ?? 30,
      tryonEnabled: features['tryon_enabled'] ?? false,
      canViewOrders: features['can_view_orders'] ?? false,
      tryonMonthlyQuota: features['tryon_monthly_quota'] ?? 0,
      visitLimitManufacturer: features['visit_limit_manafacturer'] ?? 0,
      isFree: json['is_free'] ?? false,
    );
  }
}
