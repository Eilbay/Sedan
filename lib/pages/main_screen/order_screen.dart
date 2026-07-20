import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:optombai/bloc/auth_bloc/auth_cubit.dart';
import 'package:optombai/bloc/market_bloc/supplier_market_bloc.dart';
import 'package:optombai/bloc/market_bloc/supplier_market_event.dart';
import 'package:optombai/core/di/injection.dart';
import 'package:optombai/core/import_links.dart';
import 'package:optombai/data/models/countries/countries.dart';
import 'package:optombai/data/repositories/i_product_repository.dart';
import 'package:optombai/widgets/app_scaffold/bazarlar_app_scaffold.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:optombai/app/router/app_router.dart';
import 'package:optombai/pages/main_screen/widgets/order_empty_states.dart';
import 'package:optombai/pages/main_screen/widgets/order_product_card.dart';
import 'package:optombai/pages/main_screen/widgets/orders_filters_header.dart';
import 'package:optombai/pages/main_screen/widgets/product_owner_grid_card.dart';
import 'package:optombai/pages/main_screen/widgets/user_grid_card.dart';
import 'package:optombai/widgets/bottom_nav.dart';
import 'package:optombai/widgets/common/infinite_scroll_region.dart';
import 'package:optombai/widgets/promotion/maybe_promoted_card.dart';
import 'package:optombai/widgets/promotion/promotion_placement.dart';
import 'package:optombai/widgets/translation/text_translated.dart';
import 'package:optombai/widgets/shimmer/shimmer_list_tile.dart';
import 'package:optombai/widgets/shimmer/shimmer_product_grid.dart';

// Re-export for backward compatibility (used by suborder_screen, products_screen)
export 'package:optombai/pages/main_screen/widgets/order_product_card.dart';
export 'package:optombai/pages/main_screen/widgets/market_status_badge.dart';
import 'package:auto_route/auto_route.dart';

@RoutePage()
class OrdersScreen extends StatelessWidget {
  final int? choseOwner;
  final int? choseMain;
  final int? countryId;

  const OrdersScreen({
    super.key,
    this.choseMain = 0,
    this.choseOwner,
    this.countryId,
  });

  @override
  Widget build(BuildContext context) {
    // Scoped ProductBloc isolates this screen's feed from the global one the
    // home screen uses. Tapping the "Заказы оптом" tile on home fires a
    // 250ms-debounced home feed fetch; sharing a single CancelableOperation,
    // that late fetch cancelled this screen's in-flight request and overwrote
    // postModel with the home feed — leaving the list empty until a manual
    // refresh. A dedicated bloc removes the race.
    return BlocProvider<ProductBloc>(
      create: (_) => ProductBloc(
        repository: getIt<IProductRepository>(),
        preferences: getIt<SharedPreferences>(),
      ),
      child: _OrdersView(
        choseOwner: choseOwner,
        choseMain: choseMain,
        countryId: countryId,
      ),
    );
  }
}

class _OrdersView extends StatefulWidget {
  final int? choseOwner;
  final int? choseMain;
  final int? countryId;

  const _OrdersView({
    this.choseMain = 0,
    this.choseOwner,
    this.countryId,
  });

  @override
  State<_OrdersView> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<_OrdersView> {
  String ownerName = "Владелец";
  List<User> users = [];

  String countryName = "Страна";

  String marketName = "По рынкам";
  int? marketId;

  // Client-side filter: "Все" or only owner.is_verified == true.
  // Applies to suppliers (4) and manufacturers (8) only.
  bool _showVerifiedOnly = false;

  bool isLike = false;
  final ScrollController _controller = ScrollController();
  Timer _debounce = Timer(Duration.zero, () {});

  List<SortModel> lists = [
    SortModel("Не указaно", null),
    SortModel("Сначала дешевле", "price"),
    SortModel("Сначала дороже", "-price"),
    SortModel("Сначала новые", "created_at"),
    SortModel("Выше рейтинг", "-rating"),
  ];

  int indexSort = 0;
  String? search;
  String? priceGte;
  String? priceLte;
  String? categoryId;
  int? choseOwner;
  int? countryId;
  int? choseMain = 0;
  int totalQuantityUsers = 0;

  @override
  void initState() {
    super.initState();

    choseOwner = widget.choseOwner;
    choseMain = widget.choseMain;
    fetchData();

    if (choseOwner == 4) {
      context.read<SupplierMarketBloc>().add(
            const SupplierMarketInit('', username: ''),
          );
    }

    if (choseOwner == 0) {
      context
          .read<CategoryBloc>()
          .add(CategoryAllEvent(categoryTypes: const [2]));
    } else {
      context.read<CategoryBloc>().add(CategoryAllEvent());
    }

    if (choseOwner == 0) {
      fetchProductWithFilter();
    }

    if (choseOwner == 4 || choseOwner == 8) {
      _fetchUserCountForType();
    }

    if (choseOwner == 16) {
      categoryId = null;
      _fetchCustomers();
    }

    context.read<CountryBloc>().add(const CountryAllEvent());
  }

  @override
  void dispose() {
    _controller.dispose();
    _debounce.cancel();
    super.dispose();
  }

  void _onSearchDebounce() {
    if (_debounce.isActive) _debounce.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (choseOwner == 0) {
        fetchProductWithFilter();
      } else if (choseOwner == 4 || choseOwner == 8) {
        _fetchUserCountForType();
      }
    });
  }

  Future<void> _fetchUserCountForType() async {
    if (choseOwner == 4 || choseOwner == 8) {
      context.read<AuthCubit>().fetchUserCountForType(
            choseOwner.toString(),
            categories: categoryId,
          );
      context.read<UserBloc>().add(
            FetchUsersByTypeAndCountry(
              userType: choseOwner.toString(),
              country: countryId.toString(),
              categories: categoryId,
              market: (choseOwner == 4) ? marketId : null,
              isVerified: _showVerifiedOnly,
            ),
          );
    }
  }

  Future<void> _fetchCustomers() async {
    if (choseOwner == 16) {
      context.read<UserBloc>().add(
            FetchCustomers(
              countryId: countryId?.toString(),
              categoryId: categoryId,
            ),
          );
    }
  }

  Future<void> _openOtherUserProfile({
    required String userId,
    required String username,
    String? postId,
    int? productType,
  }) async {
    final offsetBefore = _controller.offset;

    await context.router.push(OtherUserProfileRoute(
      username: username,
      productType: productType,
      user: userId,
    ));

    if (!mounted) return;

    if (postId != null) {
      context.read<ProductBloc>().add(RegisterPostViewEvent(postId));
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_controller.hasClients) _controller.jumpTo(offsetBefore);
    });
  }

  void fetchProductWithFilter() {
    final rawOrdering = lists[indexSort].value;
    final ordering = (rawOrdering?.trim().isEmpty ?? true) ? null : rawOrdering;

    BlocProvider.of<ProductBloc>(context).add(ProductWithFilter(
      search: search,
      priceGte: (priceGte?.trim().isEmpty ?? true) ? null : priceGte,
      priceLte: (priceLte?.trim().isEmpty ?? true) ? null : priceLte,
      ordering: ordering,
      typeProduct: choseMain,
      typeOwner: choseOwner,
      category: categoryId,
      countryId: countryId ?? widget.countryId,
      limit: 20,
    ));
  }

  String removeEmojisAndSmallWords(String text) {
    return text.replaceAll(
        RegExp(
            r'[\u{1F300}-\u{1FAD6}\u{1F900}-\u{1F9FF}\u{1F600}-\u{1F64F}\u{2700}-\u{27BF}]',
            unicode: true),
        '');
  }

  void fetchData() {
    var owner = combinedList.firstWhere(
      (item) => item.id == widget.choseOwner,
      orElse: () => ChoseClass(),
    );
    ownerName = removeEmojisAndSmallWords(owner.name.trim());

    var state = context.read<CountryBloc>().state;
    var country = state.list.firstWhere(
      (c) => c.id == widget.countryId,
      orElse: () => const CountryModel(name: ""),
    );
    countryName = country.name;

    setState(() {});
  }

  String _correctCountryName() {
    return {
          "Россия": "России",
          "Казахстан": "Казахстана",
          "Кыргызстан": "Кыргызстана",
          "Узбекистан": "Узбекистана",
          "Турция": "Турции",
          "Белоруссия": "Белоруссии",
          "Все страны": "Всех стран",
        }[countryName] ??
        countryName;
  }

  int _totalQuantity(ProductState state) {
    if (choseOwner == 0) {
      return state.postModel?.count ?? 0;
    } else if (choseOwner == 4 || choseOwner == 8 || choseOwner == 16) {
      return totalQuantityUsers;
    }
    return state.postModel?.count ?? 0;
  }

  List<Product> _filteredProducts(ProductState state) {
    if (choseOwner == null) return state.products;

    final uniqueOwners = <String>{};
    return state.products.where((product) {
      if (product.owner != null && !uniqueOwners.contains(product.owner!.id)) {
        uniqueOwners.add(product.owner!.id);
        return true;
      }
      return false;
    }).toList();
  }

  List<Widget> _buildContentSlivers({
    required ProductState state,
    required UserState userState,
    required bool isDarkMode,
  }) {
    if (choseOwner == 0 && state.isLoading) {
      return [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              children: List.generate(4, (_) => const ShimmerListTile()),
            ),
          ),
        ),
      ];
    }

    if ((choseOwner == 4 || choseOwner == 8 || choseOwner == 16) &&
        userState.isLoading) {
      return [
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 15),
            child: ShimmerProductGrid(itemCount: 4),
          ),
        ),
      ];
    }

    final correctCountry = _correctCountryName();
    final totalQuantity = _totalQuantity(state);
    final filteredProducts = _filteredProducts(state);

    final slivers = <Widget>[];

    slivers.add(SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      sliver: SliverToBoxAdapter(
        child: OrderContentHeader(
          ownerName: ownerName,
          correctCountryName: correctCountry,
          totalQuantity: totalQuantity,
        ),
      ),
    ));

    slivers.add(SliverToBoxAdapter(child: SizedBox(height: 20.h)));

    if (choseOwner == 0) {
      _addProductSlivers(slivers, state: state);
    } else if (choseOwner == 4 || choseOwner == 8 || choseOwner == 16) {
      _addUserSlivers(slivers, userState: userState, isDarkMode: isDarkMode);
    } else {
      _addProductOwnerSlivers(
        slivers,
        filteredProducts: filteredProducts,
        isDarkMode: isDarkMode,
      );
    }

    return slivers;
  }

  void _addProductSlivers(List<Widget> slivers, {required ProductState state}) {
    final results = (state.postModel?.results ?? [])
        .where((item) => item.postType == "0")
        .toList();
    final total = state.postModel?.count ?? 0;

    if (!state.isLoading && total == 0 && results.isEmpty) {
      slivers.add(const SliverToBoxAdapter(child: EmptySearchResult()));
      return;
    }

    slivers.add(SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      sliver: SliverList.builder(
        itemCount: results.length,
        itemBuilder: (context, index) {
          final order = results[index];
          return RepaintBoundary(
            child: MaybePromotedCard(
              postId: order.id,
              isPromoted: order.isPromoted,
              promoEndAt: order.promoEndAt,
              placement: PromotionPlacement.main,
              child: OrderProductCard(
                key: ValueKey(order.id),
                order: order,
                onTap: () => _openOtherUserProfile(
                  userId: order.owner?.id ?? "",
                  username: order.owner?.username ?? "",
                  postId: order.id,
                  productType: int.tryParse(order.postType ?? '0'),
                ),
              ),
            ),
          );
        },
      ),
    ));

    // Seamless pagination: pages append while scrolling (InfiniteScrollRegion
    // around the scroll view); this is just the bottom activity indicator.
    slivers.add(SliverLoadMoreIndicator(isLoading: state.isLoadingPaginate));
  }

  void _addUserSlivers(
    List<Widget> slivers, {
    required UserState userState,
    required bool isDarkMode,
  }) {
    final totalUsers = totalQuantityUsers;
    final showVerifiedTabs = choseOwner == 4 || choseOwner == 8;
    // Filtering is server-side (is_verified) so `count`/pagination reflect the
    // verified set — no client-side .where() (which left phantom pages).
    final visibleUsers = users;

    if (showVerifiedTabs) {
      slivers.add(SliverToBoxAdapter(
        child: _VerifiedFilterTabs(
          showVerifiedOnly: _showVerifiedOnly,
          isDarkMode: isDarkMode,
          onChanged: (verifiedOnly) {
            setState(() => _showVerifiedOnly = verifiedOnly);
            // Re-fetch page 1 with the server-side verified filter so the
            // result count and page count reflect verified users only.
            context.read<UserBloc>().add(FetchUsersByTypeAndCountry(
                  userType: choseOwner.toString(),
                  country: countryId.toString(),
                  categories: categoryId,
                  market: (choseOwner == 4) ? marketId : null,
                  isVerified: verifiedOnly,
                ));
          },
        ),
      ));
    }

    if (!userState.isLoading && visibleUsers.isEmpty && totalUsers == 0) {
      slivers.add(const SliverToBoxAdapter(child: EmptyUsersResult()));
    } else if (!userState.isLoading && visibleUsers.isEmpty) {
      slivers.add(SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 32),
        sliver: SliverToBoxAdapter(
          child: Center(
            child: TextTranslated(
              'Нет проверенных на этой странице',
              style: TextStyle(
                color: isDarkMode ? Colors.white70 : Colors.black54,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ));
    } else {
      slivers.add(SliverPadding(
        padding: const EdgeInsets.only(left: 15, right: 15, bottom: 20),
        sliver: SliverGrid.builder(
          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 230,
            mainAxisSpacing: 18,
            childAspectRatio: (MediaQuery.sizeOf(context).width * .2) / 150,
            crossAxisSpacing: 10,
          ),
          itemCount: visibleUsers.length,
          itemBuilder: (BuildContext ctx, index) {
            final user = visibleUsers[index];
            return RepaintBoundary(
              child: UserGridCard(
                user: user,
                isDarkMode: isDarkMode,
                choseOwner: choseOwner,
                onTap: () => _openOtherUserProfile(
                  userId: user.id,
                  username: user.username,
                  productType: choseOwner,
                ),
              ),
            );
          },
        ),
      ));
    }

    // Seamless pagination: next pages append while scrolling (see
    // InfiniteScrollRegion around the scroll view).
    if (choseOwner == 4 || choseOwner == 8 || choseOwner == 16) {
      slivers.add(
        SliverLoadMoreIndicator(isLoading: userState.isLoadingPaginate),
      );
    }
  }

  /// Dispatches the load-more event matching the currently shown list.
  /// Blocs guard re-entry and "no next page" themselves, so this can fire
  /// on every scroll frame near the bottom.
  void _loadMore() {
    if (choseOwner == 16) {
      context.read<UserBloc>().add(CustomersPageEvent());
    } else if (choseOwner == 4 || choseOwner == 8) {
      context.read<UserBloc>().add(UserPageEvent(
            userType: choseOwner.toString(),
            country: countryId?.toString() ?? '',
            categories: categoryId,
            market: (choseOwner == 4) ? marketId : null,
          ));
    } else {
      context.read<ProductBloc>().add(ProductPageEvent());
    }
  }

  void _addProductOwnerSlivers(
    List<Widget> slivers, {
    required List<Product> filteredProducts,
    required bool isDarkMode,
  }) {
    slivers.add(SliverPadding(
      padding: const EdgeInsets.only(left: 15, right: 15, bottom: 20),
      sliver: SliverGrid.builder(
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 230,
          mainAxisSpacing: 18,
          childAspectRatio: (MediaQuery.sizeOf(context).width * .2) / 130,
          crossAxisSpacing: 10,
        ),
        itemCount: filteredProducts.length,
        itemBuilder: (BuildContext ctx, index) {
          final product = filteredProducts[index];
          final userId = product.owner?.id;
          if (userId != null) {
            context.read<UserBloc>().add(UserOtherEvent(userId));
          }

          return RepaintBoundary(
            child: MaybePromotedCard(
              postId: product.id,
              isPromoted: product.isPromoted,
              promoEndAt: product.promoEndAt,
              placement: PromotionPlacement.main,
              child: ProductOwnerGridCard(
                product: product,
                isDarkMode: isDarkMode,
                onTap: () => _openOtherUserProfile(
                  userId: product.owner?.id ?? "",
                  postId: product.id,
                  username: product.owner?.username ?? "",
                  productType: product.postType != null
                      ? int.tryParse(product.postType!)
                      : null,
                ),
              ),
            ),
          );
        },
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = context.select((ThemeNotifier n) => n.isDarkMode);

    if (choseOwner == 4 || choseOwner == 8 || choseOwner == 16) {
      context.select((UserBloc b) => b.state.currentPage);
    } else {
      context.select((ProductBloc b) => b.state.currentPage);
    }

    return BazarlarAppScaffold(
      bottomNavigationBar:
          const BottomNav(currentIndexOverride: -1, passive: true),
      onRefresh: () async {
        if (choseOwner == 4 || choseOwner == 8) {
          await _fetchUserCountForType();
        } else if (choseOwner == 16) {
          await _fetchCustomers();
        } else {
          fetchProductWithFilter();
        }
      },
      child: BlocListener<UserBloc, UserState>(
        listener: (context, state) {
          if (state.isSuccess) {
            setState(() {
              users = state.notifications;
              totalQuantityUsers = state.count ?? 0;
            });
          }
        },
        child: BlocConsumer<ProductBloc, ProductState>(
          listener: (context, state) {},
          builder: (context, state) {
            final userState = context.select((UserBloc b) => b.state);

            return InfiniteScrollRegion(
              onLoadMore: _loadMore,
              child: CustomScrollView(
                controller: _controller,
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    sliver: SliverToBoxAdapter(
                      child: OrdersFiltersHeader(
                        choseOwner: choseOwner,
                        isDarkMode: isDarkMode,
                        marketId: marketId,
                        countryId: countryId,
                        categoryId: categoryId,
                        onSearchSubmit: (query) {
                          context.router.push(ResultsRoute(
                            initialSearch: query,
                          ));
                        },
                        onSearchChanged: (value) {
                          setState(() => search = value);
                          _onSearchDebounce();
                        },
                        onMarketChanged: (id) {
                          setState(() => marketId = (id == 0) ? null : id);
                          _fetchUserCountForType();
                        },
                        onCountryChanged: (value, name) {
                          setState(() {
                            if (value == 0) {
                              countryId = null;
                              countryName = "Все страны";
                            } else {
                              countryId = value;
                              countryName = name;
                            }
                          });

                          if (choseOwner == 0) {
                            fetchProductWithFilter();
                          } else if (choseOwner == 16) {
                            _fetchCustomers();
                          } else if (choseOwner == 4 || choseOwner == 8) {
                            _fetchUserCountForType();
                          }
                        },
                        onCategoryChanged: (value) {
                          setState(() {
                            categoryId = (value == 'all') ? null : value;
                          });

                          if (choseOwner == 0) {
                            fetchProductWithFilter();
                            return;
                          }

                          if (choseOwner == 16) {
                            _fetchCustomers();
                          } else if (choseOwner == 4 || choseOwner == 8) {
                            _fetchUserCountForType();
                          }
                        },
                      ),
                    ),
                  ),
                  ..._buildContentSlivers(
                    state: state,
                    userState: userState,
                    isDarkMode: isDarkMode,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _VerifiedFilterTabs extends StatelessWidget {
  final bool showVerifiedOnly;
  final bool isDarkMode;
  final ValueChanged<bool> onChanged;

  const _VerifiedFilterTabs({
    required this.showVerifiedOnly,
    required this.isDarkMode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(15, 4, 15, 12),
      child: Row(
        children: [
          Expanded(
            child: _TabButton(
              label: 'Все',
              isSelected: !showVerifiedOnly,
              isDarkMode: isDarkMode,
              onTap: () => onChanged(false),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _TabButton(
              label: 'Проверенные',
              isSelected: showVerifiedOnly,
              isDarkMode: isDarkMode,
              onTap: () => onChanged(true),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final bool isDarkMode;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.isSelected,
    required this.isDarkMode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final selectedBg = isDarkMode ? Colors.white : Colors.black;
    final selectedFg = isDarkMode ? Colors.black : Colors.white;
    final idleBg = isDarkMode ? Colors.white10 : Colors.black12;
    final idleFg = isDarkMode ? Colors.white70 : Colors.black87;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? selectedBg : idleBg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (label == 'Проверенные') ...[
                Icon(
                  Icons.verified,
                  size: 16,
                  color: isSelected ? selectedFg : Colors.blueAccent,
                ),
                const SizedBox(width: 6),
              ],
              TextTranslated(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? selectedFg : idleFg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
