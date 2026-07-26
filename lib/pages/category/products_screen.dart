import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:optombai/bloc/banner_bloc/banner_bloc.dart';
import 'package:optombai/bloc/category_bloc/category_bloc.dart';
import 'package:optombai/bloc/market_bloc/supplier_market_bloc.dart';
import 'package:optombai/bloc/market_bloc/supplier_market_event.dart';
import 'package:optombai/bloc/product_bloc/product_bloc.dart';
import 'package:optombai/bloc/user_bloc/user_bloc.dart';
import 'package:optombai/core/di/injection.dart';
import 'package:optombai/data/models/banner/settings_banners_model.dart';
import 'package:optombai/data/repositories/i_product_repository.dart';
import 'package:optombai/widgets/product/banner_feed_placement.dart';
import 'package:optombai/widgets/product/feed_banner_card.dart';
import 'package:optombai/widgets/product/product_feed_card.dart';
import 'package:optombai/widgets/shimmer/shimmer_product_grid.dart';
import 'package:optombai/data/models/posts/post_model.dart';
import 'package:optombai/data/mock/sedan_mock_listings.dart';
import 'package:optombai/pages/main_screen/main_screen.dart';
import 'package:optombai/pages/main_screen/sedan_mock_details_page.dart';
import 'package:optombai/widgets/promotion/maybe_promoted_card.dart';
import 'package:optombai/widgets/promotion/promotion_placement.dart';
import 'package:optombai/pages/main_screen/order_screen.dart';
import 'package:optombai/app/router/app_router.dart';
import 'package:optombai/core/theme_notifier.dart';
import 'package:optombai/core/appColors.dart';
import 'package:optombai/widgets/app_scaffold/custom_scaffold.dart';
import 'package:optombai/widgets/bottom_nav.dart';
import 'package:optombai/widgets/translation/text_translated.dart';
import 'package:optombai/widgets/utils/card/empty_product_card.dart';
import 'package:optombai/widgets/utils/fields/custom_search_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:optombai/widgets/common/rating_stars.dart';
import 'package:optombai/widgets/common/infinite_scroll_region.dart';
import 'package:auto_route/auto_route.dart';
import 'package:optombai/pages/category/product_filter_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

@RoutePage()
class ProductsScreen extends StatelessWidget {
  const ProductsScreen({
    super.key,
    required this.childId,
    required this.title,
    this.mockCategoryKey,
  });

  final String title;
  final String childId;
  final String? mockCategoryKey;

  @override
  Widget build(BuildContext context) {
    final mock = mockCategoryKey != null
        ? sedanMockListingForKey(mockCategoryKey!)
        : sedanMockListingForCategory(title) ?? sedanMockListingForKey(childId);

    if (mock != null) {
      final isDarkMode = context.select((ThemeNotifier n) => n.isDarkMode);
      return _MockListingScaffold(
        title: title,
        listing: mock,
        isDarkMode: isDarkMode,
      );
    }

    // Scoped ProductBloc isolates this screen's feed from the global one the
    // home screen uses. Without this, filtering by category here overwrites
    // the shared bloc's state — going back to the home tab afterwards showed
    // this category's filtered products instead of the home recommendations
    // feed, since both screens read the same global instance. Same root
    // cause and fix as OrdersScreen (see order_screen.dart).
    return BlocProvider<ProductBloc>(
      create: (_) => ProductBloc(
        repository: getIt<IProductRepository>(),
        preferences: getIt<SharedPreferences>(),
      ),
      child: _ProductsView(
        childId: childId,
        title: title,
        mockCategoryKey: mockCategoryKey,
      ),
    );
  }
}

class _ProductsView extends StatefulWidget {
  const _ProductsView({
    required this.childId,
    required this.title,
    this.mockCategoryKey,
  });

  final String title;
  final String childId;
  final String? mockCategoryKey;

  @override
  State<_ProductsView> createState() => _ProductsViewState();
}

class _ProductsViewState extends State<_ProductsView> {
  final ScrollController _controller = ScrollController();
  bool get isStockCategory => widget.title.toLowerCase().contains("склад");
  SedanMockListing? get mockListing {
    final key = widget.mockCategoryKey;
    if (key != null) return sedanMockListingForKey(key);
    return sedanMockListingForCategory(widget.title) ??
        sedanMockListingForKey(widget.childId);
  }

  @override
  void initState() {
    if (mockListing != null) {
      super.initState();
      return;
    }

    BlocProvider.of<ProductBloc>(context)
        .add(ProductWithFilter(category: widget.childId));
    choseMain ??= 2;
    fetchProductWithFilter();

    final userId = context.read<UserBloc>().state.user.id;
    context.read<SupplierMarketBloc>().add(SupplierMarketInit(userId));

    // Reels are fetched lazily when the user opens the videos tab —
    // keeps the products tab snappy and avoids the large reels payload
    // competing with the initial product list request.

    super.initState();
  }

  @override
  void dispose() {
    _debounce.cancel();
    _controller.dispose();
    super.dispose();
  }

  List<SortModel> list = [
    const SortModel("Не указaно", null),
    const SortModel("Сначала дешевле", "price"),
    const SortModel("Сначала дороже", "-price"),
    const SortModel("Сначала новые", "created_at"),
    const SortModel("Выше рейтинг", "-rating"),
  ];

  Timer _debounce = Timer(Duration.zero, () {});

  _onDebounce() {
    if (_debounce.isActive) {
      _debounce.cancel();
    }

    _debounce = Timer(const Duration(milliseconds: 500), () {
      fetchProductWithFilter();
    });
  }

  int indexSort = 0;
  String? priceGte;
  String? priceLte;
  String? search;
  int? choseMain = 4;
  int? choseOwner;
  int? regionId;
  String? filterCategoryId;
  String currency = 'KGS';

  Future<void> _openOtherUserProfile({
    required String userId,
    required String username,
    int? productType,
  }) async {
    final offsetBefore = _controller.offset;

    await context.router.push(OtherUserProfileRoute(
      username: username,
      productType: productType,
      user: userId,
    ));

    if (!mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_controller.hasClients) {
        _controller.jumpTo(offsetBefore);
      }
    });
  }

  void fetchProductWithFilter() {
    final rawOrdering = list[indexSort].value;
    final ordering = (rawOrdering?.trim().isEmpty ?? true) ? null : rawOrdering;

    BlocProvider.of<ProductBloc>(context).add(ProductWithFilter(
      priceGte: (priceGte != null && priceGte!.trim().isNotEmpty)
          ? double.tryParse(priceGte!.replaceAll(',', '.'))?.toString()
          : null,
      priceLte: (priceLte != null && priceLte!.trim().isNotEmpty)
          ? double.tryParse(priceLte!.replaceAll(',', '.'))?.toString()
          : null,
      search: search,
      ordering: ordering,
      typeProduct: null,
      typeOwner: choseOwner,
      category: filterCategoryId ?? widget.childId,
      regionId: regionId,
      currency: currency,
    ));
  }

  Future<void> _openFilterSheet() async {
    final config = ProductFilterConfig(
      search: search,
      filterCategoryId: filterCategoryId,
      regionId: regionId,
      priceGte: priceGte,
      priceLte: priceLte,
      sortIndex: indexSort,
      choseMain: choseMain,
      choseOwner: choseOwner,
      currency: currency,
    );

    final totalCount = context.read<ProductBloc>().state.totalQuantity;
    final categories = context.read<CategoryBloc>().state.categories;
    final markets = context.read<SupplierMarketBloc>().state.markets;

    final result = await ProductFilterSheet.show(
      context,
      config: config,
      categoryTitle: widget.title,
      sortOptions: list,
      categories: categories,
      markets: markets,
      totalCount: totalCount > 0 ? totalCount : null,
    );

    if (!mounted || result == null) return;

    // Picking a different category in the filter replaces this screen with
    // a fresh ProductsScreen for that category instead of just refetching —
    // the category name/title in the app bar must match the new category.
    final pickedCategoryId = result.filterCategoryId;
    if (pickedCategoryId != null && pickedCategoryId != widget.childId) {
      context.router.replace(ProductsRoute(
        childId: pickedCategoryId,
        title: result.filterCategoryTitle ?? widget.title,
      ));
      return;
    }

    setState(() {
      search = result.search;
      regionId = result.regionId;
      priceGte = result.priceGte;
      priceLte = result.priceLte;
      indexSort = result.sortIndex;
      choseMain = result.choseMain;
      choseOwner = result.choseOwner;
      currency = result.currency;
    });
    fetchProductWithFilter();
  }

  Widget _buildProductsTab(BuildContext context) {
    final bool stateSwitch = context.select((ThemeNotifier n) => n.isDarkMode);

    return BlocConsumer<ProductBloc, ProductState>(
      buildWhen: (previous, current) {
        return previous.products != current.products ||
            previous.isLoading != current.isLoading ||
            previous.isLoadingPaginate != current.isLoadingPaginate ||
            previous.currentPage != current.currentPage ||
            previous.totalPages != current.totalPages;
      },
      listener: (context, state) {},
      builder: (context, state) {
        final bool isInitialLoading = state.products.isEmpty && state.isLoading;

        // Ad banners interleave the category feed: one after every 10
        // products (per ТЗ), in every category and subcategory. An empty
        // banner list degrades to the plain feed.
        final bannerState = context.watch<BannerBloc>().state;
        final List<BannerModel> banners = bannerState is BannerSuccess
            ? bannerState.list
            : const <BannerModel>[];

        List<Product> filteredProducts = state.products;
        if (choseOwner != null) {
          final uniqueOwners = <String>{};
          filteredProducts = state.products.where((product) {
            if (product.owner != null &&
                !uniqueOwners.contains(product.owner!.id)) {
              uniqueOwners.add(product.owner!.id);
              return true;
            }
            return false;
          }).toList();
        }

        // Banners belong to the product feed only — the unique-sellers view
        // (owner filter) lists shops, not товары, so it stays banner-free.
        final bool isProductFeed =
            choseOwner == null || choseOwner == 4 || choseOwner == 8;
        final placement = BannerFeedPlacement(
          productCount: filteredProducts.length,
          banners: isProductFeed ? banners : const <BannerModel>[],
        );

        return InfiniteScrollRegion(
          onLoadMore: () => context.read<ProductBloc>().add(ProductPageEvent()),
          child: CustomScrollView(
            controller: _controller,
            cacheExtent: 800,
            slivers: [
              SliverPadding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!isStockCategory) ...[
                        CustomSearchField(
                          focusBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: const BorderSide(color: Colors.grey),
                          ),
                          onChange: (value) {
                            // Refetch (debounced) as the query changes — including
                            // when it is cleared (empty -> null), so the list
                            // resets to the unfiltered category feed instead of
                            // keeping stale results.
                            setState(() {
                              search = value.isEmpty ? null : value;
                            });
                            _onDebounce();
                          },
                          onSubmit: (query) {
                            context.router.push(ResultsRoute(
                              initialSearch: query,
                            ));
                          },
                        ),
                      ] else ...[
                        Padding(
                          padding: EdgeInsets.only(bottom: 10.h),
                          child: const TextTranslated(
                            "Сейчас на складе в Кыргызстане:",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                      SizedBox(height: 24.h),
                    ],
                  ),
                ),
              ),
              if (isInitialLoading)
                const SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: 15),
                  sliver: SliverToBoxAdapter(
                    child: ShimmerProductGrid(),
                  ),
                )
              else if (state.products.isEmpty && !isStockCategory)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  sliver: SliverToBoxAdapter(
                    child: EmptyComment(
                      subTitle: 'В выбранной категории товары отсутствуют',
                      image: 'assets/icons/korzinka.png',
                      height: 190.h,
                    ),
                  ),
                )
              else ...[
                if (isStockCategory)
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          if (placement.isBannerIndex(index)) {
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8.0),
                              child: FeedBannerCard(
                                  banner: placement.bannerAt(index)),
                            );
                          }
                          final order =
                              filteredProducts[placement.productIndexAt(index)];
                          return RepaintBoundary(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8.0),
                              child: MaybePromotedCard(
                                postId: order.id,
                                isPromoted: order.isPromoted,
                                promoEndAt: order.promoEndAt,
                                placement: PromotionPlacement.categoryTop,
                                child: OrderProductCard(
                                  order: order,
                                  onTap: () => _openOtherUserProfile(
                                    username: order.owner?.username ?? "",
                                    userId: order.owner?.id ?? "",
                                    productType: order.postType != null
                                        ? int.tryParse(order.postType!)
                                        : null,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                        childCount: placement.totalItemCount,
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (ctx, index) {
                          if (placement.isBannerIndex(index)) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: FeedBannerCard(
                                  banner: placement.bannerAt(index)),
                            );
                          }
                          final product =
                              filteredProducts[placement.productIndexAt(index)];

                          Widget cardContent;
                          if (choseOwner != null &&
                              choseOwner != 4 &&
                              choseOwner != 8) {
                            cardContent = GestureDetector(
                              onTap: () => _openOtherUserProfile(
                                username: product.owner?.username ?? "",
                                userId: product.owner?.id ?? "",
                                productType: product.postType != null
                                    ? int.tryParse(product.postType!)
                                    : null,
                              ),
                              child: Material(
                                borderRadius: BorderRadius.circular(10),
                                elevation: 10,
                                color: stateSwitch
                                    ? const Color(0xff0e1e33)
                                    : Colors.white,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Container(
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          image: DecorationImage(
                                            fit: BoxFit.fill,
                                            image: product.owner?.image != null
                                                ? CachedNetworkImageProvider(
                                                    product.owner!.image)
                                                : const AssetImage(
                                                        'assets/product_not_found.png')
                                                    as ImageProvider,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(10.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          TextTranslated(
                                            product.owner!.username,
                                            maxLines: 1,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          TextTranslated(
                                            product.owner!.description,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          SizedBox(height: 10.h),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              if (product.owner!.rating >
                                                  0) ...[
                                                RatingStars(
                                                  rating: product.owner!.rating,
                                                ),
                                                SizedBox(width: 10.w),
                                                TextTranslated(
                                                  product.owner!.reviewsCount
                                                      .toString(),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.fade,
                                                  style: const TextStyle(
                                                      fontSize: 13),
                                                ),
                                              ] else
                                                const TextTranslated(
                                                  'нет отзывов',
                                                  style: TextStyle(
                                                      fontSize: 11,
                                                      color: Colors.grey),
                                                ),
                                            ],
                                          ),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            children: [
                                              if (product
                                                  .owner!.userStatus!.isPremium)
                                                const Image(
                                                  image: AssetImage(
                                                      'assets/logo2.png'),
                                                  width: 24,
                                                  height: 24,
                                                ),
                                              SizedBox(width: 5.w),
                                              if (product
                                                  .owner!.userStatus!.isActive)
                                                const Icon(
                                                  Icons.check_circle_outline,
                                                  color: Colors.green,
                                                ),
                                              const Spacer(),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          } else {
                            cardContent = ProductFeedCard(
                              product: product,
                              chooseMain: choseMain,
                            );
                          }

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: Column(
                              children: [
                                RepaintBoundary(child: cardContent),
                                // Cards have no border of their own, so without
                                // an explicit separator consecutive full-width
                                // cards visually run into each other.
                                Divider(
                                  height: 24.h,
                                  thickness: 1,
                                  color: stateSwitch
                                      ? Colors.white.withValues(alpha: 0.08)
                                      : const Color(0xFFEDEDED),
                                ),
                              ],
                            ),
                          );
                        },
                        childCount: placement.totalItemCount,
                      ),
                    ),
                  ),
                // Seamless pagination: the next page is appended automatically
                // while scrolling (see InfiniteScrollRegion below); this only
                // shows the bottom activity indicator during the fetch.
                if (!isStockCategory)
                  SliverLoadMoreIndicator(isLoading: state.isLoadingPaginate),
              ],
              SliverToBoxAdapter(
                child: SizedBox(
                  height: kBottomNavigationBarHeight +
                      MediaQuery.viewPaddingOf(context).bottom +
                      20,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = context.select((ThemeNotifier n) => n.isDarkMode);
    final mock = mockListing;

    if (isStockCategory) {
      return CustomScaffold(
        bottomNavigationBar: const BottomNav(
          currentIndexOverride: -2,
          passive: true,
        ),
        title: widget.title,
        child: _buildProductsTab(context),
      );
    }

    if (mock != null) {
      return _MockListingScaffold(
        title: widget.title,
        listing: mock,
        isDarkMode: isDarkMode,
      );
    }

    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.black : AppColors.white,
      appBar: AppBar(
        backgroundColor: isDarkMode ? AppColors.black : AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: isDarkMode ? Colors.white : Colors.black,
          onPressed: () => context.router.maybePop(),
        ),
        centerTitle: false,
        title: Text(
          widget.title,
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton(
              onPressed: _openFilterSheet,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF007AFF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              ),
              child: const Text(
                'Фильтр',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          _buildProductsTab(context),
          const Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: BottomNav(
              currentIndexOverride: -2,
              passive: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _MockListingScaffold extends StatefulWidget {
  const _MockListingScaffold({
    required this.title,
    required this.listing,
    required this.isDarkMode,
  });

  final String title;
  final SedanMockListing listing;
  final bool isDarkMode;

  @override
  State<_MockListingScaffold> createState() => _MockListingScaffoldState();
}

class _MockListingScaffoldState extends State<_MockListingScaffold> {
  String _search = '';
  bool _isSaved = false;

  bool get _matchesSearch {
    final query = _search.trim().toLowerCase();
    if (query.isEmpty) return true;

    final listing = widget.listing;
    final searchable = [
      listing.title,
      listing.price,
      listing.condition,
      ...listing.specs.map((spec) => '${spec.label} ${spec.value}'),
    ].join(' ').toLowerCase();

    return searchable.contains(query);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.isDarkMode ? AppColors.black : AppColors.white,
      appBar: AppBar(
        backgroundColor: widget.isDarkMode ? AppColors.black : AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: widget.isDarkMode ? Colors.white : Colors.black,
          onPressed: () => context.router.maybePop(),
        ),
        centerTitle: false,
        title: Text(
          widget.title,
          style: TextStyle(
            color: widget.isDarkMode ? Colors.white : Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton(
              onPressed: () {},
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF007AFF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              ),
              child: const Text(
                'Фильтр',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverPadding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
                sliver: SliverToBoxAdapter(
                  child: _MockSearchField(
                    isDarkMode: widget.isDarkMode,
                    onChanged: (value) => setState(() => _search = value),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                sliver: SliverToBoxAdapter(
                  child: _matchesSearch
                      ? _MockListingCard(
                          listing: widget.listing,
                          isDarkMode: widget.isDarkMode,
                          isSaved: _isSaved,
                          onSavedTap: () =>
                              setState(() => _isSaved = !_isSaved),
                        )
                      : EmptyComment(
                          subTitle: 'В выбранной категории товары отсутствуют',
                          image: 'assets/icons/korzinka.png',
                          height: 190.h,
                        ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: kBottomNavigationBarHeight +
                      MediaQuery.viewPaddingOf(context).bottom +
                      20,
                ),
              ),
            ],
          ),
          const Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: BottomNav(
              currentIndexOverride: -2,
              passive: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _MockSearchField extends StatelessWidget {
  const _MockSearchField({
    required this.isDarkMode,
    required this.onChanged,
  });

  final bool isDarkMode;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final borderColor = isDarkMode ? Colors.white12 : Colors.grey.shade300;
    final hintColor = isDarkMode ? Colors.white60 : const Color(0xff797979);
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final iconColor = isDarkMode ? Colors.white70 : const Color(0xff797979);

    return TextField(
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      style: TextStyle(color: textColor, fontSize: 16),
      decoration: InputDecoration(
        prefixIcon: Icon(Icons.search, color: iconColor, size: 28),
        hintText: 'Поиск авто на Sedan.Kg',
        hintStyle: TextStyle(color: hintColor, fontSize: 16),
        filled: true,
        fillColor: Colors.transparent,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.grey),
        ),
      ),
    );
  }
}

class _MockListingCard extends StatelessWidget {
  const _MockListingCard({
    required this.listing,
    required this.isDarkMode,
    required this.isSaved,
    required this.onSavedTap,
  });

  final SedanMockListing listing;
  final bool isDarkMode;
  final bool isSaved;
  final VoidCallback onSavedTap;

  @override
  Widget build(BuildContext context) {
    final fg = isDarkMode ? Colors.white : Colors.black;
    final sub = isDarkMode ? Colors.white70 : const Color(0xFF666666);
    final cardColor = isDarkMode ? const Color(0xFF111111) : Colors.white;
    final borderColor = isDarkMode
        ? Colors.white.withValues(alpha: 0.10)
        : const Color(0xFFE8E8E8);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => SedanMockDetailsPage(listing: listing),
          ),
        );
      },
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
          boxShadow: isDarkMode
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.07),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
              child: AspectRatio(
                aspectRatio: 1.65,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      listing.imageAsset,
                      fit: BoxFit.cover,
                    ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Material(
                        color: isSaved ? const Color(0xFF007AFF) : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: onSavedTap,
                          child: SizedBox(
                            width: 38,
                            height: 38,
                            child: Icon(
                              isSaved ? Icons.bookmark : Icons.bookmark_border,
                              color: isSaved ? Colors.white : Colors.black,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    listing.title,
                    style: TextStyle(
                      color: fg,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...listing.specs.map(
                    (spec) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: _MockSpecRow(
                        label: spec.label,
                        value: spec.value,
                        fg: fg,
                        sub: sub,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  _MockSpecRow(
                    label: 'Состояние',
                    value: listing.condition,
                    fg: fg,
                    sub: sub,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    listing.price,
                    style: const TextStyle(
                      color: Color(0xFF007AFF),
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MockSpecRow extends StatelessWidget {
  const _MockSpecRow({
    required this.label,
    required this.value,
    required this.fg,
    required this.sub,
  });

  final String label;
  final String value;
  final Color fg;
  final Color sub;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: TextStyle(
          color: sub,
          fontSize: 14,
          height: 1.35,
        ),
        children: [
          TextSpan(
            text: '$label: ',
            style: TextStyle(color: fg, fontWeight: FontWeight.w700),
          ),
          TextSpan(text: value),
        ],
      ),
    );
  }
}
