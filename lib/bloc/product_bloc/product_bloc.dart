import 'dart:math';
import 'package:optombai/configs/constrants.dart';
import 'package:optombai/core/error/app_exception.dart';
import 'package:optombai/core/import_links.dart';
import 'package:optombai/data/models/media_file.dart';
import 'package:equatable/equatable.dart';
import 'package:optombai/data/models/posts/posts_stats_by_owner.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:optombai/core/enums/request_type.dart';
import 'package:optombai/data/repositories/i_product_repository.dart';
import 'package:async/async.dart';

part 'product_event.dart';

part 'product_state.dart';

class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final IProductRepository _repository;
  final SharedPreferences preferences;

  ProductBloc(
      {required IProductRepository repository, required this.preferences})
      : _repository = repository,
        super(ProductState(product: Product())) {
    on<ProductWithFilter>(_getAProductsWithFilter);
    on<ProductCreateEvent>(onProductCreate);
    on<ProductDeleteEvent>(onProductDelete);
    on<SameProductEvent>(_onGetSameProduct);
    on<FetchAllProductsEvent>(getAllPageProducts);
    on<RefreshCurrentFilterEvent>(_onRefreshCurrentFilter);
    on<OptimisticAddProductEvent>(_onOptimisticAdd);
    on<OptimisticRemoveProductEvent>(_onOptimisticRemove);
    on<ProductPageEvent>(_getNextPage);
    on<ProductImageDelete>(onProductImageDelete);
    on<GetProfileProductsEvent>(_onGetProfileProduct);
    on<FetchMoreProfileProductsEvent>(_onFetchMoreProfileProducts);
    on<RegisterPostViewEvent>(_onRegisterPostView);
    on<FetchPostsStatsEvent>(_onFetchPostsStats);
    on<PreloadHomeEvent>(_onPreloadHome);
    on<InvalidateProfileCacheEvent>((event, emit) {
      _lastProfileUsername = null;
    });

    // Wipe all cached products and pagination cursors on account switch
    // so the next viewer doesn't briefly see the previous account's feed
    // / profile / postModel before its own fetch lands.
    on<ClearProductsEvent>((event, emit) {
      _lastKey = null;
      _lastFilter = null;
      _lastProfileUsername = null;
      _currentOperation?.cancel();
      _currentOperation = null;
      emit(ProductState(product: Product()));
    });

    on<RefreshSingleProduct>((event, emit) async {
      try {
        final fresh = await _repository.getProductInfo(event.productId);

        // Defensive merge against the backend "orphan media" bug
        // (server-side issue #13): GET /posts/{id}/ sometimes returns
        // `images_post: []` for posts that DID have media — likely a
        // TTL cleanup of unprocessed uploads. Without this guard a
        // simple refresh after editing the post would replace a valid
        // cover with the empty-image placeholder and the user would
        // wonder why their video disappeared. If the fresh payload
        // lost media we previously had, keep the existing image_post.
        Product mergeIfRegressing(Product existing) {
          if (existing.id != fresh.id) return existing;
          final clone = Product.clone(fresh);
          if (clone.image_post.isEmpty && existing.image_post.isNotEmpty) {
            clone.image_post = existing.image_post;
          }
          if (event.preserveLocalPromotion &&
              existing.isPromoted &&
              !clone.isPromoted) {
            clone.isPromoted = true;
            clone.promoEndAt = existing.promoEndAt;
            clone.promoCampaignId = existing.promoCampaignId;
          }
          return clone;
        }

        final freshDetail = (state.product.id == fresh.id)
            ? mergeIfRegressing(state.product)
            : state.product;

        emit(state.copyWith(
          isLoading: false,
          product: freshDetail,
          profileProducts:
              state.profileProducts.map(mergeIfRegressing).toList(),
          products: state.products.map(mergeIfRegressing).toList(),
          isSuccess: true,
        ));
      } on AppException catch (e) {
        e.messages;
        emit(state.copyWith(isLoading: false));
      }
    });

    on<MarkProductPromotedLocally>((event, emit) {
      Product patchOne(Product product) {
        if (product.id != event.productId) return product;
        return product.copyWith(
          isPromoted: true,
          promoEndAt:
              product.promoEndAt ?? DateTime.now().add(const Duration(days: 1)),
        );
      }

      List<Product> patchList(List<Product> products) {
        return products.map(patchOne).toList();
      }

      final pm = state.postModel;

      emit(state.copyWith(
        product: patchOne(state.product),
        profileProducts: patchList(state.profileProducts),
        products: patchList(state.products),
        sameProduct: patchList(state.sameProduct),
        postModel: pm?.copyWith(results: patchList(pm.results)),
      ));
    });

    on<GetProductInfo>(_onGetProductInfo);
    on<ProductGoToPageEvent>((event, emit) async {
      try {
        emit(state.copyWith(
          isLoading: true,
          errors: const [],
          isSuccess: false,
        ));

        final pm = await _repository.fetchProductsByFilter(
          search: event.search,
          priceGte: event.priceGte,
          priceLte: event.priceLte,
          ordering: event.ordering,
          typeProduct: event.typeProduct,
          typeOwner: event.typeOwner,
          category: event.category,
          countryId: event.countryId,
          regionId: event.regionId,
          limit: event.limit,
          page: event.page,
          token: getToken(),
          isVideo: event.isVideo,
        );

        final pageSize = event.limit > 0 ? event.limit : 20;
        final totalPages = _computeTotalPages(pm, pageSize, event.page);

        emit(state.copyWith(
          isLoading: false,
          isSuccess: true,
          products: pm.results,
          postModel: pm,
          currentPage: event.page,
          totalPages: totalPages,
          totalQuantity: pm.count,
        ));
      } on AppException catch (e) {
        e.messages;
        emit(state.copyWith(isLoading: false));
      } catch (e) {
        emit(state.copyWith(isLoading: false));
      }
    });

    on<ProductClearEvent>((event, emit) {
      emit(ProductState.initial());
    });
  }

  String getToken() => preferences.getString(TOKEN_KEY) ?? "";

  /// Computes total pages from API response count.
  static int _computeTotalPages(
    PostModel pm,
    int pageSize,
    int currentPage,
  ) {
    if (pm.count > 0 && pageSize > 0) {
      return (pm.count / pageSize).ceil();
    }
    // No count available — estimate from next/previous
    if (pm.next != null) return currentPage + 1;
    return max(currentPage, 1);
  }

  _getNextPage(ProductPageEvent event, emit) async {
    // Re-entry guard: infinite-scroll fires this repeatedly while the user
    // is near the bottom; only one in-flight request at a time.
    if (state.isLoadingPaginate) return;

    try {
      var page = state.postModel;
      if (page?.next != null) {
        emit(state.copyWith(isLoadingPaginate: true));
        var postModel = await _repository.fetchAllProduct(
            nextUrl: page?.next, token: getToken());

        emit(state.addNextPage(postModel.results, postModel));
      }
    } on AppException catch (e) {
      e.messages;
      emit(state.copyWith(isLoadingPaginate: false));
    } catch (_) {
      // A non-AppException must not leave the flag stuck — that would
      // permanently block further load-more requests.
      emit(state.copyWith(isLoadingPaginate: false));
    }
  }

  onProductDelete(ProductDeleteEvent event, emit) async {
    emit(state.copyWith(loading: true));
    try {
      await _repository.deleteProduct(event.productId, getToken());

      final updatedProfile = List<Product>.from(state.profileProducts)
        ..removeWhere((p) => p.id == event.productId);

      final updatedProducts = List<Product>.from(state.products)
        ..removeWhere((p) => p.id == event.productId);

      emit(state.copyWith(
        loading: false,
        isSuccess: true,
        profileProducts: updatedProfile,
        products: updatedProducts,
        totalQuantity: state.totalQuantity > 0 ? state.totalQuantity - 1 : 0,
        profileProductsTotalCount: state.profileProductsTotalCount > 0
            ? state.profileProductsTotalCount - 1
            : 0,
      ));
    } on AppException catch (e) {
      emit(state.copyWith(loading: false, errors: e.messages));
    }
  }

  onProductImageDelete(ProductImageDelete event, emit) async {
    emit(state.copyWith(loading: true));
    try {
      await _repository.deleteImage(event.id, getToken());

      Product removeFrom(Product p) {
        final copy = Product.clone(p);
        copy.image_post = List.from(p.image_post)
          ..removeWhere((img) => img.id == event.id);
        return copy;
      }

      final updatedProfile = state.profileProducts
          .map((p) =>
              p.image_post.any((img) => img.id == event.id) ? removeFrom(p) : p)
          .toList();

      final updatedProducts = state.products
          .map((p) =>
              p.image_post.any((img) => img.id == event.id) ? removeFrom(p) : p)
          .toList();

      emit(state.copyWith(
        loading: false,
        isSuccess: true,
        profileProducts: updatedProfile,
        products: updatedProducts,
      ));
    } on AppException catch (e) {
      e.messages;
      emit(state.copyWith(loading: false));
    }
  }

  CancelableOperation? _currentOperation;

  String? _lastKey;
  String? _lastProfileUsername;
  ProductWithFilter? _lastFilter;

  String _makeKey(ProductWithFilter e) => [
        e.category,
        e.owner,
        e.price,
        e.priceGte,
        e.priceLte,
        e.search,
        e.ordering,
        e.typeProduct,
        e.typeOwner,
        e.countryId,
        e.regionId,
        e.currency,
        e.limit,
        e.isVideo,
      ].join('|');

  Future<void> _getAProductsWithFilter(
      ProductWithFilter event, Emitter emit) async {
    final key = _makeKey(event);
    final sw = Stopwatch()..start();

    if (state.isLoading && _lastKey == key) {
      debugPrint(
          '[PRELOAD] ProductWithFilter SKIP (already loading, same key)');
      return;
    }

    if (!event.forceRefresh &&
        !state.isLoading &&
        state.isSuccess &&
        _lastKey == key &&
        state.products.isNotEmpty) {
      debugPrint(
          '[PRELOAD] ProductWithFilter SKIP (cached, ${state.products.length} products)');
      return;
    }

    debugPrint('[PRELOAD] ProductWithFilter FETCHING key=$key');
    _lastKey = key;
    _lastFilter = event;

    _currentOperation?.cancel();
    emit(state.copyWith(
      isLoading: true,
      errors: const [],
      isSuccess: false,
      currentPage: 1,
      products: const [],
      totalPages: 1,
      totalQuantity: 0,
    ));

    _currentOperation = CancelableOperation.fromFuture(
      _repository.fetchProductsByFilter(
        category: event.category,
        owner: event.owner,
        ordering: event.ordering,
        price: event.price,
        priceGte: event.priceGte,
        priceLte: event.priceLte,
        search: event.search,
        typeProduct: event.typeProduct,
        typeOwner: event.typeOwner,
        countryId: event.countryId,
        regionId: event.regionId,
        currency: event.currency,
        limit: event.limit,
        offset: 0,
        forceRefresh: event.forceRefresh,
        token: getToken(),
        isVideo: event.isVideo,
      ),
    );

    try {
      final pm = await _currentOperation!.value;
      final pageSize = event.limit > 0 ? event.limit : 20;
      final totalPages = _computeTotalPages(pm, pageSize, 1);
      debugPrint(
          '[PRELOAD] ProductWithFilter DONE ${sw.elapsedMilliseconds}ms — ${pm.results.length} products');
      debugPrint(
          '[FEED] fetched ids=[${pm.results.map((p) => p.id).join(",")}]');
      emit(state.copyWith(
        isLoading: false,
        isSuccess: true,
        products: pm.results,
        postModel: pm,
        currentPage: 1,
        totalPages: totalPages,
        totalQuantity: pm.count,
      ));
    } on AppException catch (e) {
      debugPrint(
          '[PRELOAD] ProductWithFilter ERROR ${sw.elapsedMilliseconds}ms — ${e.messages}');
      e.messages;
      emit(state.copyWith(isLoading: false));
    }
  }

  getAllPageProducts(FetchAllProductsEvent event, emit) async {
    debugPrint('[PRELOAD] FetchAllProductsEvent FETCHING (WHO CALLED THIS?)');
    debugPrint(StackTrace.current.toString());
    emit(state.copyWith(isLoading: true));
    try {
      var postModel =
          await _repository.fetchProductsByFilter(token: getToken());
      emit(state.copyWith(
          isLoading: false,
          isSuccess: true,
          products: postModel.results,
          postModel: postModel));
    } on AppException catch (e) {
      e.messages;
      emit(state.copyWith(isLoading: false));
    }
  }

  onProductCreate(ProductCreateEvent event, emit) async {
    emit(state.copyWith(
      isLoading: true,
      isSuccessCreate: false,
      errors: const [],
    ));
    try {
      await _repository.createProduct(
        getToken(),
        event.results,
        event.mediaFiles,
        event.requestType,
      );

      if (event.requestType == EnumRequestType.patch &&
          event.results.id.isNotEmpty) {
        final edited = event.results;
        debugPrint('[EDIT] PATCH ok, applying optimistic update for '
            'id=${edited.id} name="${edited.name}" price=${edited.price}');

        Product applyEdits(Product existing) {
          if (existing.id != edited.id) return existing;
          return existing.copyWith(
            name: edited.name,
            description: edited.description,
            price: edited.price,
            currency: edited.currency,
            category: edited.category,
            postType: edited.postType,
            regionId: edited.regionId,
            image_post: edited.image_post.isNotEmpty ? edited.image_post : null,
          );
        }

        final base = state.product.id == edited.id ? state.product : edited;
        final optimisticDetail = applyEdits(
          base.id == edited.id ? base : edited,
        );

        emit(state.copyWith(
          product: optimisticDetail,
          products: state.products.map(applyEdits).toList(),
          profileProducts: state.profileProducts.map(applyEdits).toList(),
          sameProduct: state.sameProduct.map(applyEdits).toList(),
        ));
      }

      emit(state.copyWith(isSuccessCreate: true, isLoading: false));
    } on AppException catch (e) {
      emit(state
          .copyWith(errors: ["Error product create $e"], isLoading: false));
    }
  }

  _onGetSameProduct(SameProductEvent event, emit) async {
    if (event.childId == null) {
      emit(state.copyWith());
      return;
    }
    final sw = Stopwatch()..start();
    debugPrint('[PRELOAD] SameProduct FETCHING cat=${event.childId}');
    emit(state.copyWith(isLoading: true));
    try {
      var list = await _repository.sameProduct(
          category: event.childId, typeProduct: event.typeProduct);
      debugPrint(
          '[PRELOAD] SameProduct DONE ${sw.elapsedMilliseconds}ms — ${list.length} items');
      emit(
          state.copyWith(isLoading: false, isSuccess: true, sameProduct: list));
    } on AppException catch (e) {
      debugPrint(
          '[PRELOAD] SameProduct ERROR ${sw.elapsedMilliseconds}ms — ${e.messages}');
      emit(state.copyWith(isLoading: false, errors: ["Error request$e"]));
    }
  }

  _onGetProductInfo(GetProductInfo event, emit) async {
    final sw = Stopwatch()..start();
    debugPrint('[PRELOAD] GetProductInfo FETCHING id=${event.id}');
    emit(state.copyWith(isLoading: true));
    try {
      var product = await _repository.getProductInfo(event.id);
      debugPrint('[PRELOAD] GetProductInfo DONE ${sw.elapsedMilliseconds}ms');
      emit(state.copyWith(isLoading: false, isSuccess: true, product: product));
    } on AppException catch (e) {
      debugPrint(
          '[PRELOAD] GetProductInfo ERROR ${sw.elapsedMilliseconds}ms — ${e.messages}');
      emit(state.copyWith(isLoading: false, errors: ["Error request$e"]));
    }
  }

  _onGetProfileProduct(GetProfileProductsEvent event, emit) async {
    if (event.userName.isEmpty) {
      return;
    }

    if (!event.forceRefresh &&
        state.profileProducts.isNotEmpty &&
        _lastProfileUsername == event.userName) {
      return;
    }

    _lastProfileUsername = event.userName;
    emit(state.copyWith(
      isLoading: true,
      // Reset pagination state — this is page 1 of a fresh feed.
      currentProfilePage: 1,
      hasMoreProfileProducts: true,
      isLoadingProfileMore: false,
    ));
    try {
      var list = await _repository.fetchProductsByFilter(
        owner: event.userName,
        page: 1,
        token: getToken(),
      );
      emit(state.copyWith(
        isLoading: false,
        isSuccess: true,
        profileProducts: list.results,
        currentProfilePage: 1,
        hasMoreProfileProducts: list.next != null,
        profileProductsTotalCount: list.count,
      ));
    } on AppException catch (e) {
      emit(state.copyWith(isLoading: false, errors: ["Error request$e"]));
    } catch (e) {
      // Surface non-AppException failures (e.g. response parsing) that would
      // otherwise leave the handler without emitting any state, freezing the
      // grid on its previous (empty) render.
      emit(state.copyWith(isLoading: false, errors: ["Error request$e"]));
    }
  }

  /// Append the next page of profile products onto the existing list.
  /// Guarded against double-fetch via `isLoadingProfileMore` flag and
  /// `hasMoreProfileProducts` (set from API `next` URL on page 1).
  Future<void> _onFetchMoreProfileProducts(
    FetchMoreProfileProductsEvent event,
    Emitter<ProductState> emit,
  ) async {
    if (event.userName.isEmpty) return;
    if (state.isLoadingProfileMore) return;
    if (!state.hasMoreProfileProducts) return;

    final nextPage = state.currentProfilePage + 1;
    emit(state.copyWith(isLoadingProfileMore: true));
    try {
      final list = await _repository.fetchProductsByFilter(
        owner: event.userName,
        page: nextPage,
        token: getToken(),
      );
      final merged = List<Product>.from(state.profileProducts)
        ..addAll(list.results);
      emit(state.copyWith(
        isLoadingProfileMore: false,
        profileProducts: merged,
        currentProfilePage: nextPage,
        hasMoreProfileProducts: list.next != null,
        profileProductsTotalCount: list.count,
      ));
    } on AppException catch (e) {
      e.messages;
      emit(state.copyWith(
        isLoadingProfileMore: false,
        errors: ["Error pagination $e"],
      ));
    }
  }

  Future<void> _onRegisterPostView(
    RegisterPostViewEvent event,
    Emitter<ProductState> emit,
  ) async {
    final token = getToken();
    if (token.isEmpty) return;

    final postId = event.postId;

    try {
      final newViews = await _repository.registerView(
        postId: postId,
        authHeader: token,
      );

      Product patchOne(Product p) {
        if (p.id != postId) return p;
        final copy = Product.clone(p);
        copy.views = newViews;
        return copy;
      }

      List<Product> patchList(List<Product> src) => src.map(patchOne).toList();

      final pm = state.postModel;

      emit(state.copyWith(
        products: patchList(state.products),
        profileProducts: patchList(state.profileProducts),
        sameProduct: patchList(state.sameProduct),
        postModel: pm?.copyWith(results: patchList(pm.results)),
        product: patchOne(state.product),
      ));
    } catch (e, st) {
      debugPrint('registerView failed: $e\n$st');
    }
  }

  Future<void> _onFetchPostsStats(
    FetchPostsStatsEvent event,
    Emitter<ProductState> emit,
  ) async {
    if (state.isStatsLoading) {
      debugPrint('[PRELOAD] PostsStats SKIP (already loading)');
      return;
    }
    if (state.stats != null) {
      debugPrint('[PRELOAD] PostsStats SKIP (cached)');
      return;
    }

    debugPrint('[PRELOAD] PostsStats FETCHING');
    final sw = Stopwatch()..start();
    emit(state.copyWith(isStatsLoading: true));

    try {
      final stats = await _repository.fetchPostsStatsByOwnerType();
      debugPrint('[PRELOAD] PostsStats DONE ${sw.elapsedMilliseconds}ms');
      emit(state.copyWith(isStatsLoading: false, stats: stats));
    } catch (_) {
      debugPrint('[PRELOAD] PostsStats ERROR ${sw.elapsedMilliseconds}ms');
      emit(state.copyWith(isStatsLoading: false));
    }
  }

  Future<void> _onRefreshCurrentFilter(
    RefreshCurrentFilterEvent event,
    Emitter<ProductState> emit,
  ) async {
    final last = _lastFilter;
    if (last == null) {
      // No filter was ever applied — fall back to the generic feed.
      add(FetchAllProductsEvent());
      return;
    }
    // Bypass the cache check by clearing the key and re-dispatching the
    // original filter. forceRefresh=true also prevents the early-return
    // guard inside _getAProductsWithFilter.
    _lastKey = null;
    add(ProductWithFilter(
      category: last.category,
      owner: last.owner,
      price: last.price,
      priceGte: last.priceGte,
      priceLte: last.priceLte,
      search: last.search,
      ordering: last.ordering,
      typeProduct: last.typeProduct,
      typeOwner: last.typeOwner,
      countryId: last.countryId,
      regionId: last.regionId,
      currency: last.currency,
      limit: last.limit,
      forceRefresh: true,
    ));
  }

  void _onOptimisticAdd(
    OptimisticAddProductEvent event,
    Emitter<ProductState> emit,
  ) {
    // Avoid duplicate inserts if the user re-triggers upload for the same id.
    final alreadyPresent = state.products.any((p) => p.id == event.product.id);
    if (alreadyPresent) return;

    final updated = [event.product, ...state.products];
    emit(state.copyWith(
      products: updated,
      totalQuantity: state.totalQuantity + 1,
    ));
  }

  void _onOptimisticRemove(
    OptimisticRemoveProductEvent event,
    Emitter<ProductState> emit,
  ) {
    final id = event.productId;
    final newProducts = state.products.where((p) => p.id != id).toList();
    final newProfile = state.profileProducts.where((p) => p.id != id).toList();
    final newSame = state.sameProduct.where((p) => p.id != id).toList();

    final pm = state.postModel;
    final newPostModel = (pm == null || pm.results.every((p) => p.id != id))
        ? pm
        : pm.copyWith(
            results: pm.results.where((p) => p.id != id).toList(),
          );

    final anyChanged = newProducts.length != state.products.length ||
        newProfile.length != state.profileProducts.length ||
        newSame.length != state.sameProduct.length ||
        newPostModel != pm;
    debugPrint('[REPORT/REMOVE] id=$id changed=$anyChanged | products '
        '${state.products.length}->${newProducts.length} profile '
        '${state.profileProducts.length}->${newProfile.length} same '
        '${state.sameProduct.length}->${newSame.length}');
    if (!anyChanged) return;

    final removedFromMainFeed = newProducts.length != state.products.length;
    final removedFromProfile = newProfile.length != state.profileProducts.length;
    emit(state.copyWith(
      products: newProducts,
      profileProducts: newProfile,
      sameProduct: newSame,
      postModel: newPostModel,
      totalQuantity: removedFromMainFeed && state.totalQuantity > 0
          ? state.totalQuantity - 1
          : state.totalQuantity,
      profileProductsTotalCount: removedFromProfile &&
              state.profileProductsTotalCount > 0
          ? state.profileProductsTotalCount - 1
          : state.profileProductsTotalCount,
    ));
  }

  Future<void> _onPreloadHome(
    PreloadHomeEvent event,
    Emitter<ProductState> emit,
  ) async {
    if (state.products.isNotEmpty && state.stats != null) return;

    emit(state
        .copyWith(isLoading: true, isStatsLoading: true, errors: const []));

    try {
      final results = await Future.wait([
        _repository.fetchProductsByFilter(
          typeProduct: 2,
          typeOwner: 4,
          page: 1,
          pageSize: event.pageSize,
          token: getToken(),
        ),
        _repository.fetchPostsStatsByOwnerType(),
      ]);

      final pm = results[0] as PostModel;
      final stats = results[1] as PostsStatsByOwnerType;
      final pageSize = event.pageSize > 0 ? event.pageSize : 20;
      final totalPages = _computeTotalPages(pm, pageSize, 1);

      emit(state.copyWith(
        isLoading: false,
        isStatsLoading: false,
        isSuccess: true,
        products: pm.results,
        postModel: pm,
        currentPage: 1,
        totalPages: totalPages,
        totalQuantity: pm.count,
        stats: stats,
      ));
    } catch (e) {
      emit(state.copyWith(isLoading: false, isStatsLoading: false));
    }
  }
}
