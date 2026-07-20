import 'package:auto_route/auto_route.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:optombai/app/router/app_router.dart';
import 'package:optombai/core/appColors.dart';
import 'package:optombai/core/import_links.dart';
import 'package:optombai/tour/controller/tour_controller.dart';
import 'package:optombai/widgets/translation/text_translated.dart';

String removeEmojis(String text) {
  return text.replaceAll(
    RegExp(
      r'[\u{1F300}-\u{1FAD6}\u{1F900}-\u{1F9FF}\u{1F600}-\u{1F64F}\u{2700}-\u{27BF}]',
      unicode: true,
    ),
    '',
  );
}

class CustomChoose extends StatefulWidget {
  final Function(int?) onFilterChanged;
  final Map<int, GlobalKey>? tourKeys;
  final int? tourTotalStep0;
  final int? tourTotalStep1;
  const CustomChoose({
    super.key,
    required this.onFilterChanged,
    this.tourKeys,
    this.tourTotalStep0,
    this.tourTotalStep1,
  });

  @override
  State<CustomChoose> createState() => _CustomChooseState();
}

class _CustomChooseState extends State<CustomChoose> {
  int? _chosenOwner;

  @override
  Widget build(BuildContext context) {
    final items = [...listProviderAndManufacturer];

    const desiredOrder = [2, 0, 10, 8, 4, 16];
    final sortedItems = [...items]..sort((a, b) {
        final ai = desiredOrder.contains(a.id) ? desiredOrder.indexOf(a.id!) : desiredOrder.length;
        final bi = desiredOrder.contains(b.id) ? desiredOrder.indexOf(b.id!) : desiredOrder.length;
        return ai.compareTo(bi);
      });

    return BlocBuilder<ProductBloc, ProductState>(
      buildWhen: (p, c) => p.stats != c.stats || p.isStatsLoading != c.isStatsLoading,
      builder: (context, state) {
        final stats = state.stats;

        int countFor(ChoseClass item) {
          if (stats == null) return 0;

          switch (item.id) {
            case 2:
              return stats.product;
            case 0:
              return stats.demand;
            case 4:
              return stats.providers;
            case 8:
              return stats.manufacturers;
            case 16:
              return stats.customers;
            default:
              return 0;
          }
        }

        final grid = Directionality(
          textDirection: TextDirection.ltr,
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
              childAspectRatio: 0.82,
              mainAxisExtent: 90,
            ),
            itemCount: sortedItems.length,
            itemBuilder: (context, index) {
              final item = sortedItems[index];

              void open() {
                final tour = context.read<TourController>();
                if (tour.isRunning) {
                  setState(() => _chosenOwner = item.id);
                  widget.onFilterChanged(_chosenOwner);
                  return;
                }

                setState(() => _chosenOwner = item.id);
                widget.onFilterChanged(_chosenOwner);

                if (item.id == 2) {
                  context.router.push(CategoryRoute());
                } else if (item.id == 10) {
                  context.router.push(OrderStatusRoute(categoryId: item.categoryId!));
                } else {
                  context.router.push(OrdersRoute(choseOwner: _chosenOwner, choseMain: 0));
                }
              }

              Widget tile = _ChooseTile(
                item: item,
                count: countFor(item),
                onTap: open,
              );
              final gk = widget.tourKeys?[item.id];
              if (gk != null) {
                tile = KeyedSubtree(key: gk, child: tile);
              }

              return tile;
            },
          ),
        );

        return grid;
      },
    );
  }
}

class _ChooseTile extends StatelessWidget {
  final ChoseClass item;
  final int count;
  final VoidCallback onTap;

  const _ChooseTile({
    required this.item,
    required this.count,
    required this.onTap,
  });

  // bool get _showCrown => item.id == 0 || item.id == 16;

  @override
  Widget build(BuildContext context) {
    final isDark = context.select((ThemeNotifier n) => n.isDarkMode);

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Card(
        margin: EdgeInsets.zero,
        color: isDark ? Colors.transparent : AppColors.white,
        elevation: isDark ? 0 : 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            width: 0.2.w,
            color: isDark ? Colors.white : Colors.transparent,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (item.imagePath != null)
                    Image.asset(
                      item.imagePath!,
                      height: 34.w,
                      width: 34.w,
                      fit: BoxFit.cover,
                    ),
                  const SizedBox(width: 2),
                  if (item.id != 10) Text('$count', style: const TextStyle(fontSize: 12)),
                ],
              ),
              const SizedBox(height: 1),
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextTranslated(
                      item.name,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  // if (_showCrown)
                  //   Padding(
                  //     padding: EdgeInsets.only(left: 4.w),
                  //     child: BlocBuilder<ButtonVisibleBloc, ButtonVisibleState>(
                  //       buildWhen: (previous, current) =>
                  //           previous.status != current.status ||
                  //           previous.statusChangeMode != current.statusChangeMode ||
                  //           previous.isVisible != current.isVisible,
                  //       builder: (context, state) {
                  //         if (!state.isVisible) return const SizedBox();

                  //         return Image.asset(
                  //           'assets/icons/crown.png',
                  //           height: 14,
                  //           width: 14,
                  //           fit: BoxFit.contain,
                  //         );
                  //       },
                  //     ),
                  //   ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
