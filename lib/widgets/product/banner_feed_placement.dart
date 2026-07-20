import 'package:optombai/data/models/banner/settings_banners_model.dart';

/// Index math for interleaving ad banners into a product feed:
/// after every [productsPerBanner] products one banner slot is inserted,
/// and banners rotate round-robin (admin-defined order) across slots.
///
/// Pure and stateless so list/grid delegates can map their child index
/// to either a product or a banner without duplicating the arithmetic.
class BannerFeedPlacement {
  BannerFeedPlacement({
    required this.productCount,
    required List<BannerModel> banners,
    this.productsPerBanner = 10,
  }) : banners = banners
            .where((b) => b.mobile.isNotEmpty || (b.image ?? '').isNotEmpty)
            .toList();

  final int productCount;
  final List<BannerModel> banners;
  final int productsPerBanner;

  bool get _hasBanners => banners.isNotEmpty;

  int get _bannerSlotCount =>
      _hasBanners ? productCount ~/ productsPerBanner : 0;

  /// Total children the sliver delegate should build (products + banners).
  int get totalItemCount => productCount + _bannerSlotCount;

  /// A banner sits right after each full group of [productsPerBanner]
  /// products, i.e. at combined indexes 10, 21, 32... for a step of 10.
  bool isBannerIndex(int index) {
    if (!_hasBanners) return false;
    return (index + 1) % (productsPerBanner + 1) == 0;
  }

  /// Combined index -> index in the products list. Only valid when
  /// [isBannerIndex] is false.
  int productIndexAt(int index) {
    if (!_hasBanners) return index;
    return index - index ~/ (productsPerBanner + 1);
  }

  /// Banner for the given combined index, rotating through the list in
  /// admin order. Only valid when [isBannerIndex] is true.
  BannerModel bannerAt(int index) =>
      bannerForSlot((index + 1) ~/ (productsPerBanner + 1) - 1);

  /// Banner for the N-th banner slot (0-based), cycling round-robin.
  BannerModel bannerForSlot(int slot) => banners[slot % banners.length];
}
