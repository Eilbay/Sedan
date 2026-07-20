import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:optombai/core/import_links.dart';
import 'package:optombai/widgets/bottom_nav.dart';
import 'package:optombai/widgets/translation/text_translated.dart';
import 'package:flutter/cupertino.dart';
import 'package:auto_route/auto_route.dart';
import 'package:optombai/app/router/app_router.dart';
import 'package:optombai/widgets/utils/access/categoryacces.dart';

@RoutePage(name: 'SubcategoryPickerRoute')
class Subcategory extends StatefulWidget {
  final List<Category> list;
  final void Function(Category, String)? onUpdate;
  final String fullNameCategories;

  const Subcategory(
      {super.key,
      required this.list,
      this.onUpdate,
      this.fullNameCategories = ""});

  @override
  State<Subcategory> createState() => _SubcategoryState();
}

class _SubcategoryState extends State<Subcategory> {
  final Category select = const Category();
  String fullName = "";

  @override
  void initState() {
    fullName = widget.fullNameCategories;
    super.initState();
  }

  bool isActive(List<Category> list, Category category) {
    for (var element in list) {
      if (element.id == category.id) {
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final children = filterOutStatusCategories(widget.list);
    return CustomScaffold(
      bottomNavigationBar: const BottomNav(
        currentIndexOverride: -2,
        passive: true,
      ),
      title: 'Категории',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: ListView.separated(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: children.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (BuildContext ctx, index) {
            return Card(
              color: isActive(children, select)
                  ? CupertinoColors.activeOrange
                  : null,
              child: ListTile(
                onTap: () async {
                  final cat = children[index];

                  final nextFullName = ("$fullName${cat.name},  ");
                  final isLeaf = cat.children.isEmpty;

                  if (isLeaf) {
                    final trimmed =
                        nextFullName.substring(0, nextFullName.length - 3);

                    if (!mounted) return;
                    context.router.maybePop(CategoryPickResult(cat, trimmed));
                    return;
                  }

                  final res = await context.router.push<CategoryPickResult>(
                    SubcategoryPickerRoute(
                      list: cat.children,
                      fullNameCategories: nextFullName,
                    ),
                  );

                  if (!context.mounted) return;
                  if (res != null) {
                    context.router.maybePop(res);
                  }
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
                          memCacheWidth:
                              (45.w * MediaQuery.of(context).devicePixelRatio)
                                  .round(),
                          memCacheHeight:
                              (45.w * MediaQuery.of(context).devicePixelRatio)
                                  .round(),
                          placeholder: (_, __) => const SizedBox(
                            width: 45,
                            height: 45,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          errorWidget: (_, __, ___) => const Icon(
                              Icons.shopping_bag_outlined,
                              size: 35,
                              color: Colors.blue),
                        ),
                      )
                    : const Icon(Icons.shopping_bag_outlined,
                        size: 35, color: Colors.blue),
                trailing: children[index].children.isNotEmpty
                    ? const Icon(Icons.chevron_right)
                    : null,
              ),
            );
          },
        ),
      ),
    );
  }
}

class CategoryPickResult {
  final Category category;
  final String fullName;
  const CategoryPickResult(this.category, this.fullName);
}
