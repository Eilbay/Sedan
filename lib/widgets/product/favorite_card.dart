import 'package:auto_route/auto_route.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:optombai/app/router/app_router.dart';
import 'package:optombai/data/models/favorite/favorite_model.dart';
import 'package:optombai/data/models/posts/post_model.dart';
import 'package:optombai/widgets/translation/text_translated.dart';
import 'package:optombai/widgets/utils/card/empty_widget.dart';
import 'package:optombai/widgets/common/rating_stars.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:optombai/core/theme_notifier.dart';

class FavoriteCard extends StatefulWidget {
  const FavoriteCard(
      {super.key, required this.results, required this.onPressed});

  final FavoriteResult results;
  final VoidCallback onPressed;

  @override
  State<FavoriteCard> createState() => _FavoriteCardState();
}

class _FavoriteCardState extends State<FavoriteCard> {
  late final FavoriteResult results;

  @override
  void initState() {
    results = widget.results;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    bool stateSwitch = context.select((ThemeNotifier n) => n.isDarkMode);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Material(
        borderRadius: BorderRadius.circular(10),
        elevation: 10,
        color: stateSwitch ? const Color(0xff0e1e33) : Colors.white,
        child: InkWell(
          onTap: () {
            context.router.push(
                ProductDetailsRoute(results: results.post));
          },
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 130.w,
                height: 140.h,
                child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(10),
                        bottomLeft: Radius.circular(10)),
                    child: _buildFavoritePreview(results.post)),
              ),
              SizedBox(
                width: 10.w,
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 10.h,
                    ),
                    if (results.post.owner!.userStatus!.isPremium)
                      const Image(image: AssetImage('assets/logo2.png')),
                    SizedBox(height: 10.h),
                    Row(
                      children: [
                        TextTranslated(
                          results.post.name.length > 7
                              ? '${results.post.name.substring(0, 7)}...'
                              : results.post.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    // 5 empty stars at rating=0 look like a "broken
                    // rendering" bug to users — show stars only when
                    // there is an actual rating to display.
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (results.post.rating > 0) ...[
                          RatingStars(rating: results.post.rating),
                          SizedBox(width: 10.w),
                          TextTranslated(
                            results.post.displayReviewCount.toString(),
                            maxLines: 1,
                            overflow: TextOverflow.fade,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ] else
                          const TextTranslated(
                            'нет отзывов',
                            maxLines: 1,
                            overflow: TextOverflow.fade,
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                      ],
                    ),
                    SizedBox(
                      height: 10.h,
                    ),
                    TextTranslated(
                      results.post.description,
                      maxLines: 2,
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w400),
                    ),
                    SizedBox(
                      height: 12.h,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextTranslated(
                          results.post.price != null && results.post.price != 0
                              ? "Цена: ${results.post.price!.toStringAsFixed(2)} ${results.post.currency}"
                              : "Цена: Договорная",
                          maxLines: 2,
                          overflow: TextOverflow.fade,
                          style: TextStyle(
                            fontSize: results.post.price != null &&
                                    results.post.price != 0
                                ? 10
                                : 9,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        /*SizedBox(height: 7.h),
                        if (flagPath != null)
                          Image(
                            image: AssetImage(flagPath),
                            width: 23.w,
                          )*/
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: widget.onPressed,
                icon: const Icon(
                  Icons.bookmark,
                  color: Color(0xFF7B2FF2),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

Widget _buildFavoritePreview(Product post) {
  final url = post.previewUrl;
  if (url == null) return const EmptyImageWidget();
  final firstImage = post.image_post.isNotEmpty ? post.image_post.first : null;
  final showVideoIcon = firstImage?.isVideo ?? false;

  return Stack(
    fit: StackFit.expand,
    children: [
      CachedNetworkImage(
        imageUrl: url,
        // Decode at display size, not source resolution.
        memCacheWidth: 600,
        fit: BoxFit.cover,
        placeholder: (_, __) => const ColoredBox(color: Color(0xFFEDEDED)),
        errorWidget: (_, __, ___) => const EmptyImageWidget(),
      ),
      if (showVideoIcon)
        Center(
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.play_arrow,
              color: Colors.white,
              size: 30,
            ),
          ),
        ),
    ],
  );
}
