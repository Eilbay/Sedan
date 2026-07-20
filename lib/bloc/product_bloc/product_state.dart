part of 'product_bloc.dart';

class ProductState extends Equatable {
  final bool isLoading;
  final bool isLoadingPaginate;
  final bool loading;
  final List<String> errors;
  final bool isSuccess;
  final bool isSuccessCreate;
  final PostModel? postModel;
  final List<Product> products;
  final List<Product> sameProduct;
  final List<Product> profileProducts;
  final Product product;
  final int totalQuantity;
  final int currentPage;
  final int totalPages;

  final PostsStatsByOwnerType? stats;
  final bool isStatsLoading;

  // Profile products pagination
  final int currentProfilePage;
  final bool hasMoreProfileProducts;
  final bool isLoadingProfileMore;

  /// Total number of products owned by the profile user, from
  /// `count` field of paginated /posts/?owner=... response. Different
  /// from `profileProducts.length` which is only the loaded subset.
  final int profileProductsTotalCount;

  const ProductState(
      {required this.product,
      this.postModel = const PostModel(),
      this.products = const [],
      this.loading = false,
      this.sameProduct = const [],
      this.profileProducts = const [],
      this.isLoading = false,
      this.isLoadingPaginate = false,
      this.currentPage = 1,
      this.totalPages = 1,
      this.errors = const [],
      this.isSuccess = false,
      this.isSuccessCreate = false,
      this.stats,
      this.isStatsLoading = false,
      this.currentProfilePage = 1,
      this.hasMoreProfileProducts = true,
      this.isLoadingProfileMore = false,
      this.profileProductsTotalCount = 0,
      this.totalQuantity = 0});

  ProductState copyWith({
    bool? isLoading,
    bool? isLoadingPaginate,
    bool? loading,
    List<String>? errors,
    bool? isSuccess,
    bool? isSuccessCreate,
    PostModel? postModel,
    List<Product>? products,
    List<Product>? sameProduct,
    List<Product>? profileProducts,
    Product? product,
    int? totalQuantity,
    int? currentPage,
    int? totalPages,
    PostsStatsByOwnerType? stats,
    bool? isStatsLoading,
    int? currentProfilePage,
    bool? hasMoreProfileProducts,
    bool? isLoadingProfileMore,
    int? profileProductsTotalCount,
  }) {
    return ProductState(
      isLoading: isLoading ?? this.isLoading,
      isLoadingPaginate: isLoadingPaginate ?? this.isLoadingPaginate,
      loading: loading ?? this.loading,
      errors: errors ?? this.errors,
      isSuccess: isSuccess ?? this.isSuccess,
      isSuccessCreate: isSuccessCreate ?? this.isSuccessCreate,
      postModel: postModel ?? this.postModel,
      products: products ?? this.products,
      sameProduct: sameProduct ?? this.sameProduct,
      profileProducts: profileProducts ?? this.profileProducts,
      product: product ?? this.product,
      totalQuantity: totalQuantity ?? this.totalQuantity,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      stats: stats ?? this.stats,
      isStatsLoading: isStatsLoading ?? this.isStatsLoading,
      currentProfilePage: currentProfilePage ?? this.currentProfilePage,
      hasMoreProfileProducts:
          hasMoreProfileProducts ?? this.hasMoreProfileProducts,
      isLoadingProfileMore: isLoadingProfileMore ?? this.isLoadingProfileMore,
      profileProductsTotalCount:
          profileProductsTotalCount ?? this.profileProductsTotalCount,
    );
  }

  ProductState addNextPage(List<Product> results, PostModel postModel) {
    // Dedup by id: a shifting feed (new posts landing between requests)
    // can repeat items across page boundaries.
    final seenIds = products.map((p) => p.id).toSet();
    final fresh = results.where((p) => seenIds.add(p.id));
    final nextProducts = List<Product>.from(products)..addAll(fresh);
    return copyWith(
      products: nextProducts,
      postModel: postModel,
      // The load-more request this page came from is finished.
      isLoadingPaginate: false,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        isLoadingPaginate,
        loading,
        errors,
        isSuccess,
        isSuccessCreate,
        postModel,
        products,
        sameProduct,
        profileProducts,
        product,
        totalQuantity,
        currentPage,
        totalPages,
        stats,
        isStatsLoading,
        currentProfilePage,
        hasMoreProfileProducts,
        isLoadingProfileMore,
        profileProductsTotalCount,
      ];

  factory ProductState.initial() {
    return ProductState(
      product: Product(),
      postModel: const PostModel(),
      products: const [],
      sameProduct: const [],
      profileProducts: const [],
      isLoading: false,
      isLoadingPaginate: false,
      loading: false,
      errors: const [],
      isSuccess: false,
      totalQuantity: 0,
    );
  }
}
