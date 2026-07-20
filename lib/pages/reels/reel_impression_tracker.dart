import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:optombai/bloc/reel_bloc/reel_bloc.dart';
import 'package:optombai/data/models/reel/reel_model.dart';
import 'package:optombai/data/repositories/i_reel_repository.dart';
import 'package:optombai/features/promotion/data/data_sources/promotion_remote_data_source.dart';
import 'package:optombai/pages/reels/reel_feed_action_queue.dart';
import 'package:optombai/widgets/promotion/promotion_placement.dart';

/// Tracks reel views, feed progress and promotion impressions.
///
/// Deduplicates requests so each reel is only counted once per session, and
/// routes progress + impression delivery through an offline-aware queue so
/// nothing is lost when the network drops mid-scroll.
class ReelImpressionTracker {
  ReelImpressionTracker({
    required PromotionRemoteDataSource dataSource,
    required IReelRepository repository,
    required String Function() tokenProvider,
    required this.currentUserId,
    Connectivity? connectivity,
  }) {
    _queue = ReelFeedActionQueue(
      connectivity: connectivity,
      sender: (action) {
        switch (action.kind) {
          case ReelFeedActionKind.progress:
            return repository.reportProgress(action.postId, tokenProvider());
          case ReelFeedActionKind.impression:
            return dataSource.recordImpression(
              action.postId,
              PromotionPlacement.videoFeed.apiValue,
            );
        }
      },
    );
  }

  final String currentUserId;

  late final ReelFeedActionQueue _queue;

  final Set<String> _viewedReelIds = {};
  final Set<String> _progressReelIds = {};
  final Set<String> _impressionReelIds = {};

  /// Register a view event via [ReelBloc] (deduplicated). Keeps the legacy
  /// per-post view counter growing.
  void registerView(String reelId, ReelBloc bloc) {
    if (_viewedReelIds.contains(reelId)) return;
    _viewedReelIds.add(reelId);
    bloc.add(RegisterViewEvent(reelId: reelId));
  }

  /// Mark a reel as watched in the personalized feed so the next session
  /// resumes from the following reel. Deduplicated + offline-queued.
  void reportProgress(String reelId) {
    if (reelId.isEmpty) return;
    if (_progressReelIds.contains(reelId)) return;
    _progressReelIds.add(reelId);
    _queue.enqueue(PendingReelAction(ReelFeedActionKind.progress, reelId));
  }

  /// Record a promotion impression if the reel is a paid promo slot and the
  /// viewer is not the owner (deduplicated + offline-queued).
  void recordImpressionIfNeeded(ReelModel reel) {
    if (currentUserId.isEmpty) return;
    if (_impressionReelIds.contains(reel.id)) return;
    if (!reel.isPromoCard) return;
    if (reel.owner.id == currentUserId) return;

    _impressionReelIds.add(reel.id);
    // Reels are the vertical video feed — the backend's placement enum accepts
    // `video_feed`.
    _queue.enqueue(PendingReelAction(ReelFeedActionKind.impression, reel.id));
  }

  /// Force-deliver any queued events (call when the app is backgrounded).
  Future<void> flush() => _queue.flush();

  void dispose() => _queue.dispose();
}
