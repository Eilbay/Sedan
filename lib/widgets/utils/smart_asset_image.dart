import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class SmartImage extends StatelessWidget {
  const SmartImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.memCacheWidth,
    this.memCacheHeight,
    this.placeholder,
    this.errorWidget,
  });

  final String url;
  final BoxFit fit;
  final int? memCacheWidth;
  final int? memCacheHeight;
  final Widget Function(BuildContext, String)? placeholder;
  final Widget Function(BuildContext, String, Object)? errorWidget;

  static bool isAssetPath(String url) => url.startsWith('assets/');

  static ImageProvider provider(String url) {
    if (isAssetPath(url)) return AssetImage(url);
    return CachedNetworkImageProvider(url);
  }

  @override
  Widget build(BuildContext context) {
    if (isAssetPath(url)) {
      return Image.asset(
        url,
        fit: fit,
        errorBuilder: errorWidget == null
            ? null
            : (context, error, stackTrace) => errorWidget!(context, url, error),
      );
    }

    return CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      memCacheWidth: memCacheWidth,
      memCacheHeight: memCacheHeight,
      placeholder: placeholder,
      errorWidget: errorWidget,
    );
  }
}
