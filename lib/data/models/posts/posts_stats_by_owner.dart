class PostsStatsByOwnerType {
  final int totalPosts;

  final int providers;
  final int manufacturers;
  final int customers;

  final int demand;
  final int product;

  const PostsStatsByOwnerType({
    required this.totalPosts,
    required this.providers,
    required this.manufacturers,
    required this.customers,
    required this.demand,
    required this.product,
  });

  factory PostsStatsByOwnerType.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    return PostsStatsByOwnerType(
      totalPosts: asInt(json['total_posts']),
      providers: asInt(json['providers']),
      manufacturers: asInt(json['manufacturers']),
      customers: asInt(json['customers']),
      demand: asInt(json['demand']),
      product: asInt(json['product']),
    );
  }
}
