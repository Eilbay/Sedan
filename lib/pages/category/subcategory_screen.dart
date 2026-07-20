import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:optombai/widgets/app_scaffold/custom_scaffold.dart';
import 'package:optombai/app/router/app_router.dart';
import 'package:optombai/widgets/bottom_nav.dart';
import 'package:optombai/widgets/translation/text_translated.dart';
import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import 'package:optombai/data/models/category/category_model.dart';

@RoutePage()
class SubcategoryScreen extends StatelessWidget {
  const SubcategoryScreen(
      {super.key, required this.children, required this.title});

  final List<Category> children;
  final String title;

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      bottomNavigationBar: const BottomNav(
        currentIndexOverride: -2,
        passive: true,
      ),
      title: title,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                height: 27.h,
              ),
              children.isEmpty
                  ? Container(
                      padding: const EdgeInsets.symmetric(vertical: 100),
                      alignment: Alignment.center,
                      child: Column(
                        children: [
                          const TextTranslated(
                            " Под категории пока пусто! :)",
                            style: TextStyle(fontSize: 20, color: Colors.grey),
                          ),
                          CachedNetworkImage(
                            imageUrl: "https://cdn-icons-png.flaticon.com/512/7486/7486744.png",
                            width: 280.w,
                            errorWidget: (_, __, ___) => const Icon(Icons.error),
                          )
                        ],
                      ),
                    )
                  : ListView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: children.length,
                      itemBuilder: (BuildContext ctx, index) {
                        return ListTile(
                          onTap: () {
                            if (children[index].children.isEmpty) {
                              context.router.push(ProductsRoute(
                                childId: children[index].id,
                                title: children[index].name,
                              ));
                              return;
                            }
                            context.router.push(SubcategoryRoute(
                              title: children[index].name,
                              children0: children[index].children,
                            ));
                          },
                          title: TextTranslated(children[index].name),
                          leading: children[index].icon.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: CachedNetworkImage(
                                    imageUrl: children[index].icon,
                                    width: 45.w,
                                    height: 45.w,
                                    fit: BoxFit.contain,
                                    memCacheWidth: (45.w * MediaQuery.of(context).devicePixelRatio).round(),
                                    memCacheHeight: (45.w * MediaQuery.of(context).devicePixelRatio).round(),
                                    placeholder: (_, __) => SizedBox(
                                      width: 45.w,
                                      height: 45.w,
                                      child: const Center(
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    ),
                                    errorWidget: (_, __, ___) => const Icon(
                                      Icons.shopping_bag_outlined,
                                      size: 35,
                                      color: Colors.blue,
                                    ),
                                  ),
                                )
                              : const Icon(
                                  Icons.shopping_bag_outlined,
                                  size: 35,
                                  color: Colors.blue,
                                ),
                          trailing: const Icon(Icons.chevron_right),
                        );
                      },
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
