class ReachRange {
  final int from;
  final int to;

  const ReachRange({required this.from, required this.to});

  factory ReachRange.fromJson(Map<String, dynamic> json) {
    return ReachRange(
      from: json['from'] as int,
      to: json['to'] as int,
    );
  }

  Map<String, dynamic> toJson() => {'from': from, 'to': to};
}

class PromotionPackageModel {
  final int id;
  final String name;
  final String? description;
  final int days;
  final double priceTotal;
  final String currency;
  final double priorityWeight;
  final int dailyImpressions;
  final int reachMin;
  final int reachMax;
  final List<String> placements;
  final bool isActive;

  const PromotionPackageModel({
    required this.id,
    required this.name,
    this.description,
    required this.days,
    required this.priceTotal,
    required this.currency,
    required this.priorityWeight,
    required this.dailyImpressions,
    required this.reachMin,
    required this.reachMax,
    required this.placements,
    required this.isActive,
  });

  ReachRange get reach => ReachRange(from: reachMin, to: reachMax);

  factory PromotionPackageModel.fromJson(Map<String, dynamic> json) {
    final rawPrice = json['price_total']?.toString() ?? '0';
    final parsedPrice = double.tryParse(rawPrice) ?? 0.0;
    final rawWeight = json['priority_weight']?.toString() ?? '0';
    final parsedWeight = double.tryParse(rawWeight) ?? 0.0;

    final placementsList = (json['placements'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];

    return PromotionPackageModel(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      days: json['days'] as int,
      priceTotal: parsedPrice,
      currency: json['currency'] as String? ?? 'KGS',
      priorityWeight: parsedWeight,
      dailyImpressions: json['daily_impressions'] as int? ?? 0,
      reachMin: json['reach_min'] as int? ?? 0,
      reachMax: json['reach_max'] as int? ?? 0,
      placements: placementsList,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'days': days,
        'price_total': priceTotal.toString(),
        'currency': currency,
        'priority_weight': priorityWeight.toString(),
        'daily_impressions': dailyImpressions,
        'reach_min': reachMin,
        'reach_max': reachMax,
        'placements': placements,
        'is_active': isActive,
      };
}
