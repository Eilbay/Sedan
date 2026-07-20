part of 'product_bloc.dart';

abstract class ProductEvent extends Equatable {}

class ProductWithFilter extends ProductEvent {
  final String? category;
  final String? owner;
  final String? price;
  final String? priceGte;
  final String? priceLte;
  final String? search;
  final String? ordering;
  final int? typeProduct;
  final int? typeOwner;
  final int? countryId;
  final int? regionId;
  final String? currency;
  final int limit;
  final bool forceRefresh;

  /// Server-side media filter for the Photo/Video tabs:
  /// true → only video products, false → only photo products, null → all.
  final bool? isVideo;

  ProductWithFilter({
    this.category,
    this.owner,
    this.price,
    this.ordering,
    this.search,
    this.priceLte,
    this.priceGte,
    int? typeProduct,
    this.typeOwner,
    this.countryId,
    this.regionId,
    this.currency,
    this.limit = 20,
    this.forceRefresh = false,
    this.isVideo,
  }) : typeProduct = typeProduct ?? 2;

  @override
  List<Object?> get props => [
        category,
        owner,
        price,
        ordering,
        search,
        priceGte,
        priceLte,
        typeProduct,
        typeOwner,
        countryId,
        regionId,
        currency,
        limit,
        forceRefresh,
        isVideo,
      ];
}

class FetchAllProductsEvent extends ProductEvent {
  FetchAllProductsEvent();

  @override
  List<Object?> get props => [];
}

class ProductClearEvent extends ProductEvent {
  @override
  List<Object?> get props => [];
}

class ProductCreateEvent extends ProductEvent {
  final Product results;
  final List<MediaFile> mediaFiles;
  final EnumRequestType requestType;

  ProductCreateEvent(
      {required this.results,
      required this.mediaFiles,
      required this.requestType});

  @override
  List<Object?> get props => [results];
}

class ProductPutEvent extends ProductEvent {
  final Product product;

  ProductPutEvent({
    required this.product,
  });

  @override
  List<Object?> get props => [product];
}

class ProductDeleteEvent extends ProductEvent {
  final String productId;

  ProductDeleteEvent(this.productId);

  @override
  List<Object?> get props => [productId];
}

class ProductImageDelete extends ProductEvent {
  final int id;

  ProductImageDelete(this.id);

  @override
  List<Object?> get props => [id];
}

class ProductPageEvent extends ProductEvent {
  @override
  List<Object?> get props => [];
}

class ProductGoToPageEvent extends ProductEvent {
  final int page;
  final int limit;

  final String? category;
  final String? owner;
  final String? price;
  final String? priceGte;
  final String? priceLte;
  final String? search;
  final String? ordering;
  final int? typeProduct;
  final int? typeOwner;
  final int? countryId;
  final int? regionId;
  final String? currency;
  final bool? isVideo;

  ProductGoToPageEvent(
      {required this.page,
      this.limit = 20,
      this.category,
      this.owner,
      this.price,
      this.ordering,
      this.search,
      this.priceLte,
      this.priceGte,
      this.typeProduct,
      this.typeOwner = 0,
      this.countryId,
      this.regionId,
      this.currency,
      this.isVideo});

  @override
  List<Object?> get props => [
        page,
        limit,
        search,
        priceGte,
        priceLte,
        ordering,
        typeProduct,
        typeOwner,
        category,
        countryId,
        regionId,
        isVideo,
      ];
}

class SameProductEvent extends ProductEvent {
  final String? childId;
  final int? typeProduct;

  SameProductEvent(this.childId, this.typeProduct);

  @override
  List<Object?> get props => [childId];
}

class GetProductInfo extends ProductEvent {
  final String? id;

  GetProductInfo(this.id);

  @override
  List<Object?> get props => [id];
}

class RefreshSingleProduct extends ProductEvent {
  final String productId;
  final bool preserveLocalPromotion;

  RefreshSingleProduct(
    this.productId, {
    this.preserveLocalPromotion = false,
  });

  @override
  List<Object?> get props => [productId, preserveLocalPromotion];
}

class MarkProductPromotedLocally extends ProductEvent {
  final String productId;

  MarkProductPromotedLocally(this.productId);

  @override
  List<Object?> get props => [productId];
}

class GetProfileProductsEvent extends ProductEvent {
  final String userName;
  final bool forceRefresh;

  GetProfileProductsEvent(
    this.userName, {
    this.forceRefresh = false,
  });

  @override
  List<Object?> get props => [userName, forceRefresh];
}

/// Append the next page of products for [userName] onto the existing
/// `state.profileProducts`. Triggered by the scroll listener in
/// `ProfileScreen` when the user nears the bottom of the grid.
class FetchMoreProfileProductsEvent extends ProductEvent {
  final String userName;

  FetchMoreProfileProductsEvent(this.userName);

  @override
  List<Object?> get props => [userName];
}

class GetPostImage extends ProductEvent {
  final String postId;

  GetPostImage(
    this.postId,
  );

  @override
  List<Object?> get props => [postId];
}

class ClearProductsEvent extends ProductEvent {
  @override
  List<Object?> get props => [];
}

class RegisterPostViewEvent extends ProductEvent {
  final String postId;
  RegisterPostViewEvent(this.postId);

  @override
  List<Object?> get props => [postId];
}

class FetchPostsStatsEvent extends ProductEvent {
  @override
  List<Object?> get props => [];
}

class PreloadHomeEvent extends ProductEvent {
  final int pageSize;
  PreloadHomeEvent({this.pageSize = 20});

  @override
  List<Object?> get props => [pageSize];
}

class InvalidateProfileCacheEvent extends ProductEvent {
  @override
  List<Object?> get props => [];
}

/// Re-runs the most recent ProductWithFilter (if any) with forceRefresh=true.
/// Used after a new post is created so the home feed picks it up.
class RefreshCurrentFilterEvent extends ProductEvent {
  @override
  List<Object?> get props => [];
}

/// Optimistically inserts a product at the top of the current feed, so the
/// user sees their own post immediately without waiting for the network
/// round-trip. A subsequent RefreshCurrentFilterEvent will replace it with
/// the server version.
class OptimisticAddProductEvent extends ProductEvent {
  final Product product;
  OptimisticAddProductEvent(this.product);
  @override
  List<Object?> get props => [product];
}

/// Removes an optimistically-inserted product from the feed. Used when the
/// media upload fails — the post still exists on the server (createPost
/// succeeded) but has no media, so we stop showing a stale card with a
/// local thumbnail that will never resolve to real cover.
class OptimisticRemoveProductEvent extends ProductEvent {
  final String productId;
  OptimisticRemoveProductEvent(this.productId);
  @override
  List<Object?> get props => [productId];
}
