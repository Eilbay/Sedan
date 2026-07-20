import 'package:auto_route/auto_route.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:optombai/app/router/app_router.dart';
import 'package:optombai/data/models/banner/settings_banners_model.dart';
import 'package:optombai/utils/extensions/url_string_extension.dart';
import 'package:optombai/widgets/promotion/promoted_card_overlay.dart';
import 'package:optombai/widgets/shimmer/shimmer_box.dart';

/// Ad banner rendered inline between product cards in a feed
/// (mashina.kg-style). Tapping opens either the advertiser's profile
/// inside the app or an external URL, depending on the banner's link type.
class FeedBannerCard extends StatelessWidget {
  const FeedBannerCard({super.key, required this.banner});

  final BannerModel banner;

  static const double _borderRadius = 14;
  static const double _aspectRatio = 1.8;

  String get _imageUrl =>
      banner.mobile.isNotEmpty ? banner.mobile : (banner.image ?? '');

  Future<void> _open(BuildContext context) async {
    switch (banner.linkType) {
      case BannerLinkType.external:
        final raw = banner.externalUrl;
        if (raw == null || raw.isEmpty) return;
        final uri = Uri.tryParse(raw.ensureHttpsPrefix());
        if (uri == null) return;
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      case BannerLinkType.user:
        if (banner.user.isEmpty) return;
        await context.router.push(OtherUserProfileRoute(
          user: banner.user,
          username: banner.username ?? '',
        ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bannerHeight = MediaQuery.sizeOf(context).width / _aspectRatio;

    return GestureDetector(
      onTap: () => _open(context),
      child: PromotedCardOverlay(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(_borderRadius),
          child: CachedNetworkImage(
            imageUrl: _imageUrl,
            memCacheWidth: 1080,
            width: double.infinity,
            height: bannerHeight,
            fit: BoxFit.cover,
            placeholder: (_, __) => ShimmerBox(
              height: bannerHeight,
              borderRadius: _borderRadius,
            ),
            // A broken image must not leave a dead grey block in the feed.
            errorWidget: (_, __, ___) => const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}
