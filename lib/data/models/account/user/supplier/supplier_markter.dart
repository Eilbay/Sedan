class SupplierMarketLink {
  final int id;
  final int marketId;
  final String marketName;
  final bool isActive;

  SupplierMarketLink({
    required this.id,
    required this.marketId,
    required this.marketName,
    required this.isActive,
  });

  factory SupplierMarketLink.fromJson(Map<String, dynamic> json) {
    final market = (json['market'] as Map<String, dynamic>?) ?? const {};
    return SupplierMarketLink(
      id: (json['id'] as num?)?.toInt() ?? 0,
      marketId: (market['id'] as num?)?.toInt() ?? 0,
      marketName: (market['name'] ?? '').toString(),
      isActive: (json['is_active'] as bool?) ?? false,
    );
  }
}
