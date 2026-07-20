import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:optombai/data/models/posts/post_model.dart';
import 'package:optombai/widgets/utils/card/empty_widget.dart';

/// Renders the best-available cover for a [Product]:
/// 1. Locally-generated thumbnail (optimistic, during upload),
/// 2. Remote `previewUrl` (photo or ready video cover),
/// 3. [EmptyImageWidget] when nothing is available.
///
/// By default shows a play-arrow overlay when the first media item is a
/// video. Pass [showVideoIndicator] = false to render video covers the
/// same way as photo covers (no overlay) — useful in catalog grids where
/// the cards should look uniform regardless of media type.
/// Safe to use in tests — does no MediaQuery / ScreenUtil lookups.
class ProductCoverImage extends StatelessWidget {
  final Product product;
  final Widget? placeholder;
  final int? memCacheWidth;
  final int? memCacheHeight;
  final bool showVideoIndicator;

  const ProductCoverImage({
    super.key,
    required this.product,
    this.placeholder,
    this.memCacheWidth,
    this.memCacheHeight,
    this.showVideoIndicator = true,
  });

  @override
  Widget build(BuildContext context) {
    final localPath = product.localPreviewPath;
    final url = product.previewUrl;
    final firstImage =
        product.image_post.isNotEmpty ? product.image_post.first : null;
    final showVideoIcon = firstImage?.isVideo ?? false;

    Widget? primary;
    if (localPath != null) {
      primary = Image.file(
        File(localPath),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const EmptyImageWidget(),
      );
    } else if (url != null) {
      primary = CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        memCacheWidth: memCacheWidth,
        // Bounding cacheHeight in addition to cacheWidth — without this
        // CachedNetworkImage keeps the full source height in memory
        // (e.g. 1280px for a Figma cover), wasting 5-7x RAM per card.
        memCacheHeight: memCacheHeight,
        placeholder: (_, __) => placeholder ?? const SizedBox.shrink(),
        errorWidget: (_, __, ___) => const EmptyImageWidget(),
      );
    }

    if (primary == null) return const EmptyImageWidget();

    final showOverlay = showVideoIndicator &&
        (showVideoIcon || (localPath != null && url == null));
    final durationText =
        showVideoIndicator ? firstImage?.formattedDuration : null;

    return Stack(
      fit: StackFit.expand,
      children: [
        primary,
        if (showOverlay) const _VideoPlayOverlay(),
        if (durationText != null && durationText.isNotEmpty)
          Positioned(
            bottom: 6,
            right: 6,
            child: _VideoDurationBadge(text: durationText),
          ),
      ],
    );
  }
}

class _VideoPlayOverlay extends StatelessWidget {
  const _VideoPlayOverlay();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.45),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.play_arrow,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }
}

/// Bottom-right video length badge. Filled black with a matching border so
/// it stays legible on light-colored video thumbnails, not just dark ones.
class _VideoDurationBadge extends StatelessWidget {
  final String text;

  const _VideoDurationBadge({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.black, width: 1),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
