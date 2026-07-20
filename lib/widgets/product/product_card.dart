import 'package:auto_route/auto_route.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:optombai/app/router/app_router.dart';
import 'package:optombai/core/country_flags.dart';
import 'package:optombai/data/models/favorite/favorite_model.dart';
import 'package:optombai/core/theme_notifier.dart';
import 'package:optombai/widgets/product/dual_price_text.dart';
import 'package:optombai/widgets/product/product_cover_image.dart';
// import 'package:optombai/widgets/profile/premium_badge.dart';
import 'package:optombai/widgets/profile/quality_badge.dart';
import 'package:optombai/widgets/shimmer/shimmer_box.dart';
import 'package:optombai/widgets/translation/text_translated.dart';
import 'package:optombai/widgets/common/rating_stars.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:optombai/data/models/posts/post_model.dart';
import 'package:optombai/data/models/region/kg_region.dart';
import 'package:optombai/widgets/utils/custom_avatar.dart';
import 'package:optombai/widgets/utils/live_ring_avatar.dart';

class ProductCard extends StatefulWidget {
  const ProductCard(
      {super.key,
      required this.results,
      this.chooseMain,
      this.showVip = false,
      this.onTap,
      this.onReturned,
      this.uniformMediaStyle = false});

  final Product results;
  final int? chooseMain;
  final bool showVip;
  final VoidCallback? onTap;
  final VoidCallback? onReturned;

  /// When true, video posts render the same way as photo posts (no
  /// play-arrow overlay). Used in catalog grids opened from a product's
  /// category link, where the user expects a uniform layout.
  final bool uniformMediaStyle;

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  // Cached mem-cache dimensions for the cover image. Computed once in
  // didChangeDependencies (re-computed only if MediaQuery changes — e.g.
  // device rotation or theme change), instead of every build() call.
  // The card's preview Stack is fixed at 180.h × ~185w, so a single
  // dpr * 180 value bounds both axes precisely without losing sharpness.
  int? _coverCachePx;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final dpr = MediaQuery.devicePixelRatioOf(context);
    _coverCachePx = (180 * dpr).toInt();
  }

  FavoriteResult? isLike(List<FavoriteResult> list, String prodId) {
    for (var element in list) {
      if (element.post.id == prodId) {
        return element;
      }
    }
    return null;
  }

  Color colorWith30PercentOpacity =
      const Color(0xffFFFFFF).withValues(alpha: 0.3);

  Widget _buildPreview(BuildContext context) {
    return ProductCoverImage(
      product: widget.results,
      memCacheWidth: _coverCachePx,
      memCacheHeight: _coverCachePx,
      placeholder: const ShimmerBox(),
      showVideoIndicator: !widget.uniformMediaStyle,
    );
  }

  @override
  Widget build(BuildContext context) {
    bool stateSwitch = context.select((ThemeNotifier n) => n.isDarkMode);

    String? countryId = widget.results.owner?.country?.name;

    String? flagPath = kCountryFlags[countryId];

    final regionLabel = KgRegion.fromId(widget.results.regionId)?.title;

    return Material(
      borderRadius: BorderRadius.circular(10),
      elevation: 4,
      color: stateSwitch ? const Color.fromARGB(255, 7, 14, 26) : Colors.white,
      child: InkWell(
        onTap: () async {
          if (widget.onTap != null) {
            widget.onTap!();
            return;
          }

          await context.router.push(ProductDetailsRoute(
            results: widget.results,
            chooseMainType: widget.chooseMain,
          ));

          if (!context.mounted) return;

          widget.onReturned?.call();
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              children: [
                SizedBox(
                  height: 180.h,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(10),
                      topRight: Radius.circular(10),
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _buildPreview(context),
                        if (widget.results.isPromoted &&
                            (widget.results.promoEndAt
                                    ?.isAfter(DateTime.now()) ??
                                false))
                          Positioned(
                            top: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xff0095D5),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.trending_up,
                                    size: 10,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 2),
                                  TextTranslated(
                                    'Продвигается',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                if (regionLabel != null)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: stateSwitch
                            ? const Color.fromARGB(255, 7, 14, 26)
                            : Colors.white,
                        borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(10)),
                      ),
                      child: TextTranslated(
                        regionLabel,
                        style: TextStyle(
                          color: stateSwitch
                              ? Colors.white
                              : const Color.fromARGB(255, 7, 14, 26),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextTranslated(
                      widget.results.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 15),
                    ),
                    SizedBox(height: 5.h),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const TextTranslated(
                          "Цена: ",
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        DualPriceText(
                          price: widget.results.price,
                          currency: widget.results.currency,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    // Show 5 stars only when the product actually has a
                    // rating. Otherwise empty outlined stars look like a
                    // rendering bug ("звёздочки не горят") even though
                    // it's accurate — fall back to a plain "нет отзывов"
                    // label which reads naturally.
                    Row(
                      children: [
                        if (widget.results.rating > 0) ...[
                          RatingStars(rating: widget.results.rating),
                          SizedBox(width: 10.w),
                          const TextTranslated(
                            "отзывов: ",
                            style: TextStyle(fontSize: 11),
                          ),
                          TextTranslated(
                            widget.results.displayReviewCount.toString(),
                            style: const TextStyle(fontSize: 13),
                          ),
                        ] else
                          const TextTranslated(
                            "нет отзывов",
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                      ],
                    ),
                    /* SizedBox(height: 6.h),
                    Row(
                      children: [
                        const Icon(Icons.remove_red_eye,
                            size: 14, color: Colors.grey),
                        SizedBox(width: 4.w),
                        TextTranslated(
                          views.toString(),
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ),*/
                    SizedBox(height: 10.h),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              _ProductOwnerAvatar(
                                ownerId: widget.results.owner?.id ?? '',
                                ownerImage: widget.results.owner?.image,
                                isDarkMode: stateSwitch,
                              ),
                              if (flagPath != null) ...[
                                SizedBox(width: 5.w),
                                Image.asset(flagPath, width: 23.w),
                              ],

                              // if (widget.results.owner?.userStatus?.isPremium ?? false)
                              //   BlocBuilder<ButtonVisibleBloc, ButtonVisibleState>(
                              //     buildWhen: (previous, current) =>
                              //         previous.status != current.status ||
                              //         previous.statusChangeMode !=
                              //             current.statusChangeMode,
                              //     builder: (context, state) {
                              //       if (state.isVisible) {
                              //         return Padding(
                              //           padding: const EdgeInsets.only(left: 5),
                              //           child: InkWell(
                              //             onTap: () => context.router
                              //                 .push(const ProAccountsRoute()),
                              //             child: const PremiumBadge(
                              //                 flagCardProduct: true),
                              //           ),
                              //         );
                              //       }
                              //       return const SizedBox();
                              //     },
                              //   ),
                              SizedBox(width: 5.w),
                              if (widget.results.owner?.is_verified == true)
                                const Icon(Icons.verified,
                                    color: Colors.green, size: 20),
                              if (widget.results.owner?.level != null &&
                                  widget.results.owner!.level != "empty" &&
                                  qualityTierForLevel(
                                          widget.results.owner!.level!) !=
                                      null) ...[
                                SizedBox(width: 5.w),
                                QualityBadge(
                                  tier: qualityTierForLevel(
                                      widget.results.owner!.level!)!,
                                  onTap: () =>
                                      context.router.push(const UsersRoute()),
                                ),
                              ],
                            ],
                          ),
                          // TODO: Restore cart button when backend cart API is ready.
                          // ButtonVisibleGate(
                          //   fallback: const SizedBox.shrink(),
                          //   child: Flexible(
                          //     child: BlocBuilder<CartBloc, CartState>(...),
                          //   ),
                          // ),
                          const Flexible(child: SizedBox.shrink()),
                        ],
                      ),
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

class _ProductOwnerAvatar extends StatelessWidget {
  final String ownerId;
  final String? ownerImage;
  final bool isDarkMode;

  const _ProductOwnerAvatar({
    required this.ownerId,
    required this.ownerImage,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 33.w,
      height: 33.h,
      child: LiveRingAvatar(
        radius: 16.5.w,
        ownerId: ownerId,
        imageUrl: ownerImage,
        child: CustomAvatar(
          width: 50.w,
          height: 50.h,
          sizeAvatar: 25,
          size: 25,
          colorContainer: isDarkMode ? Colors.white10 : Colors.black12,
          colorContainerBorder: Colors.black12,
          image: null,
        ),
        notLiveRingBuilder: (avatar) => Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(width: 2.w, color: Colors.transparent),
            gradient: const LinearGradient(
              colors: [Colors.red, Colors.purple],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: avatar,
        ),
      ),
    );
  }
}
