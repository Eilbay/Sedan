import 'package:optombai/data/models/reel/reel_model.dart';

abstract interface class IReelRepository {
  /// Fetches the first page of reels.
  /// [categoryId] — optional server-side filter (UUID). Null = all categories.
  Future<ReelListModel> fetchReels(
    String token, {
    String? categoryId,
    bool forceRefresh,
  });

  Future<void> likeReel(String reelId, String token);

  Future<void> unlikeReel(String reelId, String token);

  Future<ReelListModel> fetchMoreReels(String nextUrl, String token);

  Future<void> registerView(String reelId, String token);

  /// Marks a reel as watched in the personalized feed so the next session
  /// resumes from the following reel. Fire-and-forget on the caller side.
  Future<void> reportProgress(String reelId, String token);

  /// Cheap probe: returns true if the given category has at least one reel.
  /// Uses page_size=1 to minimize payload.
  Future<bool> hasReelsInCategory(String categoryId);
}
