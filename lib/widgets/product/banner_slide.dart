import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:optombai/widgets/shimmer/shimmer_box.dart';

class BannerSlide extends StatelessWidget {
  const BannerSlide({
    super.key,
    required this.imageUrl,
    this.onTap,
  });

  final String imageUrl;
  final VoidCallback? onTap;

  static const double _slideBorderRadius = 16.0;

  @override
  Widget build(BuildContext context) {
    final isSvg = imageUrl.toLowerCase().endsWith(".svg");
    final isNetwork = imageUrl.startsWith("http");
    final screenWidth = MediaQuery.sizeOf(context).width;
    final bannerHeight = screenWidth / 1.8;

    Widget child;

    if (isNetwork) {
      if (isSvg) {
        child = SvgPicture.network(
          imageUrl,
          width: double.infinity,
          height: bannerHeight,
          fit: BoxFit.fill,
        );
      } else {
        child = CachedNetworkImage(
          imageUrl: imageUrl,
          // Decode at display size, not source resolution.
          memCacheWidth: 1080,
          width: double.infinity,
          height: bannerHeight,
          fit: BoxFit.fill,
          placeholder: (_, __) => ShimmerBox(
            height: bannerHeight,
            borderRadius: _slideBorderRadius,
          ),
          errorWidget: (_, __, ___) => const Icon(Icons.error_outline),
        );
      }
    } else {
      if (isSvg) {
        child = SvgPicture.asset(
          imageUrl,
          width: double.infinity,
          height: bannerHeight,
          fit: BoxFit.fill,
        );
      } else {
        child = Image.asset(
          imageUrl,
          width: double.infinity,
          height: bannerHeight,
          fit: BoxFit.fill,
        );
      }
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: bannerHeight,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_slideBorderRadius),
        ),
        clipBehavior: Clip.antiAlias,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(_slideBorderRadius),
          child: child,
        ),
      ),
    );
  }
}
