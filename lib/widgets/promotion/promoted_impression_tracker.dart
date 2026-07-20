import 'package:flutter/material.dart';
import 'package:optombai/core/di/injection.dart';
import 'package:optombai/features/promotion/data/data_sources/promotion_remote_data_source.dart';
import 'package:optombai/widgets/promotion/promotion_placement.dart';
import 'package:visibility_detector/visibility_detector.dart';

/// Wraps a feed card and reports a single promotion impression to the
/// backend once the card becomes visibly on-screen.
///
/// Deduplication: one impression per widget lifetime. Remount = new
/// impression, which matches the user's expectation of "seeing it again"
/// after a scroll.
class PromotedImpressionTracker extends StatefulWidget {
  const PromotedImpressionTracker({
    super.key,
    required this.postId,
    required this.placement,
    required this.child,
    this.visibilityThreshold = 0.5,
  });

  final String postId;
  final PromotionPlacement placement;
  final Widget child;
  final double visibilityThreshold;

  @override
  State<PromotedImpressionTracker> createState() =>
      _PromotedImpressionTrackerState();
}

class _PromotedImpressionTrackerState extends State<PromotedImpressionTracker> {
  bool _reported = false;

  void _onVisibilityChanged(VisibilityInfo info) {
    if (_reported) return;
    if (info.visibleFraction < widget.visibilityThreshold) return;

    _reported = true;

    final dataSource = getIt<PromotionRemoteDataSource>();
    dataSource
        .recordImpression(widget.postId, widget.placement.apiValue)
        .catchError((_) {
      // Impression errors are non-critical; cap is enforced server-side.
    });
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key('promoted_impression_${widget.postId}_${widget.placement.name}'),
      onVisibilityChanged: _onVisibilityChanged,
      child: widget.child,
    );
  }
}
