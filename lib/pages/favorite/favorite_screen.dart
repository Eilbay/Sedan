// TODO: This screen will be replaced by CartScreen when cart API is implemented
// Current favorite functionality is preserved for backward compatibility
// The tab in bottom_nav.dart now shows CartScreen instead of this screen

import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:animated_tree_view/tree_view/tree_node.dart';
import 'package:optombai/widgets/app_scaffold/bazarlar_app_scaffold.dart';
import 'package:optombai/widgets/app_scaffold/custom_scaffold.dart';
import 'package:optombai/widgets/bottom_nav.dart';
import 'package:optombai/widgets/shimmer/shimmer_product_grid.dart';
import 'package:animated_tree_view/tree_view/tree_view.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:optombai/bloc/favorite_bloc/favorite_bloc.dart';
import 'package:optombai/bloc/user_bloc/user_bloc.dart';
import 'package:optombai/data/models/favorite/favorite_model.dart';
import 'package:optombai/core/theme_notifier.dart';
import 'package:optombai/widgets/translation/text_translated.dart';
import 'package:optombai/widgets/utils/buttons/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:star_menu/star_menu.dart';
import 'package:optombai/bloc/category_bloc/category_bloc.dart';
import 'package:optombai/bloc/country_bloc/country_bloc.dart';
import 'package:optombai/bloc/country_bloc/country_event.dart';
import 'package:optombai/bloc/country_bloc/country_state.dart';
import 'package:optombai/data/models/category/category_model.dart';
import 'package:optombai/data/models/countries/countries.dart';
import 'package:optombai/widgets/product/favorite_card.dart';
import 'package:optombai/widgets/utils/card/empty_product_card.dart';
import 'package:optombai/widgets/utils/dropdown/product_dropdown.dart';
import 'package:optombai/widgets/utils/fields/filter_fields.dart';
import 'package:auto_route/auto_route.dart';
import 'package:optombai/app/router/app_router.dart';
import 'package:optombai/pages/add_product/product_type_config.dart';

@RoutePage()
class FavoriteScreen extends StatefulWidget {
  const FavoriteScreen({super.key});

  @override
  State<FavoriteScreen> createState() => _FavoriteScreenState();
}

class SortModel {
  final String text;
  final String? value;

  SortModel(this.text, this.value);
}

class _FavoriteScreenState extends State<FavoriteScreen> {
  String name = '';

  List<SortModel> list = [
    SortModel("Не указaно", null),
    SortModel("Сначала дешевле", "post__price"),
    SortModel("Сначала дороже", "-post__price"),
    SortModel("Сначала новые", "-post__created_at"),
    SortModel("Выше рейтинг", "-post__rating"),
  ];

  @override
  void initState() {
    var userId = context.read<UserBloc>().state.user.id;
    BlocProvider.of<FavoriteBloc>(context)
        .add(FavoriteAllEvent(post_owner: userId, name: name));
    choseMain ??= 2;
    fetchProductWithFilter();
    BlocProvider.of<CountryBloc>(context).add(const CountryAllEvent());
    BlocProvider.of<CategoryBloc>(context).add(CategoryAllEvent());

    super.initState();
  }

  Timer _debounce = Timer(Duration.zero, () {});

  _onDebounce() {
    if (_debounce.isActive != false) {
      _debounce.cancel();
    }

    _debounce = Timer(const Duration(milliseconds: 500), () {
      fetchProductWithFilter();
    });
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
    final rawOrdering = list[indexSort].value;
    final ordering = (rawOrdering?.trim().isEmpty ?? true) ? null : rawOrdering;

    BlocProvider.of<FavoriteBloc>(context).add(FavoriteWithFilter(
      search: search,
      priceGte: (priceGte?.trim().isEmpty ?? true) ? null : priceGte,
      priceLte: (priceLte?.trim().isEmpty ?? true) ? null : priceLte,
      ordering: ordering,
      category: categoryId,
      country: countryId,
      productType: choseMain,
    ));
  }

  var sampleTree = TreeNode.root();

  List<TreeNode> getTreeNodes(List<Category> list) {
    List<TreeNode> listTreeMode = [];

    for (var element in list) {
      if (element.children.isNotEmpty) {
        var treeList = getTreeNodes(element.children);
        listTreeMode
            .add(TreeNode(key: element.id, data: element)..addAll(treeList));
      } else {
        listTreeMode.add(TreeNode(key: element.id, data: element));
      }
    }

    return listTreeMode;
  }

  @override
  Widget build(BuildContext context) {
    bool stateSwitch = context.select((ThemeNotifier n) => n.isDarkMode);

    return CustomScaffold(
      title: 'Сохраненные',
      bottomNavigationBar:
          const BottomNav(currentIndexOverride: -1, passive: true),
      child: SingleChildScrollView(
          child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 15.h,
                    ),
                    const TextTranslated(
                      "Сохраненные",
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
                    ),
                    SizedBox(
                      height: 20.h,
                    ),
                    BlocConsumer<CategoryBloc, CategoryState>(
                      listener: (context, state) {
                        if (state.categories.isNotEmpty) {
                          sampleTree = TreeNode.root()
                            ..addAll(getTreeNodes(state.categories));
                        }
                      },
                      builder: (context, state) {
                        return Card(
                          color: stateSwitch
                              ? const Color(0xff061324)
                              : Colors.white,
                          margin: EdgeInsets.zero,
                          child: ListTile(
                            visualDensity: VisualDensity.compact,
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (_) => AlertDialog(
                                  backgroundColor: stateSwitch
                                      ? const Color(0xff061324)
                                      : Colors.white,
                                  title: const TextTranslated("Категория"),
                                  insetPadding: const EdgeInsets.symmetric(
                                      horizontal: 10),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 10),
                                  content: SizedBox(
                                    width: double.maxFinite,
                                    height:
                                        MediaQuery.sizeOf(context).height * .5,
                                    child: CustomScrollView(
                                      slivers: [
                                        SliverTreeView.simple(
                                          tree: sampleTree,
                                          onTreeReady: (controller) {
                                            controller
                                                .expandAllChildren(sampleTree);
                                          },
                                          builder: (context, node) {
                                            Category category = (node.data ??
                                                    const Category(
                                                        name: "Все категории"))
                                                as Category;
                                            return Padding(
                                              padding: const EdgeInsets.only(
                                                  bottom: 8.0),
                                              child: ListTile(
                                                onTap: () {
                                                  setState(() {
                                                    categoryId = category.id;
                                                  });
                                                  fetchProductWithFilter();
                                                  context.router.maybePop();
                                                },
                                                leading: category.icon.isEmpty
                                                    ? const Icon(Icons.category)
                                                    : ClipRRect(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8),
                                                        child:
                                                            CachedNetworkImage(
                                                          imageUrl:
                                                              category.icon,
                                                          width: 55.w,
                                                          height: 55.h,
                                                          fit: BoxFit.cover,
                                                          memCacheWidth: (55.w *
                                                                  MediaQuery.of(
                                                                          context)
                                                                      .devicePixelRatio)
                                                              .round(),
                                                          memCacheHeight: (55
                                                                      .h *
                                                                  MediaQuery.of(
                                                                          context)
                                                                      .devicePixelRatio)
                                                              .round(),
                                                          placeholder:
                                                              (_, __) =>
                                                                  SizedBox(
                                                            width: 55.w,
                                                            height: 55.h,
                                                            child: const Center(
                                                              child:
                                                                  CircularProgressIndicator(
                                                                      strokeWidth:
                                                                          2),
                                                            ),
                                                          ),
                                                          errorWidget: (_, __,
                                                                  ___) =>
                                                              const Icon(Icons
                                                                  .category),
                                                        ),
                                                      ),
                                                title: TextTranslated(
                                                    category.name),
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                  actions: [
                                    InkWell(
                                      onTap: () {
                                        context.router.maybePop();
                                      },
                                      child: const Row(
                                        children: [
                                          Icon(Icons.arrow_back_ios, size: 15),
                                          TextTranslated("Назад")
                                        ],
                                      ),
                                    )
                                  ],
                                ),
                              );
                            },
                            title: TextTranslated(
                                "Категория: ${state.categories.firstWhere((element) => element.id == categoryId, orElse: () => const Category()).name}"),
                            trailing: const Icon(Icons.arrow_forward),
                          ),
                        );
                      },
                    ),
                    SizedBox(
                      height: 15.h,
                    ),
                    Row(
                      children: [
                        const TextTranslated(
                          "Сортировка по:   ",
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey),
                        ),
                        TextTranslated(
                          list[indexSort].text,
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.blue),
                        ),
                        const Expanded(
                          child: SizedBox(),
                        ),
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.tune),
                        ).addStarMenu(
                            items: list
                                .map((e) => TextTranslated(e.text))
                                .toList(),
                            onItemTapped: (index, controller) {
                              setState(() {
                                indexSort = index;
                              });
                              fetchProductWithFilter();
                              controller.closeMenu!();
                            },
                            params: StarMenuParameters.dropdown(context)),
                      ],
                    ),
                    SizedBox(
                      height: 8.h,
                    ),
                    /*SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: MediaQuery.sizeOf(context).width * .4,
                            child: CustomDropdown(
                                onChanged: (value) {
                                  setState(() {
                                    choseMain = value;
                                  });
                                  fetchProductWithFilter();
                                },
                                list: listMainPostTypeFavorite,
                                value: choseMain,
                                title: "Все",
                                titleSize: 16,
                                itemSize: 17),
                          ),
                          SizedBox(
                            width: 8.w,
                          ),
                          SizedBox(
                              width: MediaQuery.sizeOf(context).width * .4,
                              child: BlocBuilder<CountryBloc, CountryState>(
                                  buildWhen: (previous, current) =>
                                      previous.list != current.list,
                                  builder: (context, state) {
                                    var list = [
                                      const CountryModel(
                                          name: "Все страны", flag: "")
                                    ];
                                    list.addAll(state.list);

                                    return CustomDropdown(
                                        onChanged: (value) {
                                          setState(() {
                                            countryId = value;
                                          });
                                          fetchProductWithFilter();
                                        },
                                        list: list,
                                        value: countryId,
                                        title: "Страны",
                                        titleSize: 16,
                                        itemSize: 17);
                                  })),
                          SizedBox(
                            width: 8.w,
                          ),
                          SizedBox(
                            width: MediaQuery.sizeOf(context).width * .4,
                            child: FilterFields(
                              hint: "Цена от",
                              onChange: (value) {
                                setState(() {
                                  priceGte = value;
                                });
                                _onDebounce();
                              },
                            ),
                          ),
                          SizedBox(
                            width: 8.w,
                          ),
                          SizedBox(
                            width: MediaQuery.sizeOf(context).width * .4,
                            child: FilterFields(
                              hint: "Цена до",
                              onChange: (value) {
                                setState(() {
                                  priceLte = value;
                                });
                                _onDebounce();
                              },
                            ),
                          )
                        ],
                      ),
                    ),*/
                    SizedBox(height: 30.h),
                    BlocBuilder<FavoriteBloc, FavoriteState>(
                        buildWhen: (previous, current) =>
                            previous.results != current.results ||
                            previous.isLoading != current.isLoading,
                        builder: (context, state) {
                          if (state.isLoading && state.results.isEmpty) {
                            return const ShimmerProductGrid(itemCount: 4);
                          }
                          if (state.results.isEmpty) {
                            return Center(
                              child: EmptyProductCard(
                                title: 'В корзине пока что пусто!',
                                subTitle: "Корзина ждет, что ее наполнят",
                                width: 340.w,
                                height: 230.h,
                                image: "assets/icons/korzinka.png",
                                child: Center(
                                  child: SizedBox(
                                    width: 260.w,
                                    child: Theme(
                                      data: Theme.of(context).copyWith(
                                        textTheme: Theme.of(context)
                                            .textTheme
                                            .copyWith(
                                              labelLarge:
                                                  const TextStyle(fontSize: 14),
                                            ),
                                      ),
                                      child: CustomButton(
                                        title: 'Перейти в каталог',
                                        onPressed: () {
                                          context.router
                                              .replaceAll([BottomNavRoute()]);
                                        },
                                        borderRadius: 20,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }
                          List<FavoriteResult> filteredProducts = state.results;
                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: filteredProducts.length,
                            itemBuilder: (context, index) {
                              final product = filteredProducts[index];
                              return RepaintBoundary(
                                child: FavoriteCard(
                                  key: ValueKey(product.id),
                                  results: product,
                                  onPressed: () {
                                    BlocProvider.of<FavoriteBloc>(context)
                                        .add(FavoriteDelete(id: product.id));
                                  },
                                ),
                              );
                            },
                          );
                        })
                  ]))),
    );
  }
}
