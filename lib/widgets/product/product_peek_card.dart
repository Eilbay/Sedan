import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:auto_route/auto_route.dart';
import 'package:optombai/app/router/app_router.dart';
import 'package:optombai/bloc/chat_bloc/chat_bloc.dart';
// STORE_RELEASE_HIDDEN: import 'package:optombai/bloc/chat_bloc/chat_bloc.dart';
import 'package:optombai/bloc/favorite_bloc/favorite_bloc.dart';
// STORE_RELEASE_HIDDEN: import 'package:optombai/core/country_flags.dart';
import 'package:optombai/core/country_flags.dart';
import 'package:optombai/core/theme_notifier.dart';
import 'package:optombai/data/models/favorite/favorite_model.dart';
import 'package:optombai/data/models/region/kg_region.dart';
import 'package:optombai/features/pricing/dual_price_calculator.dart';
import 'package:optombai/utils/extensions/number_grouping_extension.dart';
// STORE_RELEASE_HIDDEN: import 'package:optombai/utils/extensions/string_validation_extension.dart';

import 'package:optombai/utils/extensions/string_validation_extension.dart';
import 'package:optombai/core/import_links.dart';
import 'package:optombai/data/models/posts/post_model.dart';
import 'package:optombai/widgets/translation/text_translated.dart';
import 'package:optombai/widgets/utils/card/empty_widget.dart';

class ProductPeekCard extends StatefulWidget {
  const ProductPeekCard({super.key, required this.product, this.chooseMain});

  final Product product;
  final int? chooseMain;

  @override
  State<ProductPeekCard> createState() => _ProductPeekCardState();
}

class _ProductPeekCardState extends State<ProductPeekCard> {
  static const double _viewportFraction = 0.80;

  static const Color _accent = Color(0xFF5B2EE5);
  static const int _maxGalleryPhotos = 6;

  final PageController _pageController =
      PageController(viewportFraction: _viewportFraction);

  int _currentPage = 0;

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

  // ignore: unused_element
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

  // ignore: unused_element
  Future<void> _openChat(BuildContext context) async {
    final ownerId = _product.owner?.id ?? '';

    final bool isRegister = context.read<ThemeNotifier>().isRegister;
    if (!isRegister) {
      context.router.replace(const SignInRoute());
      return;
    }

    if (!ownerId.isValidUuid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось определить пользователя')),
      );
      return;
    }

    final chatBloc = context.read<ChatBloc>();
    chatBloc.add(CreatePersonalChatEvent(ownerId));

    try {
      final state = await chatBloc.stream.firstWhere((s) {
        final hasChatForUser = s.chats.any(
          (c) => c.participants.any((p) => p.id == ownerId),
        );
        return !s.isLoading && (hasChatForUser || s.errors.isNotEmpty);
      }).timeout(const Duration(seconds: 12));

      if (!context.mounted) return;

      if (state.errors.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(state.errors.join(', '))),
        );
        return;
      }

      final chat = state.chats.firstWhere(
        (c) => c.participants.any((p) => p.id == ownerId),
        orElse: () => state.chats.first,
      );
      context.router.push(ChatConversationRoute(chat: chat));
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось открыть чат')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = context.select((ThemeNotifier n) => n.isDarkMode);

    final allMedia =
        _product.image_post.where((m) => m.displayUrlOrNull != null).toList();
    final media = allMedia.take(_maxGalleryPhotos).toList();
    final remainingPhotosCount = allMedia.length - media.length;

    final String? regionLabel = KgRegion.fromId(_product.regionId)?.title;

    final double ownerRating = _product.owner?.rating ?? 0;
    final int ownerReviews = _product.owner?.reviewsCount ?? 0;

    final Color fg = isDark ? Colors.white : Colors.black;
    final Color sub = isDark ? Colors.white60 : const Color(0xFF8A8A8A);

    final Color priceColor = isDark ? const Color(0xFF9B7BFF) : _accent;

    final bool singleMedia = media.length == 1;

    final Color cardSurface =
        isDark ? const Color.fromARGB(255, 15, 15, 20) : Colors.white;

    return Material(
      color: cardSurface,
      clipBehavior: Clip.antiAlias,
      elevation: isDark ? 0 : 1.5,
      shadowColor: Colors.black.withValues(alpha: 0.10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isDark
            ? BorderSide(color: Colors.white.withValues(alpha: 0.08), width: 1)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () => _openProduct(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 2.00,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (media.isEmpty)
                    const EmptyImageWidget()
                  else if (singleMedia)
                    Stack(
                      fit: StackFit.expand,
                      children: [
                        CachedNetworkImage(
                          imageUrl: media[0].displayUrlOrNull!,
                          fit: BoxFit.cover,
                          memCacheWidth: 900,
                          errorWidget: (_, __, ___) => const EmptyImageWidget(),
                        ),
                        if (media[0].isVideo)
                          const Center(child: _CenteredPlayIcon()),
                      ],
                    )
                  else
                    PageView.builder(
                      controller: _pageController,
                      itemCount: media.length,
                      padEnds: false,
                      onPageChanged: (i) {
                        if (_currentPage == i) return;
                        setState(() => _currentPage = i);
                      },
                      itemBuilder: (_, i) {
                        final isMoreTile =
                            remainingPhotosCount > 0 && i == media.length - 1;

                        final image = CachedNetworkImage(
                          imageUrl: media[i].displayUrlOrNull!,
                          fit: BoxFit.cover,
                          memCacheWidth: 900,
                          errorWidget: (_, __, ___) => const EmptyImageWidget(),
                        );

                        Widget tile = isMoreTile
                            ? _MorePhotosOverlay(
                                image: image,
                                remainingCount: remainingPhotosCount,
                              )
                            : image;

                        return Stack(
                          fit: StackFit.expand,
                          children: [
                            tile,
                            if (media[i].isVideo && !isMoreTile)
                              const Center(child: _CenteredPlayIcon()),
                          ],
                        );
                      },
                    ),
                  if (allMedia.length > 1)
                    Positioned(
                      left: 10,
                      bottom: 10,
                      child: _PhotoCounter(
                        current: _currentPage + 1,
                        total: allMedia.length,
                      ),
                    ),
                ],
              ),
            ),
            if (media.length > 1)
              Padding(
                padding: EdgeInsets.only(top: 8.h),
                child: Center(
                  child: _GalleryDots(
                    count: media.length,
                    currentIndex: _currentPage,
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _PriceText(
                    price: _product.price,
                    currency: _product.currency,
                    color: priceColor,
                  ),

                  // SizedBox(width: 6.w),
                  // _WriteButton(
                  //   accent: _accent,
                  //   isDark: isDark,
                  //   onTap: () => _openChat(context),
                  // ),
                  // Favorite heart commented out per design.
                  // SizedBox(width: 4.w),
                  // BlocBuilder<FavoriteBloc, FavoriteState>(
                  //   buildWhen: (p, c) => p.results != c.results,
                  //   builder: (context, favState) {
                  //     final liked = _likedOf(favState.results);
                  //     return InkWell(
                  //       customBorder: const CircleBorder(),
                  //       onTap: () => _toggleFavorite(context, liked),
                  //       child: Padding(
                  //         padding: const EdgeInsets.all(2),
                  //         child: Icon(
                  //           liked != null
                  //               ? Icons.favorite
                  //               : Icons.favorite_border,
                  //           size: 20,
                  //           color: liked != null ? _accent : sub,
                  //         ),
                  //       ),
                  //     );
                  //   },
                  // ),
                  if (_product.name.trim().isNotEmpty) ...[
                    SizedBox(height: 6.h),
                    TextTranslated(
                      _product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: fg,
                      ),
                    ),
                  ],

                  if (_product.description.trim().isNotEmpty) ...[
                    SizedBox(height: 3.h),
                    TextTranslated(
                      _product.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: sub, height: 1.3),
                    ),
                  ],

                  SizedBox(height: 12.h),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _openOwner(context),
                          behavior: HitTestBehavior.opaque,
                          child: Row(
                            children: [
                              _OwnerAvatar(image: _product.owner?.image),
                              SizedBox(width: 8.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    TextTranslated(
                                      _product.owner?.username ?? '',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: fg,
                                      ),
                                    ),
                                    if (regionLabel != null)
                                      TextTranslated(
                                        regionLabel,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: sub,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(width: 6.w),
                      const Icon(Icons.star_rounded,
                          size: 17, color: Color(0xFFFFB800)),
                      SizedBox(width: 4.w),
                      Text(
                        ownerRating.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: fg,
                        ),
                      ),
                      SizedBox(width: 3.w),
                      Text(
                        '($ownerReviews)',
                        style: TextStyle(fontSize: 13, color: sub),
                      ),
                      SizedBox(width: 10.w),
                      BlocBuilder<FavoriteBloc, FavoriteState>(
                        buildWhen: (p, c) => p.results != c.results,
                        builder: (context, favState) {
                          final liked = _likedOf(favState.results);
                          return InkWell(
                            customBorder: const CircleBorder(),
                            onTap: () => _toggleFavorite(context, liked),
                            child: Padding(
                              padding: const EdgeInsets.all(2),
                              child: Icon(
                                liked != null
                                    ? Icons.bookmark
                                    : Icons.bookmark_border,
                                size: 20,
                                color: liked != null ? _accent : fg,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  // SizedBox(height: 10.h),
                  // GestureDetector(
                  //   onTap: () => _openOwner(context),
                  //   behavior: HitTestBehavior.opaque,
                  //   child: Row(
                  //     children: [
                  //       CircleAvatar(
                  //         radius: 16,
                  //         backgroundColor: const Color(0xffF0F0F0),
                  //         backgroundImage: _product.owner?.image != null
                  //             ? CachedNetworkImageProvider(
                  //                 _product.owner!.image)
                  //             : null,
                  //         child: _product.owner?.image == null
                  //             ? const Icon(Icons.person,
                  //                 size: 16, color: Colors.grey)
                  //             : null,
                  //       ),
                  //       SizedBox(width: 8.w),
                  //       Flexible(
                  //         child: TextTranslated(
                  //           _product.owner?.username ?? '',
                  //           maxLines: 1,
                  //           overflow: TextOverflow.ellipsis,
                  //           style: TextStyle(
                  //             fontSize: 13,
                  //             fontWeight: FontWeight.w700,
                  //             color: fg,
                  //           ),
                  //         ),
                  //       ),
                  //     ],
                  //   ),
                  // ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PriceText extends StatelessWidget {
  const _PriceText({
    required this.price,
    required this.currency,
    required this.color,
  });

  final double? price;
  final String currency;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final rates = context.select((CurrencyBloc b) => b.state.currency);
    final dual =
        DualPriceCalculator(rates).calculate(price: price, currency: currency);

    final style = TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w700,
      color: color,
    );

    if (dual.kgs == null && dual.usd == null) {
      return TextTranslated('Договорная', style: style);
    }

    if (dual.kgs != null) {
      return Text('${dual.kgs!.groupedByThousands} Сом', style: style);
    }

    return Text('${dual.usd!.groupedByThousands} \$', style: style);
  }
}

class _PhotoCounter extends StatelessWidget {
  const _PhotoCounter({required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$current/$total',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _OwnerAvatar extends StatelessWidget {
  const _OwnerAvatar({required this.image});

  final String? image;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 15,
      backgroundColor: const Color(0xffF0F0F0),
      backgroundImage:
          image != null ? CachedNetworkImageProvider(image!) : null,
      child: image == null
          ? const Icon(Icons.person, size: 16, color: Colors.grey)
          : null,
    );
  }
}

class _GalleryDots extends StatelessWidget {
  const _GalleryDots({required this.count, required this.currentIndex});

  final int count;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    final bool isDark = context.select((ThemeNotifier n) => n.isDarkMode);
    final Color inactive = isDark ? Colors.white24 : const Color(0xFFD4D4DC);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (i) {
        final bool isActive = i == currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          margin: EdgeInsets.only(right: i == count - 1 ? 0 : 4),
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF5B2EE5) : inactive,
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }
}

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
      child: const Icon(Icons.play_arrow, color: Colors.white, size: 36),
    );
  }
}

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
