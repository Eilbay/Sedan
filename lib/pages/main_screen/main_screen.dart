import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:optombai/widgets/product/market_product_card.dart';
import 'package:optombai/widgets/product/product_peek_card.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:optombai/core/di/injection.dart';
import 'package:optombai/l10n/tr.dart';
import 'package:optombai/tour/controller/tour_controller.dart';
import 'package:optombai/tour/tour_actions.dart';
import 'package:optombai/tour/widget/multi_tour_overlay.dart';
import 'package:optombai/widgets/app_scaffold/bazarlar_app_scaffold.dart';
import 'package:optombai/widgets/promotion/maybe_promoted_card.dart';
import 'package:optombai/widgets/promotion/promotion_placement.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:optombai/core/appColors.dart';
import 'package:optombai/core/import_links.dart';
import 'package:optombai/data/models/countries/countries.dart';
import 'package:optombai/app/router/app_router.dart';
import 'package:optombai/widgets/product/choose_cards.dart';
import 'package:optombai/widgets/shimmer/shimmer_category_strip.dart';
import 'package:optombai/widgets/shimmer/shimmer_product_grid.dart';
import 'package:optombai/widgets/translation/text_translated.dart';
import 'package:optombai/core/country_flags.dart';
import 'package:optombai/widgets/common/rating_stars.dart';
import 'package:optombai/widgets/common/pagination_widget.dart';
import 'package:optombai/widgets/common/upload_progress_banner.dart';
import 'package:optombai/widgets/utils/dropdown/home_dropdown.dart';
import 'package:optombai/widgets/bottom_nav.dart';
import 'package:auto_route/auto_route.dart';

@RoutePage()
class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class SortModel {
  final String text;
  final String? value;
  const SortModel(this.text, this.value);
}

class _HomePageState extends State<HomePage>
    with AutomaticKeepAliveClientMixin {
  static const bool _showTypeTiles = false;
  static const bool _showFilters = false;

  static const Color _accent = Color(0xFF2F80ED);

  final _kGoods = GlobalKey();
  final _kManufacturers = GlobalKey();
  final _kSuppliers = GlobalKey();

  final _kOrders = GlobalKey();
  final _kBuyers = GlobalKey();

  static const int _tourTotalStep0 = 7;
  static const int _tourTotalStep1 = 2;

  final _aSearch = GlobalKey();
  final _aFilters = GlobalKey();
  final _aFirstProduct = GlobalKey();

  final _sSearch = GlobalKey();
  final _sFilters = GlobalKey();
  final _sFirstProduct = GlobalKey();

  @override
  bool get wantKeepAlive => true;
  final ScrollController _controller = ScrollController();

  Timer _debounce = Timer(Duration.zero, () {});

  bool _hasUserSelectedType = false;

  String? categoryId;
  String? search;
  String? priceGte;
  String? priceLte;
  int? choseMain;
  int? choseOwner;
  int? countryId;
  int indexSort = 0;

  final List<SortModel> _sortOptions = const [
    SortModel("Не указaно", null),
    SortModel("Сначала дешевле", "price"),
    SortModel("Сначала дороже", "-price"),
    SortModel("Сначала новые", "-created_at"),
    SortModel("Выше рейтинг", "-rating"),
  ];

  double _screenWidth = 0;

  bool _initialFetched = false;

  static const String _feedLayoutPrefKey = 'home_feed_grid_layout';

  bool _isGridLayout =
      getIt<SharedPreferences>().getBool(_feedLayoutPrefKey) ?? true;

  void _setFeedLayout(bool isGrid) {
    if (isGrid == _isGridLayout) return;
    setState(() => _isGridLayout = isGrid);
    getIt<SharedPreferences>().setBool(_feedLayoutPrefKey, isGrid);
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_initialFetched) return;
      _initialFetched = true;
      _startInitialLoading();
    });
  }

  TourController? _tourController;
  int? _lastStep;

  int? _pendingStep;
  bool _pendingScheduled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _screenWidth = MediaQuery.sizeOf(context).width;

    final tc = context.read<TourController>();
    if (_tourController != tc) {
      _tourController?.removeListener(_onTourChanged);
      _tourController = tc;
      _tourController!.addListener(_onTourChanged);
    }
  }

  @override
  void dispose() {
    _tourController?.removeListener(_onTourChanged);
    _controller.dispose();
    _debounce.cancel();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    final productBloc = context.read<ProductBloc>();

    productBloc.add(ProductWithFilter(
      priceGte: priceGte != null && priceGte!.trim().isNotEmpty
          ? double.tryParse(priceGte!.replaceAll(',', '.'))?.toString()
          : null,
      priceLte: priceLte != null && priceLte!.trim().isNotEmpty
          ? double.tryParse(priceLte!.replaceAll(',', '.'))?.toString()
          : null,
      search: search,
      ordering: _sortOptions[indexSort].value,
      typeProduct: null,
      typeOwner: choseOwner,
      category: categoryId,
      countryId: countryId,
      forceRefresh: true,
    ));

    context.read<ProductBloc>().add(FetchPostsStatsEvent());

    await productBloc.stream.firstWhere((s) => !s.isLoading).timeout(
        const Duration(seconds: 10),
        onTimeout: () => productBloc.state);
  }

  void _onTourChanged() {
    final tour = _tourController!;
    if (!mounted) return;

    if (!tour.isRunning) {
      _lastStep = null;
      _pendingStep = null;
      _pendingScheduled = false;
      MultiTourOverlay.hide();
      return;
    }

    if (_lastStep == tour.stepIndex) return;
    _lastStep = tour.stepIndex;

    setState(() {
      _pendingStep = tour.stepIndex;
      _pendingScheduled = false;
    });
  }

  Future<bool> _waitPageActive(Duration timeout) async {
    final deadline = DateTime.now().add(timeout);

    while (DateTime.now().isBefore(deadline)) {
      if (!mounted) return false;

      final isTickerOn = TickerMode.of(context);
      final route = ModalRoute.of(context);
      final isCurrent = route == null || route.isCurrent;

      if (isTickerOn && isCurrent) return true;

      await WidgetsBinding.instance.endOfFrame;
    }
    return false;
  }

  Future<void> _runTourStep(int step) async {
    if (!mounted) return;

    final active = await _waitPageActive(const Duration(seconds: 12));
    if (!active) {
      debugPrint('[TOUR] step=$step page not active (timeout)');
      return;
    }

    await WidgetsBinding.instance.endOfFrame;

    switch (step) {
      case 0:
        _tryShowStep0Overlay();
        return;

      case 1:
        _tryShowStep1Overlay();
        return;

      case 2:
        {
          MultiTourOverlay.hide();

          final anchorCtx = await _waitAnchorContext(
            _aSearch,
            timeout: const Duration(seconds: 12),
          );
          if (anchorCtx == null) {
            debugPrint('[TOUR] step=2 _aSearch ctx is NULL (timeout)');
            return;
          }

          await Scrollable.ensureVisible(
            anchorCtx,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            alignment: 0.1,
          );

          await WidgetsBinding.instance.endOfFrame;
          await WidgetsBinding.instance.endOfFrame;

          if (!mounted || _tourController?.isRunning != true) return;
          ShowcaseView.get().startShowCase([_sSearch]);
          return;
        }

      case 3:
        {
          if (!_showFilters) {
            debugPrint('[TOUR] step=3 skipped — filters hidden');
            return;
          }

          MultiTourOverlay.hide();

          final anchorCtx = await _waitAnchorContext(
            _aFilters,
            timeout: const Duration(seconds: 12),
          );
          if (anchorCtx == null) {
            debugPrint('[TOUR] step=3 _aFilters ctx is NULL (timeout)');
            return;
          }

          await Scrollable.ensureVisible(
            anchorCtx,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            alignment: 0.1,
          );

          await WidgetsBinding.instance.endOfFrame;
          await WidgetsBinding.instance.endOfFrame;

          if (!mounted || _tourController?.isRunning != true) return;
          ShowcaseView.get().startShowCase([_sFilters]);
          return;
        }

      case 4:
        {
          MultiTourOverlay.hide();

          final anchorCtx = await _waitAnchorContext(
            _aFirstProduct,
            timeout: const Duration(seconds: 20),
          );
          if (anchorCtx == null) {
            debugPrint('[TOUR] step=4 _aFirstProduct ctx is NULL (timeout)');
            return;
          }

          await Scrollable.ensureVisible(
            anchorCtx,
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeInOut,
            alignment: 0.2,
          );

          await WidgetsBinding.instance.endOfFrame;
          await WidgetsBinding.instance.endOfFrame;

          if (!mounted || _tourController?.isRunning != true) return;
          ShowcaseView.get().startShowCase([_sFirstProduct]);
          return;
        }
    }
  }

  void _tryShowStep0Overlay() {
    if (!_showTypeTiles) {
      debugPrint('[TOUR] step0 skipped — type tiles hidden');
      return;
    }

    final keys = [_kGoods, _kManufacturers, _kSuppliers];
    final ready = keys.every((k) => k.currentContext != null);
    if (!ready) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _tryShowStep0Overlay();
      });
      return;
    }

    MultiTourOverlay.show(
      context: context,
      targetKeys: keys,
      text: tr(context, 'tour_step0_intro'),
      onNext: () => context.read<TourController>().nextStep(context),
    );
  }

  void _tryShowStep1Overlay() {
    if (!_showTypeTiles) {
      debugPrint('[TOUR] step1 skipped — type tiles hidden');
      return;
    }

    final keys = [_kOrders, _kBuyers];
    final ready = keys.every((k) => k.currentContext != null);
    if (!ready) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _tryShowStep1Overlay();
      });
      return;
    }

    MultiTourOverlay.show(
      context: context,
      targetKeys: keys,
      text: tr(context, 'tour_step1_intro'),
      onNext: () => context.read<TourController>().nextStep(context),
    );
  }

  void _startInitialLoading() {
    choseOwner = null;
    _hasUserSelectedType = false;

    // Pick default category: prefer "Одежда", fallback to first valid.
    final cs = context.read<CategoryBloc>().state;
    String? clothingId;
    String? firstValid;
    for (final cat in cs.categories) {
      final name = cat.name.trim().toLowerCase();
      if (cat.id.isEmpty ||
          name == 'другое' ||
          name.contains('статус') ||
          name.contains('склад')) {
        continue;
      }
      firstValid ??= cat.id;
      if (name == 'одежда') {
        clothingId = cat.id;
        break;
      }
    }
    categoryId = clothingId ?? firstValid;

    final ps = context.read<ProductBloc>().state;
    debugPrint(
        '[PRELOAD] HomePage._startInitialLoading — products=${ps.products.length} categories=${cs.categories.length} stats=${ps.stats != null} defaultCat=$categoryId');

    if (categoryId != null) {
      _fetchProductWithFilter();
    } else {
      debugPrint(
          '[PRELOAD] HomePage: skipping product fetch — waiting for categories');
    }

    if (cs.categories.isEmpty && !cs.isLoading) {
      debugPrint(
          '[PRELOAD] HomePage: categories empty & not loading, dispatching CategoryAllEvent');
      BlocProvider.of<CategoryBloc>(context).add(CategoryAllEvent());
    } else {
      debugPrint(
          '[PRELOAD] HomePage: categories already loaded/loading (${cs.categories.length}, loading=${cs.isLoading})');
    }
    final countryState = context.read<CountryBloc>().state;
    if (countryState.list.isEmpty) {
      BlocProvider.of<CountryBloc>(context).add(const CountryAllEvent());
    }

    if (!ps.isStatsLoading && ps.stats == null) {
      debugPrint(
          '[PRELOAD] HomePage: stats null, dispatching FetchPostsStatsEvent');
      context.read<ProductBloc>().add(FetchPostsStatsEvent());
    } else {
      debugPrint('[PRELOAD] HomePage: stats already loaded');
    }
  }

  void _onDebounceSearchOrFilter() {
    if (_debounce.isActive) _debounce.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      _fetchProductWithFilter();
    });
  }

  void _fetchProductWithFilter() {
    debugPrint(
        'HomePage _fetchProductWithFilter() hash=${identityHashCode(this)} owner=$choseOwner cat=$categoryId country=$countryId search=$search');

    final ordering = _sortOptions[indexSort].value;

    BlocProvider.of<ProductBloc>(context).add(ProductWithFilter(
      priceGte: priceGte != null && priceGte!.trim().isNotEmpty
          ? double.tryParse(priceGte!.replaceAll(',', '.'))?.toString()
          : null,
      priceLte: priceLte != null && priceLte!.trim().isNotEmpty
          ? double.tryParse(priceLte!.replaceAll(',', '.'))?.toString()
          : null,
      search: search,
      ordering: ordering,
      typeProduct: null,
      typeOwner: choseOwner,
      category: categoryId,
      countryId: countryId,
    ));
  }

  Future<BuildContext?> _waitAnchorContext(
    GlobalKey anchorKey, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final deadline = DateTime.now().add(timeout);

    while (DateTime.now().isBefore(deadline)) {
      if (!mounted) return null;

      final ctx = anchorKey.currentContext;
      if (ctx != null) {
        final ro = ctx.findRenderObject();
        if (ro is RenderBox && ro.attached && ro.hasSize) return ctx;
      }

      await WidgetsBinding.instance.endOfFrame;
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final tour = context.watch<TourController>();

    if (tour.isRunning && _pendingStep != null && !_pendingScheduled) {
      _pendingScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        final step = _pendingStep;
        if (step == null) return;

        _pendingScheduled = false;

        await _runTourStep(step);
      });
    }

    final isDarkMode = context.select((ThemeNotifier n) => n.isDarkMode);

    return BazarlarAppScaffold(
      onRefresh: _handleRefresh,
      child: BlocListener<CategoryBloc, CategoryState>(
        listenWhen: (previous, current) =>
            previous.categories.isEmpty && current.categories.isNotEmpty,
        listener: (context, catState) {
          if (categoryId == null) {
            String? firstValid;
            String? clothingId;
            for (final cat in catState.categories) {
              final name = cat.name.trim().toLowerCase();
              if (cat.id.isEmpty ||
                  name == 'другое' ||
                  name.contains('статус') ||
                  name.contains('склад')) {
                continue;
              }
              firstValid ??= cat.id;
              if (name == 'одежда') {
                clothingId = cat.id;
                break;
              }
            }
            final picked = clothingId ?? firstValid;
            if (picked != null) {
              setState(() => categoryId = picked);
              _fetchProductWithFilter();
            }
          }
        },
        child: BlocBuilder<ProductBloc, ProductState>(
          buildWhen: (previous, current) {
            return previous.products != current.products ||
                previous.isLoading != current.isLoading ||
                previous.isLoadingPaginate != current.isLoadingPaginate ||
                previous.currentPage != current.currentPage ||
                previous.totalPages != current.totalPages;
          },
          builder: (context, state) {
            final ordering = _sortOptions[indexSort].value;
            final isInitialLoading = state.products.isEmpty && state.isLoading;

            return Scrollbar(
              controller: _controller,
              thumbVisibility: true,
              thickness: 4,
              radius: const Radius.circular(4),
              child: CustomScrollView(
                controller: _controller,
                cacheExtent: 800,
                slivers: [
                  const SliverToBoxAdapter(
                    child: UploadProgressBanner(),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 10.h),
                          Container(
                            key: _aSearch,
                            child: Showcase.withWidget(
                              key: _sSearch,
                              container: TourTooltipWidget(
                                text: tr(context, 'tour_search'),
                                totalInThisScreen: 1,
                              ),
                              child: _SearchField(onChanged: (q) {
                                setState(() => search = q.isEmpty ? null : q);
                                _onDebounceSearchOrFilter();
                              }),
                            ),
                          ),
                          SizedBox(height: 8.h),
                          if (_showTypeTiles) ...[
                            _ChooseOwnerWidget(
                              onChanged: (owner) {
                                setState(() {
                                  choseOwner = owner;
                                  if (choseOwner == 0) {
                                    choseMain = 0;
                                  } else {
                                    choseMain = null;
                                  }
                                });
                                _onDebounceSearchOrFilter();
                              },
                              tourKeys: {
                                2: _kGoods,
                                8: _kManufacturers,
                                4: _kSuppliers,
                                0: _kOrders,
                                16: _kBuyers,
                              },
                              tourTotalStep0: _tourTotalStep0,
                              tourTotalStep1: _tourTotalStep1,
                            ),
                            SizedBox(height: 10.h),
                          ],
                          if (_showFilters) ...[
                            Container(
                              key: _aFilters,
                              child: Showcase.withWidget(
                                key: _sFilters,
                                container: TourTooltipWidget(
                                  text: tr(context, 'tour_filters'),
                                  totalInThisScreen: 1,
                                ),
                                child: _FilterRow(
                                  screenWidth: _screenWidth,
                                  productOptions: combinedListWithoutOrders,
                                  chosenMain: choseMain,
                                  chosenOwner: choseOwner,
                                  hasUserSelectedType: _hasUserSelectedType,
                                  onProductSelected: (value) {
                                    setState(() {
                                      _hasUserSelectedType = true;
                                      if (value == 4 || value == 8) {
                                        choseOwner = value;
                                        choseMain = null;
                                      } else {
                                        choseMain = value;
                                        choseOwner = null;
                                      }
                                    });
                                    _onDebounceSearchOrFilter();
                                  },
                                  selectedCountryId: countryId,
                                  onCountryChanged: (value) {
                                    setState(() => countryId = value);
                                    _onDebounceSearchOrFilter();
                                  },
                                  selectedCategoryId: categoryId,
                                  onCategoryChanged: (value) {
                                    setState(() => categoryId = value);
                                    _onDebounceSearchOrFilter();
                                  },
                                  onPriceFromChanged: (value) {
                                    setState(() => priceGte = value);
                                    _onDebounceSearchOrFilter();
                                  },
                                  onPriceToChanged: (value) {
                                    setState(() => priceLte = value);
                                    _onDebounceSearchOrFilter();
                                  },
                                  sortOptions: _sortOptions,
                                  selectedSortIndex: indexSort,
                                  onSortSelected: (newIndex) {
                                    setState(() => indexSort = newIndex);
                                    _onDebounceSearchOrFilter();
                                  },
                                ),
                              ),
                            ),
                            SizedBox(height: 14.h),
                          ],
                          _SectionHeader(
                            title: 'Категории',
                            actionText: 'Смотреть все',
                            onAction: () => BottomNav.of(context)?.setTab(1),
                          ),
                          SizedBox(height: 5.h),
                          const _CategoriesStrip(),
                          SizedBox(height: 5.h),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const TextTranslated(
                                'Все объявления',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w700),
                              ),
                              _FeedLayoutToggle(
                                isGridLayout: _isGridLayout,
                                onChanged: _setFeedLayout,
                              ),
                            ],
                          ),
                          SizedBox(height: 12.h),
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
                  else ...[
                    SliverPadding(
                      padding: const EdgeInsets.only(left: 15, right: 15),
                      sliver: _ProductsSliverGrid(
                        products: state.products,
                        isDarkMode: isDarkMode,
                        choseOwner: choseOwner,
                        screenWidth: _screenWidth,
                        isGridLayout: _isGridLayout,
                        tourTotalInThisScreen: _tourTotalStep0,
                        onTapOwner: (product) {
                          final String? countryName =
                              product.owner?.country?.name;
                          final String? flagPath = countryName != null
                              ? kCountryFlags[countryName]
                              : null;

                          context.router.push(OtherUserProfileRoute(
                            flagName: flagPath,
                            productType: product.postType != null
                                ? int.tryParse(product.postType!)
                                : null,
                            user: product.owner?.id ?? "",
                            username: product.owner?.username ?? "",
                          ));
                        },
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      sliver: SliverToBoxAdapter(
                        child: PaginationWidget(
                          currentPage: state.currentPage,
                          totalPages: state.totalPages,
                          isBusy: state.isLoadingPaginate,
                          onPageSelected: (page) {
                            _controller.animateTo(
                              410,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                            context
                                .read<ProductBloc>()
                                .add(ProductGoToPageEvent(
                                  page: page,
                                  limit: 20,
                                  search: search,
                                  priceGte: priceGte,
                                  priceLte: priceLte,
                                  ordering: ordering,
                                  typeProduct: 2,
                                  typeOwner: choseOwner,
                                  category: categoryId,
                                  countryId: countryId,
                                  owner: null,
                                  price: null,
                                  currency: null,
                                ));
                          },
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 20),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final void Function(String) onChanged;
  const _SearchField({required this.onChanged});
  @override
  Widget build(BuildContext context) {
    return CustomSearchField(
      focusBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Colors.grey),
      ),
      onChange: onChanged,
      onSubmit: (query) {
        context.router.push(ResultsRoute(
          initialSearch: query,
        ));
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String actionText;
  final VoidCallback onAction;
  const _SectionHeader({
    required this.title,
    required this.actionText,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TextTranslated(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        InkWell(
          onTap: onAction,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextTranslated(
                actionText,
                style: const TextStyle(
                  color: _HomePageState._accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Icon(Icons.chevron_right,
                  size: 18, color: _HomePageState._accent),
            ],
          ),
        ),
      ],
    );
  }
}

class _CategoriesStrip extends StatelessWidget {
  const _CategoriesStrip();

  @override
  Widget build(BuildContext context) {
    final isDark = context.select((ThemeNotifier n) => n.isDarkMode);

    return SizedBox(
      height: 108.h,
      child: BlocBuilder<CategoryBloc, CategoryState>(
        buildWhen: (p, c) =>
            p.categories != c.categories || p.isLoading != c.isLoading,
        builder: (context, state) {
          final cats = state.categories.where((cat) {
            final name = cat.name.trim().toLowerCase();
            return name != 'другое' &&
                !name.contains('статус') &&
                !name.contains('склад');
          }).toList();

          if (state.isLoading && cats.isEmpty) {
            return const ShimmerCategoryStrip();
          }

          return ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.zero,
            itemCount: cats.length,
            separatorBuilder: (_, __) => SizedBox(width: 10.w),
            itemBuilder: (ctx, i) {
              final c = cats[i];
              return GestureDetector(
                onTap: () {
                  if (c.children.isNotEmpty) {
                    context.router.push(SubcategoryRoute(
                      title: c.name,
                      children0: c.children,
                    ));
                  } else {
                    context.router.push(ProductsRoute(
                      childId: c.id,
                      title: c.name,
                    ));
                  }
                },
                child: SizedBox(
                  width: 72.w,
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: SizedBox(
                          width: 70.w,
                          height: 70.w,
                          child: c.icon.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: c.icon,
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) => Container(
                                    color: isDark
                                        ? Colors.grey[800]
                                        : const Color(0xFFF0F0F0),
                                  ),
                                  errorWidget: (_, __, ___) => Image.asset(
                                    'assets/card_image.png',
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : Image.asset(
                                  'assets/card_image.png',
                                  fit: BoxFit.cover,
                                ),
                        ),
                      ),
                      SizedBox(height: 6.h),
                      TextTranslated(
                        c.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _ChooseOwnerWidget extends StatelessWidget {
  final void Function(int?) onChanged;
  final Map<int, GlobalKey> tourKeys;
  final int tourTotalStep0;
  final int tourTotalStep1;

  const _ChooseOwnerWidget({
    required this.onChanged,
    required this.tourKeys,
    required this.tourTotalStep0,
    required this.tourTotalStep1,
  });

  @override
  Widget build(BuildContext context) {
    return CustomChoose(
      onFilterChanged: onChanged,
      tourKeys: tourKeys,
      tourTotalStep0: tourTotalStep0,
      tourTotalStep1: tourTotalStep1,
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
    final isDark = context.select((ThemeNotifier n) => n.isDarkMode);

    final child = Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isDark ? const Color(0xff1A2A42) : const Color(0xffCFDEFB),
            width: 1),
      ),
      alignment: Alignment.center,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextTranslated(
            sortOptions[selectedIndex].text,
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(width: 6),
          const Icon(Icons.arrow_drop_down, size: 18),
        ],
      ),
    );

    return child.addStarMenu(
      items: sortOptions.map((e) => TextTranslated(e.text)).toList(),
      onItemTapped: (newIndex, controller) {
        onSelected(newIndex);
        controller.closeMenu?.call();
      },
      params: StarMenuParameters.dropdown(context),
    );
  }
}

class _FilterRow extends StatelessWidget {
  final double screenWidth;

  final List<ChoseClass> productOptions;
  final int? chosenMain;
  final int? chosenOwner;
  final ValueChanged<int?> onProductSelected;

  final String? selectedCategoryId;

  final ValueChanged<String?> onCategoryChanged;
  final ValueChanged<String?> onPriceFromChanged;
  final ValueChanged<String?> onPriceToChanged;

  final int? selectedCountryId;
  final ValueChanged<int?> onCountryChanged;

  final bool hasUserSelectedType;

  final List<SortModel> sortOptions;
  final int selectedSortIndex;
  final ValueChanged<int> onSortSelected;

  const _FilterRow({
    required this.screenWidth,
    required this.productOptions,
    required this.chosenMain,
    required this.chosenOwner,
    required this.onProductSelected,
    required this.selectedCategoryId,
    required this.onCategoryChanged,
    required this.onPriceFromChanged,
    required this.onPriceToChanged,
    required this.hasUserSelectedType,
    required this.selectedCountryId,
    required this.onCountryChanged,
    required this.sortOptions,
    required this.selectedSortIndex,
    required this.onSortSelected,
  });

  @override
  Widget build(BuildContext context) {
    const int allTypesId = -1;

    final selectedValue =
        hasUserSelectedType ? (chosenOwner ?? chosenMain) : null;

    final typesList = <ChoseClass>[
      ChoseClass(id: allTypesId, name: 'Все типы'),
      ...productOptions,
    ];

    final isValid =
        selectedValue != null && typesList.any((e) => e.id == selectedValue);

    return SizedBox(
      height: 38.h,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          IntrinsicWidth(
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 120),
              child: HomeDropdown(
                list: typesList,
                value: isValid ? selectedValue : null,
                title: 'Все типы',
                titleSize: 14,
                itemSize: 14,
                onChanged: (v) {
                  onProductSelected(v == allTypesId ? null : v);
                },
              ),
            ),
          ),
          IntrinsicWidth(
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 120, maxWidth: 120),
              child: BlocBuilder<CountryBloc, CountryState>(
                buildWhen: (previous, current) => previous.list != current.list,
                builder: (context, state) {
                  final countries = <CountryModel>[
                    const CountryModel(id: 0, name: "Страна"),
                    ...state.list,
                  ];

                  return HomeDropdown(
                    title: "Страна",
                    titleSize: 14,
                    itemSize: 14,
                    list: countries,
                    value: selectedCountryId ?? 0,
                    onChanged: (v) => onCountryChanged(v == 0 ? null : v),
                  );
                },
              ),
            ),
          ),
          IntrinsicWidth(
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 120, maxWidth: 130),
              child: BlocBuilder<CategoryBloc, CategoryState>(
                buildWhen: (previous, current) =>
                    previous.categories != current.categories,
                builder: (context, state) {
                  final list = <Category>[
                    const Category(name: 'Категории'),
                    ...state.categories.where((cat) {
                      final name = cat.name.trim().toLowerCase();
                      return name != 'другое' &&
                          !name.contains('статус') &&
                          !name.contains('склад');
                    }),
                  ];

                  final hasValue = selectedCategoryId != null &&
                      list.any((cat) => cat.id == selectedCategoryId);

                  return HomeDropdown(
                    list: list,
                    value: hasValue ? selectedCategoryId : null,
                    onChanged: onCategoryChanged,
                    title: 'Категории',
                    titleSize: 14,
                    itemSize: 14,
                  );
                },
              ),
            ),
          ),
          _SortRow(
            sortOptions: sortOptions,
            selectedIndex: selectedSortIndex,
            onSelected: onSortSelected,
          ),
          SizedBox(width: 10.w),
          SizedBox(
            width: 100,
            child: FilterFields(hint: 'Цена от', onChange: onPriceFromChanged),
          ),
          SizedBox(width: 10.w),
          SizedBox(
            width: 100,
            child: FilterFields(hint: 'Цена до', onChange: onPriceToChanged),
          ),
        ],
      ),
    );
  }
}

/// Grid/list switch for the products section — two pill-shaped icon buttons,
/// active one filled with the brand accent.
class _FeedLayoutToggle extends StatelessWidget {
  const _FeedLayoutToggle({
    required this.isGridLayout,
    required this.onChanged,
  });

  final bool isGridLayout;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final bool isDark = context.select((ThemeNotifier n) => n.isDarkMode);
    final Color trackColor =
        isDark ? const Color(0xFF1C1C1E) : const Color(0xFFEAF1FC);

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: trackColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _FeedLayoutToggleButton(
            icon: Icons.grid_view_rounded,
            isSelected: isGridLayout,
            onTap: () => onChanged(true),
          ),
          _FeedLayoutToggleButton(
            icon: Icons.view_list_rounded,
            isSelected: !isGridLayout,
            onTap: () => onChanged(false),
          ),
        ],
      ),
    );
  }
}

class _FeedLayoutToggleButton extends StatelessWidget {
  const _FeedLayoutToggleButton({
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isSelected ? _HomePageState._accent : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: 18,
          color: isSelected ? Colors.white : Colors.grey,
        ),
      ),
    );
  }
}

class _ProductsSliverGrid extends StatelessWidget {
  final List<Product> products;
  final bool isDarkMode;
  final int? choseOwner;
  final double screenWidth;
  final bool isGridLayout;
  final void Function(Product) onTapOwner;
  final int tourTotalInThisScreen;

  const _ProductsSliverGrid({
    required this.products,
    required this.isDarkMode,
    required this.choseOwner,
    required this.screenWidth,
    required this.isGridLayout,
    required this.onTapOwner,
    required this.tourTotalInThisScreen,
  });

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    if (isGridLayout && choseOwner != 1024) {
      return SliverPadding(
        padding: EdgeInsets.only(bottom: 16.h),
        sliver: SliverGrid(
          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 230,
            mainAxisSpacing: 18,
            crossAxisSpacing: 10,
            mainAxisExtent: choseOwner != null ? 265 : 285,
          ),
          delegate: SliverChildBuilderDelegate(
            (_, index) {
              final product = products[index];
              return RepaintBoundary(
                child: MarketProductCard(
                  key: ValueKey(product.id),
                  results: product,
                  chooseMain: choseOwner,
                ),
              );
            },
            childCount: products.length,
            addAutomaticKeepAlives: false,
            addSemanticIndexes: false,
          ),
        ),
      );
    }

    return SliverPadding(
      padding: EdgeInsets.only(bottom: 16.h),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (_, index) {
            final product = products[index];

            if (choseOwner == 1024) {
              return GestureDetector(
                onTap: () => onTapOwner(product),
                child: Material(
                  borderRadius: BorderRadius.circular(10),
                  elevation: 4,
                  color: isDarkMode ? AppColors.black : AppColors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 180.h,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            fit: BoxFit.fill,
                            image: product.owner?.image != null
                                ? CachedNetworkImageProvider(
                                    product.owner!.image)
                                : const AssetImage('assets/notfound.png')
                                    as ImageProvider,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
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
                                RatingStars(rating: product.owner!.rating),
                                SizedBox(width: 10.w),
                                TextTranslated(
                                  product.owner!.reviewsCount.toString(),
                                  maxLines: 1,
                                  overflow: TextOverflow.fade,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                if (product.owner!.userStatus!.isPremium)
                                  Image(
                                    image: const AssetImage('assets/logo2.png'),
                                    width: 20.w,
                                    height: 20.h,
                                  ),
                                SizedBox(width: 5.w),
                                if (product.owner!.userStatus!.isActive)
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
            }
            final card = Padding(
              padding: EdgeInsets.only(bottom: 14.h),
              child: RepaintBoundary(
                child: MaybePromotedCard(
                  postId: product.id,
                  isPromoted: product.isPromoted,
                  promoEndAt: product.promoEndAt,
                  placement: PromotionPlacement.main,
                  child: ProductPeekCard(
                    key: ValueKey(product.id),
                    product: product,
                    chooseMain: choseOwner,
                  ),
                ),
              ),
            );

            final homeState = context.findAncestorStateOfType<_HomePageState>();
            if (index == 0 && homeState != null) {
              return Container(
                key: homeState._aFirstProduct,
                child: Showcase.withWidget(
                  key: homeState._sFirstProduct,
                  container: TourTooltipWidget(
                    text: tr(context, 'tour_open_product'),
                    totalInThisScreen: 1,
                  ),
                  child: card,
                ),
              );
            }

            return card;
          },
          childCount: products.length,
          addAutomaticKeepAlives: false,
          addRepaintBoundaries: true,
          addSemanticIndexes: false,
        ),
      ),
    );
  }
}
