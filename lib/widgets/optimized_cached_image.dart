import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// CachedNetworkImage with automatic memCacheWidth/memCacheHeight calculation.
/// Reduces memory consumption by decoding images at display size.
class OptimizedCachedImage extends StatelessWidget {
  const OptimizedCachedImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
  });

  final String imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget Function(BuildContext, String)? placeholder;
  final Widget Function(BuildContext, String, dynamic)? errorWidget;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final memWidth = width != null ? (width! * dpr).toInt() : null;
    final memHeight = height != null ? (height! * dpr).toInt() : null;

    final image = CachedNetworkImage(
      imageUrl: imageUrl,
      fit: fit,
      width: width,
      height: height,
      memCacheWidth: memWidth,
      memCacheHeight: memHeight,
      placeholder: placeholder,
      errorWidget: errorWidget ??
          (_, __, ___) => const Icon(Icons.error),
    );

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: image,
      );
    }

    return image;
  }
}
