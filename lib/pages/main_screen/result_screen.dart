import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:optombai/core/import_links.dart';
import 'package:optombai/data/models/countries/countries.dart';
import 'package:optombai/app/router/app_router.dart';

import 'package:optombai/widgets/bottom_nav.dart';
import 'package:optombai/widgets/common/infinite_scroll_region.dart';
import 'package:optombai/widgets/promotion/maybe_promoted_card.dart';
import 'package:optombai/widgets/promotion/promotion_placement.dart';
import 'package:optombai/widgets/translation/text_translated.dart';
import 'package:optombai/widgets/shimmer/shimmer_product_grid.dart';
import 'package:optombai/widgets/utils/dropdown/category_dropdown.dart';
import 'package:auto_route/auto_route.dart';

@RoutePage()
class ResultsScreen extends StatefulWidget {
  final int? choseOwner;
  final int? countryId;
  final String? initialSearch;

  const ResultsScreen({
    super.key,
    this.choseOwner,
    this.countryId,
    this.initialSearch,
  });

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  final ScrollController _controller = ScrollController();

  List<SortModel> lists = [
    SortModel("Не указано", null),
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

  bool _usersLoading = false;

  @override
  void initState() {
    super.initState();

    search = widget.initialSearch?.trim();
    choseOwner = widget.choseOwner;
    countryId = widget.countryId;

    context.read<CategoryBloc>().add(CategoryAllEvent());
    context.read<CountryBloc>().add(const CountryAllEvent());

    _fetchAll();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _fetchAll() {
    _fetchProducts();
    _fetchUsers();
  }

  void _fetchProducts() {
    final rawOrdering = lists[indexSort].value;
    final ordering = (rawOrdering?.trim().isEmpty ?? true) ? null : rawOrdering;

    context.read<ProductBloc>().add(
          ProductWithFilter(
            search: (search?.trim().isEmpty ?? true) ? null : search,
            priceGte: (priceGte?.trim().isEmpty ?? true) ? null : priceGte,
            priceLte: (priceLte?.trim().isEmpty ?? true) ? null : priceLte,
            ordering: ordering,
            typeProduct: widget.choseOwner,
            typeOwner: choseOwner,
            category: categoryId,
            countryId: countryId ?? widget.countryId,
            limit: 20,
          ),
        );
  }

  void _fetchUsers({int page = 1}) {
    final q = (search?.trim() ?? '');
    if (q.isEmpty) return;

    final rawOrdering = lists[indexSort].value;
    final ordering = (rawOrdering?.trim().isEmpty ?? true) ? null : rawOrdering;

    context.read<UserBloc>().add(
          SearchUsersEvent(
            search: q,
            page: page,
            limit: 20,
            categoryId:
                (categoryId?.trim().isEmpty ?? true) ? null : categoryId,
            countryId: countryId,
            ordering: ordering,
          ),
        );
  }

  Future<void> _openOtherUserProfile({
    required String userId,
    required String username,
    int? productType,
  }) async {
    final offsetBefore = _controller.offset;

    await context.router.push(OtherUserProfileRoute(
      user: userId,
      productType: productType,
      username: username,
    ));

    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_controller.hasClients) _controller.jumpTo(offsetBefore);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.select((ThemeNotifier n) => n.isDarkMode);

    return CustomScaffold(
      title: "Результаты",
      bottomNavigationBar: const BottomNav(
        currentIndexOverride: -1,
        passive: true,
      ),
      child: MultiBlocListener(
        listeners: [
          BlocListener<UserBloc, UserState>(
            listener: (context, state) {
              setState(() {
                _usersLoading = state.isLoading || state.isLoadingPaginate;
              });
            },
          ),
        ],
        child: InfiniteScrollRegion(
          // Seamless pagination for the products section (the bottom one);
          // the bloc guards re-entry and "no next page" itself.
          onLoadMore: () => context.read<ProductBloc>().add(ProductPageEvent()),
          child: SingleChildScrollView(
            controller: _controller,
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 18.h),
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                      children: [
                        const TextSpan(text: 'по запросу '),
                        TextSpan(
                          text: '«${widget.initialSearch ?? ''}»',
                          style: const TextStyle(
                            color: Color(0xFF1967FF),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 12.h),
                // _SortRow(
                //   sortOptions: lists,
                //   selectedIndex: indexSort,
                //   onSelected: (newIndex) {
                //     setState(() => indexSort = newIndex);
                //     _fetchProducts();
                //     _fetchUsers(page: 1);
                //   },
                // ),
                // SizedBox(height: 10.h),
                // SizedBox(
                //   height: 50.h,
                //   child: ListView(
                //     scrollDirection: Axis.horizontal,
                //     children: [
                //       SizedBox(
                //         width: MediaQuery.sizeOf(context).width * .50,
                //         child: BlocBuilder<CountryBloc, CountryState>(
                //           buildWhen: (previous, current) =>
                //               previous.list != current.list,
                //           builder: (context, state) {
                //             final countries = <CountryModel>[
                //               const CountryModel(id: 0, name: "Все страны"),
                //               ...state.list,
                //             ];
                //
                //             final selectedValue = countryId ?? 0;
                //
                //             return CustomDropdown(
                //               title: "Страна",
                //               titleSize: 16,
                //               itemSize: 17,
                //               list: countries,
                //               value: selectedValue,
                //               onChanged: (v) {
                //                 setState(() => countryId = (v == 0) ? null : v);
                //                 _fetchProducts();
                //                 _fetchUsers(page: 1);
                //               },
                //             );
                //           },
                //         ),
                //       ),
                //       SizedBox(width: 8.w),
                //       SizedBox(
                //         width: MediaQuery.sizeOf(context).width * .70,
                //         child: BlocBuilder<CategoryBloc, CategoryState>(
                //           buildWhen: (previous, current) =>
                //               previous.categories != current.categories,
                //           builder: (context, state) {
                //             final categories = state.categories.where((cat) {
                //               final n = cat.name.trim().toLowerCase();
                //               return n != 'другое' &&
                //                   !n.contains('статус') &&
                //                   !n.contains('склад');
                //             }).toList();
                //
                //             final list = <Category>[
                //               const Category(id: 'all', name: 'Все категории'),
                //               ...categories,
                //             ];
                //
                //             final selectedValue = categoryId ?? 'all';
                //
                //             return CustomCategoryDropdown(
                //               list: list,
                //               value: selectedValue,
                //               hint: 'Категории',
                //               onChanged: (value) {
                //                 setState(() => categoryId =
                //                     (value == 'all' || value == '')
                //                         ? null
                //                         : value);
                //                 _fetchProducts();
                //                 _fetchUsers(page: 1);
                //               },
                //             );
                //           },
                //         ),
                //       ),
                //     ],
                //   ),
                // ),
                // SizedBox(height: 18.h),
                BlocBuilder<UserBloc, UserState>(
                  buildWhen: (previous, current) =>
                      previous.notifications != current.notifications,
                  builder: (context, userState) {
                    final users = userState.notifications;
                    return _UsersSection(
                      users: users,
                      isDarkMode: isDarkMode,
                      usersLoading: _usersLoading,
                      indexSort: indexSort,
                      onOpenProfile: _openOtherUserProfile,
                      onLoadMoreUsers: () => context.read<UserBloc>().add(
                            SearchUsersPageEvent(search: search?.trim() ?? ''),
                          ),
                    );
                  },
                ),
                SizedBox(height: 18.h),
                BlocBuilder<ProductBloc, ProductState>(
                  buildWhen: (previous, current) =>
                      previous.products != current.products ||
                      previous.isLoading != current.isLoading ||
                      previous.isLoadingPaginate != current.isLoadingPaginate ||
                      previous.postModel != current.postModel ||
                      previous.currentPage != current.currentPage ||
                      previous.totalPages != current.totalPages,
                  builder: (context, productState) {
                    return _ProductsSection(
                      state: productState,
                      choseOwner: choseOwner,
                      scrollController: _controller,
                      lists: lists,
                      indexSort: indexSort,
                      search: search,
                      priceGte: priceGte,
                      priceLte: priceLte,
                      typeProduct: widget.choseOwner,
                      categoryId: categoryId,
                      countryId: countryId ?? widget.countryId,
                    );
                  },
                ),
                SizedBox(height: 30.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SortRow extends StatelessWidget {
  final List<SortModel> sortOptions;
  final int selectedIndex;
  final void Function(int) onSelected;

  const _SortRow({
    required this.sortOptions,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const TextTranslated(
          "Сортировка по:   ",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          ),
        ),
        TextTranslated(
          sortOptions[selectedIndex].text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.blue,
          ),
        ),
        const Spacer(),
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.tune),
        ).addStarMenu(
          items: sortOptions.map((e) => TextTranslated(e.text)).toList(),
          onItemTapped: (newIndex, controller) {
            onSelected(newIndex);
            controller.closeMenu!();
          },
          params: StarMenuParameters.dropdown(context),
        ),
      ],
    );
  }
}

class _UsersSection extends StatelessWidget {
  final List<User> users;
  final bool isDarkMode;
  final bool usersLoading;
  final int indexSort;
  final Future<void> Function({
    required String userId,
    required String username,
    int? productType,
  }) onOpenProfile;
  final VoidCallback onLoadMoreUsers;

  const _UsersSection({
    required this.users,
    required this.isDarkMode,
    required this.usersLoading,
    required this.indexSort,
    required this.onOpenProfile,
    required this.onLoadMoreUsers,
  });

  @override
  Widget build(BuildContext context) {
    if (usersLoading && users.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 30),
        child: ShimmerProductGrid(itemCount: 4),
      );
    }

    if (!usersLoading && users.isEmpty) {
      return const SizedBox.shrink();
    }

    final usersSorted = List<User>.from(users);

    if (indexSort == 4) {
      usersSorted.sort((a, b) {
        final r = (b.rating).compareTo(a.rating);
        if (r != 0) return r;

        final rev = (b.reviewsCount).compareTo(a.reviewsCount);
        if (rev != 0) return rev;

        return a.username.toLowerCase().compareTo(b.username.toLowerCase());
      });
    } else if (indexSort != 0) {
      usersSorted.sort(
        (a, b) => a.username.toLowerCase().compareTo(b.username.toLowerCase()),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const TextTranslated(
          "Пользователи",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        SizedBox(height: 12.h),
        GridView.builder(
          primary: false,
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 230,
            mainAxisSpacing: 18,
            crossAxisSpacing: 10,
            childAspectRatio: (MediaQuery.sizeOf(context).width * .2) / 150,
          ),
          itemCount: usersSorted.length,
          itemBuilder: (ctx, index) {
            final u = usersSorted[index];

            return RepaintBoundary(
              child: _UserGridCard(
                user: u,
                isDarkMode: isDarkMode,
                onTap: () => onOpenProfile(
                    userId: u.id,
                    productType: int.tryParse(u.userType ?? ''),
                    username: u.username),
              ),
            );
          },
        ),
        SizedBox(height: 10.h),
        // This section sits mid-page above the products feed, so scroll-based
        // loading would push products around unexpectedly — an explicit
        // "show more" button appends the next page in place instead.
        BlocBuilder<UserBloc, UserState>(
          buildWhen: (p, c) =>
              p.next != c.next || p.isLoadingPaginate != c.isLoadingPaginate,
          builder: (context, st) {
            if (st.isLoadingPaginate) {
              return const LoadMoreIndicator(isLoading: true);
            }
            if (st.next == null) return const SizedBox.shrink();
            return Center(
              child: OutlinedButton(
                onPressed: onLoadMoreUsers,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF007AFF),
                  side: const BorderSide(color: Color(0xFF007AFF)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 10,
                  ),
                ),
                child: const TextTranslated('Показать ещё'),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _ProductsSection extends StatelessWidget {
  final ProductState state;
  final int? choseOwner;
  final ScrollController scrollController;
  final List<SortModel> lists;
  final int indexSort;
  final String? search;
  final String? priceGte;
  final String? priceLte;
  final int? typeProduct;
  final String? categoryId;
  final int? countryId;

  const _ProductsSection({
    required this.state,
    required this.choseOwner,
    required this.scrollController,
    required this.lists,
    required this.indexSort,
    required this.search,
    required this.priceGte,
    required this.priceLte,
    required this.typeProduct,
    required this.categoryId,
    required this.countryId,
  });

  @override
  Widget build(BuildContext context) {
    final total = state.postModel?.count ?? 0;

    if (state.isLoading && state.products.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 30),
        child: ShimmerProductGrid(itemCount: 6),
      );
    }

    if (!state.isLoading && total == 0 && state.products.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Center(
          child: Column(
            children: [
              const Icon(Icons.search_off, size: 46, color: Colors.grey),
              SizedBox(height: 12.h),
              const TextTranslated(
                'Товары по вашему запросу не найдены',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 6.h),
              const TextTranslated(
                'Попробуйте изменить фильтры или категорию/страну',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const TextTranslated(
          "Товары",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        SizedBox(height: 12.h),
        GridView.builder(
          primary: false,
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 230,
            mainAxisSpacing: 18,
            crossAxisSpacing: 10,
            childAspectRatio: (MediaQuery.sizeOf(context).width * .2) / 170,
          ),
          itemCount: state.products.length,
          itemBuilder: (ctx, index) {
            final product = state.products[index];
            return RepaintBoundary(
              child: MaybePromotedCard(
                postId: product.id,
                isPromoted: product.isPromoted,
                promoEndAt: product.promoEndAt,
                placement: PromotionPlacement.search,
                child: ProductCard(
                  key: ValueKey(product.id),
                  results: product,
                  chooseMain: choseOwner,
                ),
              ),
            );
          },
        ),
        // Seamless pagination: next pages append while scrolling (the screen
        // is wrapped in InfiniteScrollRegion); this is just the indicator.
        LoadMoreIndicator(isLoading: state.isLoadingPaginate),
      ],
    );
  }
}

class _UserGridCard extends StatelessWidget {
  final User user;
  final bool isDarkMode;
  final VoidCallback onTap;

  const _UserGridCard({
    required this.user,
    required this.isDarkMode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final avatarUrl =
        (user.image == null) ? null : user.image.toString().trim();
    final hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Material(
        borderRadius: BorderRadius.circular(10),
        elevation: 6,
        color: isDarkMode ? const Color(0xff0e1e33) : Colors.white,
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 140.h,
              width: double.infinity,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    fit: BoxFit.cover,
                    image: hasAvatar
                        ? CachedNetworkImageProvider(avatarUrl)
                        : const AssetImage('assets/noImageUser.png')
                            as ImageProvider,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextTranslated(
                      user.username,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.star,
                            size: 14, color: Color(0xffFFA800)),
                        const SizedBox(width: 6),
                        Text(
                          user.rating.toStringAsFixed(1),
                          style: const TextStyle(fontSize: 13),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '(${user.reviewsCount})',
                          style:
                              const TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                      ],
                    ),
                    const Spacer(),
                    const Align(
                      alignment: Alignment.bottomRight,
                      child: Icon(Icons.chevron_right, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
