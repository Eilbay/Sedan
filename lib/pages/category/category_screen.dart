import 'package:cached_network_image/cached_network_image.dart';
import 'package:optombai/bloc/category_bloc/category_bloc.dart';
import 'package:optombai/widgets/app_scaffold/bazarlar_app_scaffold.dart';
import 'package:optombai/widgets/shimmer/shimmer_product_grid.dart';
import 'package:optombai/bloc/product_bloc/product_bloc.dart';
import 'package:optombai/pages/main_screen/main_screen.dart';
import 'package:optombai/app/router/app_router.dart';
import 'package:optombai/widgets/app_scaffold/app_scaffold.dart';
import 'package:optombai/widgets/bottom_nav.dart';
import 'package:optombai/widgets/translation/text_translated.dart';
import 'package:optombai/widgets/utils/fields/custom_search_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:optombai/core/theme_notifier.dart';
import 'package:auto_route/auto_route.dart';
import 'package:optombai/data/models/category/category_model.dart';

@RoutePage()
class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key, this.showBottomNav = true, this.choseOwner});

  final List<Category> categories = const [];
  final bool showBottomNav;
  final int? choseOwner;

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  List<SortModel> lists = [
    const SortModel("Не указaно", null),
    const SortModel("Сначала дешевле", "price"),
    const SortModel("Сначала дороже", "-price"),
    const SortModel("Сначала новые", "created_at"),
    const SortModel("Выше рейтинг", "-rating"),
  ];

  @override
  void initState() {
    BlocProvider.of<CategoryBloc>(context).add(CategoryAllEvent());
    super.initState();
  }

  String? categoryId;
  int indexSort = 0;
  String? priceGte;
  String? priceLte;
  String? search;
  int? choseMain;
  int? choseOwner;
  int? countryId;

  void fetchProductWithFilter() {
    final ordering = lists[indexSort].value;

    choseMain ??= 2;

    BlocProvider.of<ProductBloc>(context).add(ProductWithFilter(
      search: search,
      priceGte: (priceGte?.trim().isEmpty ?? true) ? null : priceGte,
      priceLte: (priceLte?.trim().isEmpty ?? true) ? null : priceLte,
      ordering: (ordering?.trim().isEmpty ?? true) ? null : ordering,
      typeProduct: choseMain,
      typeOwner: choseOwner,
      category: categoryId,
      countryId: countryId,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return BazarlarAppScaffold(
      bottomNavigationBar: widget.showBottomNav
          ? const BottomNav(
              currentIndexOverride: -2,
              passive: true,
            )
          : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              CustomSearchField(
                focusBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
                onSubmit: (query) {
                  context.router.push(ResultsRoute(
                    initialSearch: query,
                  ));
                },
                onChange: (value) {
                  setState(() {
                    search = value;
                  });
                  fetchProductWithFilter();
                },
              ),
              const SizedBox(height: 10),
              const TextTranslated(
                "Категории",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: BlocBuilder<CategoryBloc, CategoryState>(
                  buildWhen: (previous, current) =>
                      previous.categories != current.categories ||
                      previous.isLoading != current.isLoading,
                  builder: (context, state) {
                    if (state.isLoading && state.categories.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.only(top: 20),
                        child: ShimmerProductGrid(itemCount: 6),
                      );
                    }
                    final isDark = context.select(
                      (ThemeNotifier n) => n.isDarkMode,
                    );
                    final filteredCategories = state.categories
                        .where((category) =>
                            !category.name.toLowerCase().contains('статус'))
                        .toList();
                    return GridView.builder(
                      primary: false,
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 150,
                        mainAxisSpacing: 5,
                        childAspectRatio: 150 / 200,
                        crossAxisSpacing: 10,
                      ),
                      itemCount: filteredCategories.length,
                      itemBuilder: (BuildContext ctx, index) {
                        final category = filteredCategories[index];
                        return GestureDetector(
                          onTap: () {
                            if (category.children.isNotEmpty) {
                              context.router.push(SubcategoryRoute(
                                title: category.name,
                                children0: category.children,
                              ));
                            } else {
                              context.router.push(ProductsRoute(
                                childId: category.id,
                                title: category.name,
                              ));
                            }
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: isDark ? Colors.grey[900] : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark
                                    ? Colors.grey[700]!
                                    : Colors.grey[300]!,
                                width: 0.5,
                              ),
                              boxShadow: isDark
                                  ? null
                                  : [
                                      BoxShadow(
                                        color: Colors.black
                                            .withValues(alpha: 0.06),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: AspectRatio(
                                    aspectRatio: 1,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: category.icon.isNotEmpty
                                          ? CachedNetworkImage(
                                              imageUrl: category.icon,
                                              fit: BoxFit.cover,
                                              memCacheWidth: (150 *
                                                      MediaQuery.of(context)
                                                          .devicePixelRatio)
                                                  .round(),
                                              memCacheHeight: (150 *
                                                      MediaQuery.of(context)
                                                          .devicePixelRatio)
                                                  .round(),
                                              placeholder: (_, __) => Container(
                                                color: isDark
                                                    ? Colors.grey[800]
                                                    : const Color(0xFFF0F0F0),
                                                child: Center(
                                                  child: Icon(
                                                    Icons.image_outlined,
                                                    color: Colors.grey[400],
                                                    size: 28,
                                                  ),
                                                ),
                                              ),
                                              errorWidget: (_, __, ___) =>
                                                  Image.asset(
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
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 6,
                                  ),
                                  child: TextTranslated(
                                    category.name,
                                    softWrap: false,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}
