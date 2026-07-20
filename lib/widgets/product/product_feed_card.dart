import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:auto_route/auto_route.dart';
import 'package:optombai/app/router/app_router.dart';
import 'package:optombai/bloc/favorite_bloc/favorite_bloc.dart';
import 'package:optombai/core/country_flags.dart';
import 'package:optombai/core/theme_notifier.dart';
import 'package:optombai/data/models/favorite/favorite_model.dart';
import 'package:optombai/data/models/posts/post_model.dart';
import 'package:optombai/data/models/region/kg_region.dart';
import 'package:optombai/utils/extensions/iso_date_extension.dart';
import 'package:optombai/widgets/product/dual_price_text.dart';
import 'package:optombai/widgets/translation/text_translated.dart';
import 'package:optombai/widgets/utils/card/empty_widget.dart';
import 'package:optombai/widgets/utils/live_ring_avatar.dart';

/// Full-width product card for the main/category feeds: a swipeable photo
/// gallery, dual-currency price row, description, and an owner summary row.
class ProductFeedCard extends StatefulWidget {
  const ProductFeedCard({super.key, required this.product, this.chooseMain});

  final Product product;
  final int? chooseMain;

  @override
  State<ProductFeedCard> createState() => _ProductFeedCardState();
}

class _ProductFeedCardState extends State<ProductFeedCard> {
  final PageController _pageController = PageController();
  int _page = 0;

  static const double _borderRadius = 14;
  static const Color _accent = Color(0xFF7B2FF2);
  static const int _maxGalleryPhotos = 6;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Product get _product => widget.product;

  FavoriteResult? _likedOf(List<FavoriteResult> list) {
    if (_product.id.isEmpty) return null;
    for (final r in list) {
      if (r.post.id.isNotEmpty && r.post.id == _product.id) return r;
    }
    return null;
  }

  void _toggleFavorite(BuildContext context, FavoriteResult? liked) {
    final bloc = context.read<FavoriteBloc>();
    if (liked != null) {
      bloc.add(FavoriteDelete(id: liked.id));
    } else {
      bloc.add(FavoriteCreateEvent(
        post: _product.id,
        favoriteResult: FavoriteResult(post: _product),
      ));
    }
  }

  void _openProduct(BuildContext context) {
    context.router.push(ProductDetailsRoute(
      results: _product,
      chooseMainType: widget.chooseMain,
    ));
  }

  void _openOwner(BuildContext context) {
    final String? countryName = _product.owner?.country?.name;
    final String? flagPath =
        countryName != null ? kCountryFlags[countryName] : null;
    context.router.push(OtherUserProfileRoute(
      flagName: flagPath,
      productType:
          _product.postType != null ? int.tryParse(_product.postType!) : null,
      user: _product.owner?.id ?? '',
      username: _product.owner?.username ?? '',
    ));
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = context.select((ThemeNotifier n) => n.isDarkMode);
    final allMedia =
        _product.image_post.where((m) => m.displayUrlOrNull != null).toList();
    // Cap the swipeable gallery at a fixed count — the last visible tile
    // shows a blurred preview with a "+N фото" badge instead of paging
    // through everything, so a 40-photo listing doesn't turn the feed card
    // into an endless swiper.
    final media = allMedia.take(_maxGalleryPhotos).toList();
    final remainingPhotosCount = allMedia.length - media.length;

    final regionLabel = KgRegion.fromId(_product.regionId)?.title;
    final String? flagName = _product.owner?.country?.name;
    final String? flagPath = flagName != null ? kCountryFlags[flagName] : null;
    final String dateLabel = _product.createdAt.asRussianDate;

    final Color fg = isDark ? Colors.white : Colors.black;
    final Color sub = isDark ? Colors.white60 : const Color(0xFF8A8A8A);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openProduct(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(_borderRadius),
                topRight: Radius.circular(_borderRadius),
              ),
              child: AspectRatio(
                aspectRatio: 1.9,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (media.isEmpty)
                      const EmptyImageWidget()
                    else
                      PageView.builder(
                        controller: _pageController,
                        itemCount: media.length,
                        onPageChanged: (i) => setState(() => _page = i),
                        itemBuilder: (_, i) {
                          final isMoreTile =
                              remainingPhotosCount > 0 && i == media.length - 1;
                          final image = CachedNetworkImage(
                            imageUrl: media[i].displayUrlOrNull!,
                            fit: BoxFit.cover,
                            memCacheWidth: 900,
                            errorWidget: (_, __, ___) =>
                                const EmptyImageWidget(),
                          );
                          if (!isMoreTile) return image;
                          return _MorePhotosOverlay(
                            image: image,
                            remainingCount: remainingPhotosCount,
                          );
                        },
                      ),
                    if (media.isNotEmpty &&
                        media[_page].isVideo &&
                        !(remainingPhotosCount > 0 &&
                            _page == media.length - 1))
                      const Center(
                        child: _CenteredPlayIcon(),
                      ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: BlocBuilder<FavoriteBloc, FavoriteState>(
                        buildWhen: (p, c) => p.results != c.results,
                        builder: (context, favState) {
                          final liked = _likedOf(favState.results);
                          return InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () => _toggleFavorite(context, liked),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.45),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                liked != null
                                    ? Icons.bookmark
                                    : Icons.bookmark_border,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  if (media.length > 1)
                    Positioned(
                      left: 12,
                      right: 12,
                      bottom: 10,
                      child: Row(
                        children: [
                          Expanded(
                            child: Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: List.generate(media.length, (i) {
                                  final active = i == _page;
                                  return AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width: active ? 7 : 5,
                                    height: active ? 7 : 5,
                                    margin:
                                        const EdgeInsets.symmetric(horizontal: 2),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: active
                                          ? _accent
                                          : Colors.white.withValues(alpha: 0.7),
                                    ),
                                  );
                                }),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${_page + 1} / ${media.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DualPriceText(
                    price: _product.price,
                    currency: _product.currency,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: fg,
                    ),
                  ),
                  if (_product.description.trim().isNotEmpty) ...[
                    SizedBox(height: 6.h),
                    TextTranslated(
                      _product.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, color: sub, height: 1.3),
                    ),
                  ],
                  SizedBox(height: 10.h),
                  GestureDetector(
                    onTap: () => _openOwner(context),
                    behavior: HitTestBehavior.opaque,
                    child: Row(
                      children: [
                        LiveRingAvatar(
                          radius: 16,
                          ownerId: _product.owner?.id ?? '',
                          imageUrl: _product.owner?.image,
                          child: _product.owner?.image == null
                              ? const Icon(Icons.person,
                                  size: 16, color: Colors.grey)
                              : null,
                        ),
                        SizedBox(width: 8.w),
                        Flexible(
                          child: TextTranslated(
                            _product.owner?.username ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: fg,
                            ),
                          ),
                        ),
                        if (flagPath != null) ...[
                          SizedBox(width: 6.w),
                          Image.asset(flagPath, width: 16.w),
                        ],
                        if (regionLabel != null) ...[
                          SizedBox(width: 4.w),
                          // Region names come from a fixed, short KgRegion
                          // list (unlike the arbitrary-length username), so
                          // it always renders in full — the username shrinks
                          // first when space is tight.
                          TextTranslated(
                            regionLabel,
                            maxLines: 1,
                            style: TextStyle(fontSize: 12, color: sub),
                          ),
                        ],
                        const Spacer(),
                        if (dateLabel.isNotEmpty)
                          Text(
                            dateLabel,
                            style: TextStyle(fontSize: 11, color: sub),
                          ),
                      ],
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

/// Centered play badge for a video page in the gallery. Tapping the card
/// still opens the product (the only screen that actually plays the video),
/// this just signals that the current photo is a video before the user taps.
class _CenteredPlayIcon extends StatelessWidget {
  const _CenteredPlayIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.play_arrow,
        color: Colors.white,
        size: 36,
      ),
    );
  }
}

/// Last visible gallery tile once a listing has more than [_maxGalleryPhotos]
/// photos: the photo blurred behind a "+N фото" badge instead of an endless
/// swiper. Tapping still opens the product, where the full gallery lives.
class _MorePhotosOverlay extends StatelessWidget {
  const _MorePhotosOverlay({required this.image, required this.remainingCount});

  final Widget image;
  final int remainingCount;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        image,
        ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.black.withValues(alpha: 0.35)),
          ),
        ),
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '+$remainingCount фото',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
