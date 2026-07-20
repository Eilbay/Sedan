import 'package:auto_route/auto_route.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:optombai/app/router/app_router.dart';
import 'package:optombai/bloc/favorite_bloc/favorite_bloc.dart';
import 'package:optombai/core/country_flags.dart';
import 'package:optombai/core/theme_notifier.dart';
import 'package:optombai/data/models/favorite/favorite_model.dart';
import 'package:optombai/data/models/posts/post_model.dart';
import 'package:optombai/widgets/product/product_cover_image.dart';
import 'package:optombai/widgets/shimmer/shimmer_box.dart';
import 'package:optombai/widgets/translation/text_translated.dart';
import 'package:optombai/widgets/utils/custom_avatar.dart';

class RecommendationCard extends StatelessWidget {
  final Product results;
  final int? chooseMain;
  final bool showVip;

  const RecommendationCard({
    super.key,
    required this.results,
    this.chooseMain,
    this.showVip = false,
  });

  static const Color _accent = Color(0xFF7B2FF2);

  FavoriteResult? _likedOf(List<FavoriteResult> list) {
    for (final r in list) {
      if (r.post.id == results.id) return r;
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

  @override
  Widget build(BuildContext context) {
    final bool isDark = context.select((ThemeNotifier n) => n.isDarkMode);

    final String? flagName = results.owner?.country?.name;
    final String? flagPath = flagName != null ? kCountryFlags[flagName] : null;

    final market = results.owner?.supplierMarkets.isNotEmpty == true
        ? results.owner!.supplierMarkets.first.marketName
        : null;

    final double ownerRating = results.owner?.rating ?? 0;
    final int ownerReviews = results.owner?.reviewsCount ?? 0;

    final priceText = results.price != null && results.price != 0
        ? '${results.price!.toStringAsFixed(2)} ${results.currency}'
        : 'Цена: Договорная';

    return Material(
      borderRadius: BorderRadius.circular(12),
      elevation: 0,
      color: isDark ? const Color.fromARGB(255, 7, 14, 26) : Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openProduct(context),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.06),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Stack(
                children: [
                  SizedBox(
                    height: 86.h,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                      child: ProductCoverImage(
                        product: results,
                        placeholder: const ShimmerBox(),
                        showVideoIndicator: true,
                      ),
                    ),
                  ),
                  if (showVip)
                    const Positioned(top: 8, left: 8, child: _VipBadge()),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: BlocBuilder<FavoriteBloc, FavoriteState>(
                      buildWhen: (p, c) => p.results != c.results,
                      builder: (context, favState) {
                        final liked = _likedOf(favState.results);
                        return _FavoriteButton(
                          isFavorite: liked != null,
                          isDark: isDark,
                          onTap: () => _toggleFavorite(context, liked),
                        );
                      },
                    ),
                  ),
                ],
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(8.w, 6.h, 8.w, 7.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextTranslated(
                      results.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      priceText,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    GestureDetector(
                      onTap: () => _openOwner(context),
                      behavior: HitTestBehavior.opaque,
                      child: Row(
                        children: [
                          _OwnerAvatar(
                            image: results.owner?.image,
                            isDark: isDark,
                          ),
                          if (flagPath != null) ...[
                            SizedBox(width: 5.w),
                            Image.asset(flagPath, width: 18.w),
                          ],
                          if (results.owner?.is_verified == true) ...[
                            SizedBox(width: 4.w),
                            const Icon(Icons.verified,
                                color: Colors.green, size: 16),
                          ],
                          if (market != null) ...[
                            SizedBox(width: 5.w),
                            Flexible(
                              child: TextTranslated(
                                market,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Row(
                      children: [
                        const Icon(Icons.star,
                            size: 14, color: Color(0xFFFFC107)),
                        SizedBox(width: 4.w),
                        Text(
                          ownerRating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          '($ownerReviews)',
                          style:
                              const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VipBadge extends StatelessWidget {
  const _VipBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3D6),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE8B53D), width: 0.8),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.workspace_premium, size: 12, color: Color(0xFFD89A1E)),
          SizedBox(width: 3),
          Text(
            'VIP',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: Color(0xFFB8860B),
            ),
          ),
        ],
      ),
    );
  }
}

class _FavoriteButton extends StatelessWidget {
  final bool isFavorite;
  final bool isDark;
  final VoidCallback onTap;

  const _FavoriteButton({
    required this.isFavorite,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.85),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(
            isFavorite ? Icons.bookmark : Icons.bookmark_border,
            size: 18,
            color: isFavorite ? const Color(0xFF7B2FF2) : Colors.grey,
          ),
        ),
      ),
    );
  }
}

class _OwnerAvatar extends StatelessWidget {
  final String? image;
  final bool isDark;

  const _OwnerAvatar({required this.image, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22.w,
      height: 22.w,
      child: Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [Colors.red, Colors.purple],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(1.5),
        child: CircleAvatar(
          backgroundColor: const Color(0xffF0F0F0),
          backgroundImage:
              image != null ? CachedNetworkImageProvider(image!) : null,
          child: image == null
              ? CustomAvatar(
                  width: 24.w,
                  height: 24.h,
                  sizeAvatar: 16,
                  size: 16,
                  colorContainer: isDark ? Colors.white10 : Colors.black12,
                  colorContainerBorder: Colors.black12,
                  image: null,
                )
              : null,
        ),
      ),
    );
  }
}
