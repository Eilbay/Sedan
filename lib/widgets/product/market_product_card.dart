import 'package:auto_route/auto_route.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:optombai/app/router/app_router.dart';
import 'package:optombai/bloc/chat_bloc/chat_bloc.dart';
import 'package:optombai/bloc/favorite_bloc/favorite_bloc.dart';
import 'package:optombai/core/country_flags.dart';
import 'package:optombai/core/theme_notifier.dart';
import 'package:optombai/data/models/favorite/favorite_model.dart';
import 'package:optombai/data/models/posts/post_model.dart';
import 'package:optombai/data/models/region/kg_region.dart';
import 'package:optombai/utils/extensions/string_validation_extension.dart';
import 'package:optombai/widgets/product/product_cover_image.dart';
import 'package:optombai/widgets/shimmer/shimmer_box.dart';
import 'package:optombai/widgets/translation/text_translated.dart';
import 'package:optombai/widgets/utils/custom_avatar.dart';

class MarketProductCard extends StatelessWidget {
  final Product results;
  final int? chooseMain;
  final bool showVip;

  final num? oldPrice;

  final String? currency;

  const MarketProductCard({
    super.key,
    required this.results,
    this.chooseMain,
    this.showVip = false,
    this.oldPrice,
    this.currency,
  });

  static const Color _accent = Color(0xFF2F80ED);
  static const Color _discount = Color(0xFFE5234B);
  static const Color _saved = _accent;

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
      bloc.add(
        FavoriteCreateEvent(
          post: results.id,
          favoriteResult: FavoriteResult(post: results),
        ),
      );
    }
  }

  void _openProduct(BuildContext context) {
    context.router.push(
      ProductDetailsRoute(results: results, chooseMainType: chooseMain),
    );
  }

  void _openOwner(BuildContext context) {
    final String? countryName = results.owner?.country?.name;
    final String? flagPath =
        countryName != null ? kCountryFlags[countryName] : null;
    context.router.push(
      OtherUserProfileRoute(
        flagName: flagPath,
        productType:
            results.postType != null ? int.tryParse(results.postType!) : null,
        user: results.owner?.id ?? '',
        username: results.owner?.username ?? '',
      ),
    );
  }

  Future<void> _openChat(BuildContext context) async {
    final ownerId = results.owner?.id ?? '';

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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(state.errors.join(', '))));
        return;
      }

      final chat = state.chats.firstWhere(
        (c) => c.participants.any((p) => p.id == ownerId),
        orElse: () => state.chats.first,
      );
      context.router.push(ChatConversationRoute(chat: chat));
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Не удалось открыть чат')));
    }
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

  bool get _isAd {
    if (results.isPromoted == true) return true;
    if ((results.promoCampaignId ?? '').trim().isNotEmpty) return true;

    final end = results.promoEndAt;
    if (end != null && end.isAfter(DateTime.now())) return true;

    return false;
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = context.select((ThemeNotifier n) => n.isDarkMode);

    final regionLabel = KgRegion.fromId(results.regionId)?.title;

    final resolvedCurrency = currency ?? results.currency;

    final String currencyLabel = switch (resolvedCurrency.toUpperCase()) {
      'KGS' => 'сом',
      'USD' => '\$',
      _ => resolvedCurrency,
    };

    final double ownerRating = results.owner?.rating ?? 0;
    final int ownerReviews = results.owner?.reviewsCount ?? 0;

    final bool hasPrice = results.price != null && results.price != 0;
    final bool hasDiscount = oldPrice != null && oldPrice! > 0;
    final String priceText = hasPrice
        ? '${_formatNumber(results.price!)} $currencyLabel'
        : 'Договорная';

    final bool showAdBadge = _isAd;

    final Color fg = isDark ? Colors.white : Colors.black;
    final Color sub = isDark ? Colors.white60 : const Color(0xFF8A8A8A);

    final Color borderColor =
        isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE6E6E6);

    final Color cardSurface = isDark ? const Color(0xFF14141C) : Colors.white;

    return Material(
      clipBehavior: Clip.antiAlias,
      elevation: isDark ? 0 : 1.5,
      shadowColor: Colors.black.withValues(alpha: 0.10),
      color: cardSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: borderColor, width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _openProduct(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                SizedBox(
                  height: 130.h,
                  width: double.infinity,
                  child: ProductCoverImage(
                    product: results,
                    placeholder: const ShimmerBox(),
                    showVideoIndicator: true,
                  ),
                ),
                if (showAdBadge)
                  const Positioned(left: 8, bottom: 8, child: _AdBadge()),
                Positioned(
                  right: 6,
                  top: 6,
                  child: BlocBuilder<FavoriteBloc, FavoriteState>(
                    buildWhen: (p, c) => p.results != c.results,
                    builder: (context, favState) {
                      final liked = _likedOf(favState.results);
                      return _BookmarkButton(
                        isSaved: liked != null,
                        onTap: () => _toggleFavorite(context, liked),
                      );
                    },
                  ),
                ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(10.w, 10.h, 10.w, 10.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextTranslated(
                      results.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: fg,
                      ),
                    ),
                    if (results.description.trim().isNotEmpty) ...[
                      SizedBox(height: 4.h),
                      TextTranslated(
                        results.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.35,
                          color: sub,
                        ),
                      ),
                    ],
                    SizedBox(height: 6.h),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            priceText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: hasDiscount ? _discount : _accent,
                            ),
                          ),
                        ),
                        if (hasDiscount) ...[
                          SizedBox(width: 6.w),
                          Text(
                            '${_formatNumber(oldPrice!)} $currencyLabel',
                            style: TextStyle(
                              fontSize: 11,
                              color: sub,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _openOwner(context),
                            behavior: HitTestBehavior.opaque,
                            child: Row(
                              children: [
                                _OwnerAvatar(
                                  image: results.owner?.image,
                                  isDark: isDark,
                                ),
                                SizedBox(width: 5.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Row(
                                        children: [
                                          Flexible(
                                            child: TextTranslated(
                                              results.owner?.username ?? '',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: fg,
                                              ),
                                            ),
                                          ),
                                          if (results.owner?.is_verified ==
                                              true) ...[
                                            SizedBox(width: 2.w),
                                            const Icon(
                                              Icons.verified,
                                              color: Colors.green,
                                              size: 11,
                                            ),
                                          ],
                                        ],
                                      ),
                                      if (regionLabel != null)
                                        TextTranslated(
                                          regionLabel,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 10,
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
                        SizedBox(width: 4.w),
                        const Icon(
                          Icons.star,
                          size: 13,
                          color: Color(0xFFFFC107),
                        ),
                        SizedBox(width: 2.w),
                        Text(
                          ownerRating.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: fg,
                          ),
                        ),
                        SizedBox(width: 2.w),
                        Text(
                          '($ownerReviews)',
                          style: TextStyle(fontSize: 10, color: sub),
                        ),
                      ],
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

class _AdBadge extends StatelessWidget {
  const _AdBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: MarketProductCard._accent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Text(
        'А',
        style: TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          height: 1,
        ),
      ),
    );
  }
}

class _BookmarkButton extends StatelessWidget {
  const _BookmarkButton({required this.isSaved, required this.onTap});

  final bool isSaved;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          isSaved ? Icons.bookmark : Icons.bookmark_border,
          size: 16,
          color: isSaved ? MarketProductCard._accent : Colors.black87,
        ),
      ),
    );
  }
}

class VipBadgeNew extends StatelessWidget {
  const VipBadgeNew({super.key});

  @override
  Widget build(BuildContext context) {
    return Image.asset('assets/icons/vip_badge.png', height: 22);
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
                  width: 20.w,
                  height: 20.h,
                  sizeAvatar: 12,
                  size: 12,
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
