import 'package:flutter/material.dart';

/// Turns any scrollable into an infinite feed: fires [onLoadMore] whenever
/// the user scrolls within [threshold] px of the bottom.
///
/// Deliberately fires on every qualifying scroll frame — the owning bloc is
/// expected to guard re-entry itself (in-flight flag + "has next page"
/// check), which keeps this widget stateless and the single source of truth
/// for pagination in the bloc.
class InfiniteScrollRegion extends StatelessWidget {
  const InfiniteScrollRegion({
    super.key,
    required this.onLoadMore,
    required this.child,
    this.threshold = 600,
  });

  final VoidCallback onLoadMore;
  final Widget child;

  /// Distance from the bottom (logical px) at which the next page starts
  /// loading, so new items are ready before the user actually gets there.
  final double threshold;

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollUpdateNotification>(
      onNotification: (notification) {
        final metrics = notification.metrics;
        if (metrics.axis == Axis.vertical && metrics.extentAfter < threshold) {
          onLoadMore();
        }
        return false;
      },
      child: child,
    );
  }
}

/// Bottom-of-feed activity indicator for infinite scroll, sliver-shaped so
/// it can sit directly in a [CustomScrollView]. Collapses to nothing when
/// idle.
class SliverLoadMoreIndicator extends StatelessWidget {
  const SliverLoadMoreIndicator({super.key, required this.isLoading});

  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: LoadMoreIndicator(isLoading: isLoading),
    );
  }
}

/// Box variant of the load-more indicator for non-sliver layouts
/// (e.g. a Column inside a SingleChildScrollView).
class LoadMoreIndicator extends StatelessWidget {
  const LoadMoreIndicator({super.key, required this.isLoading});

  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (!isLoading) return const SizedBox.shrink();
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
      ),
    );
  }
}
