import 'package:flutter/widgets.dart';
import 'package:optombai/widgets/promotion/promoted_card_overlay.dart';
import 'package:optombai/widgets/promotion/promoted_impression_tracker.dart';
import 'package:optombai/widgets/promotion/promotion_placement.dart';

/// Decorator that wraps a feed card with a "Реклама" overlay + impression
/// tracker when the post is an active promotion, otherwise renders the
/// child as-is. Keeps every feed call-site to a single widget.
class MaybePromotedCard extends StatelessWidget {
  const MaybePromotedCard({
    super.key,
    required this.postId,
    required this.isPromoted,
    required this.promoEndAt,
    required this.placement,
    required this.child,
  });

  final String postId;
  final bool isPromoted;
  final DateTime? promoEndAt;
  final PromotionPlacement placement;
  final Widget child;

  bool get _isActivePromotion {
    if (!isPromoted) return false;
    final end = promoEndAt;
    if (end == null) return true;
    return end.isAfter(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    if (!_isActivePromotion) return child;

    return PromotedImpressionTracker(
      postId: postId,
      placement: placement,
      child: PromotedCardOverlay(child: child),
    );
  }
}
