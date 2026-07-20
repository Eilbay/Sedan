/// Identifiers passed to `POST /api/v1/target/impressions/` to scope the
/// frequency cap (3 impressions / user / placement / 24h) per surface.
enum PromotionPlacement {
  main('main'),
  search('search'),
  categoryTop('category_top'),
  videoFeed('video_feed');

  const PromotionPlacement(this.apiValue);

  final String apiValue;
}
