import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:optombai/app/router/app_router.dart';
import 'package:optombai/bloc/favorite_bloc/favorite_bloc.dart';
import 'package:optombai/core/country_flags.dart';
import 'package:optombai/core/theme_notifier.dart';
import 'package:optombai/data/models/favorite/favorite_model.dart';
import 'package:optombai/data/models/posts/post_model.dart';
import 'package:optombai/data/models/region/kg_region.dart';
import 'package:optombai/widgets/product/product_cover_image.dart';
import 'package:optombai/widgets/shimmer/shimmer_box.dart';
import 'package:optombai/widgets/translation/text_translated.dart';
import 'package:optombai/widgets/utils/custom_avatar.dart';
import 'package:optombai/widgets/utils/live_ring_avatar.dart';

class CatalogProductCard extends StatelessWidget {
  final Product results;
  final int? chooseMain;
  final bool showVip;
  final num? oldPrice;
  final String? currency;

  final VoidCallback? onTap;

  const CatalogProductCard({
    super.key,
    required this.results,
    this.chooseMain,
    this.showVip = false,
    this.oldPrice,
    this.currency,
    this.onTap,
  });

  static const Color _green = Color(0xFF2EB872);
  static const Color _discount = Color(0xFFE5234B);

  FavoriteResult? _likedOf(List<FavoriteResult> list) {
    if (results.id.isEmpty) return null;
    for (final r in list) {
      if (r.post.id.isNotEmpty && r.post.id == results.id) return r;
    }
    return null;
  }

  void _toggleFavorite(BuildContext context, FavoriteResult? liked) {
    final bloc = context.read<FavoriteBloc>();
    if (liked != null) {
      bloc.add(FavoriteDelete(id: liked.id));
    } else {
      bloc.add(FavoriteCreateEvent(
        post: results.id,
        favoriteResult: FavoriteResult(post: results),
      ));
    }
  }

  void _openProduct(BuildContext context) {
    if (onTap != null) {
      onTap!();
      return;
    }
    context.router.push(ProductDetailsRoute(
      results: results,
      chooseMainType: chooseMain,
    ));
  }

  void _openOwner(BuildContext context) {
    final String? countryName = results.owner?.country?.name;
    final String? flagPath =
        countryName != null ? kCountryFlags[countryName] : null;
    context.router.push(OtherUserProfileRoute(
      flagName: flagPath,
      productType:
          results.postType != null ? int.tryParse(results.postType!) : null,
      user: results.owner?.id ?? '',
      username: results.owner?.username ?? '',
    ));
  }

  static String _formatNumber(num v) {
    final s = v.round().toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = context.select((ThemeNotifier n) => n.isDarkMode);

    final String? flagName = results.owner?.country?.name;
    final String? flagPath = flagName != null ? kCountryFlags[flagName] : null;

    final regionLabel = KgRegion.fromId(results.regionId)?.title;

    final resolvedCurrency = currency ?? results.currency;

    final double ownerRating = results.owner?.rating ?? 0;
    final int ownerReviews = results.owner?.reviewsCount ?? 0;

    final bool hasPrice = results.price != null && results.price != 0;
    final bool hasDiscount = oldPrice != null && oldPrice! > 0;
    final String priceText = hasPrice
        ? '${_formatNumber(results.price!)} $resolvedCurrency'
        : 'Договорная';

    final Color fg = isDark ? Colors.white : Colors.black;
    final Color sub = isDark ? Colors.white60 : const Color(0xFF8A8A8A);

    return Material(
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      color: isDark ? const Color.fromARGB(255, 7, 14, 26) : Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _openProduct(context),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.07),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Stack(
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(8.w, 8.h, 8.w, 0),
                    child: SizedBox(
                      height: 150.h,
                      width: double.infinity,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: ProductCoverImage(
                          product: results,
                          placeholder: const ShimmerBox(),
                          showVideoIndicator: true,
                        ),
                      ),
                    ),
                  ),
                  if (regionLabel != null)
                    Positioned(
                      top: 16,
                      left: 16,
                      child: _MarketPin(label: regionLabel),
                    ),
                  Positioned(
                    top: 14,
                    right: 14,
                    child: BlocBuilder<FavoriteBloc, FavoriteState>(
                      buildWhen: (p, c) => p.results != c.results,
                      builder: (context, favState) {
                        final liked = _likedOf(favState.results);
                        return _BookmarkButton(
                          active: liked != null,
                          onTap: () => _toggleFavorite(context, liked),
                        );
                      },
                    ),
                  ),
                ],
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(10.w, 8.h, 10.w, 10.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextTranslated(
                        results.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: fg,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      if (hasDiscount)
                        Text(
                          '${_formatNumber(oldPrice!)} $resolvedCurrency',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      Text(
                        priceText,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: hasDiscount ? _discount : fg,
                        ),
                      ),
                      SizedBox(height: 6.h),
                      if (ownerReviews > 0)
                        Row(
                          children: [
                            _Stars(rating: ownerRating),
                            SizedBox(width: 6.w),
                            Text(
                              ownerRating.toStringAsFixed(1),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: fg,
                              ),
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              '($ownerReviews)',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        )
                      else
                        const Text(
                          'Нет отзывов',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => _openOwner(context),
                        behavior: HitTestBehavior.opaque,
                        child: Row(
                          children: [
                            _OwnerAvatar(
                              ownerId: results.owner?.id ?? '',
                              image: results.owner?.image,
                              isDark: isDark,
                            ),
                            if (flagPath != null) ...[
                              SizedBox(width: 5.w),
                              Image.asset(flagPath, width: 18.w),
                            ],
                            if (results.owner?.is_verified == true) ...[
                              SizedBox(width: 5.w),
                              Container(
                                width: 16,
                                height: 16,
                                decoration: const BoxDecoration(
                                  color: _green,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.check,
                                    size: 11, color: Colors.white),
                              ),
                            ],
                            if (regionLabel != null) ...[
                              SizedBox(width: 6.w),
                              Flexible(
                                child: TextTranslated(
                                  regionLabel,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: fg,
                                  ),
                                ),
                              ),
                            ],
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
      ),
    );
  }
}

class _MarketPin extends StatelessWidget {
  final String label;
  const _MarketPin({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      constraints: const BoxConstraints(maxWidth: 130),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.location_on, size: 14, color: Color(0xFFE5234B)),
          const SizedBox(width: 3),
          Flexible(
            child: TextTranslated(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BookmarkButton extends StatelessWidget {
  final bool active;
  final VoidCallback onTap;
  const _BookmarkButton({required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(9),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          active ? Icons.bookmark : Icons.bookmark_border,
          size: 20,
          color: active ? const Color(0xFF7B2FF2) : Colors.black54,
        ),
      ),
    );
  }
}

class _Stars extends StatelessWidget {
  final double rating;
  const _Stars({required this.rating});

  @override
  Widget build(BuildContext context) {
    const Color amber = Color(0xFFFFC107);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final diff = rating - i;
        IconData icon;
        if (diff >= 1) {
          icon = Icons.star;
        } else if (diff >= 0.5) {
          icon = Icons.star_half;
        } else {
          icon = Icons.star_border;
        }
        return Icon(icon, size: 14, color: amber);
      }),
    );
  }
}

class _OwnerAvatar extends StatelessWidget {
  final String ownerId;
  final String? image;
  final bool isDark;

  const _OwnerAvatar({
    required this.ownerId,
    required this.image,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 26.w,
      height: 26.w,
      child: LiveRingAvatar(
        radius: 13.w,
        ownerId: ownerId,
        imageUrl: image,
        notLiveRingBuilder: (avatar) => Container(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [Colors.red, Colors.purple],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.all(1.5),
          child: avatar,
        ),
        child: image == null
            ? CustomAvatar(
                width: 26.w,
                height: 26.h,
                sizeAvatar: 15,
                size: 15,
                colorContainer: isDark ? Colors.white10 : Colors.black12,
                colorContainerBorder: Colors.black12,
                image: null,
              )
            : null,
      ),
    );
  }
}
