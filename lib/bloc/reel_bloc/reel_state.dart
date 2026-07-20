part of 'reel_bloc.dart';

/// Sentinel used in copyWith to distinguish "not provided" from "set to null".
const Object _unset = Object();

class ReelState extends Equatable {
  final bool isLoading;
  final List<String> errors;
  final bool isSuccess;
  final List<ReelModel> reels;
  final int lastViewedReelIndex;
  final String? nextPageUrl;
  final bool hasReachedEnd;
  final bool isLoadingMore;
  // Active category filter; null means "Все".
  final String? categoryId;

  const ReelState({
    this.reels = const [],
    this.isLoading = false,
    this.errors = const [],
    this.isSuccess = false,
    this.lastViewedReelIndex = 0,
    this.nextPageUrl,
    this.hasReachedEnd = false,
    this.isLoadingMore = false,
    this.categoryId,
  });

  ReelState copyWith({
    bool? isLoading,
    List<String>? errors,
    bool? isSuccess,
    List<ReelModel>? reels,
    int? lastViewedReelIndex,
    String? nextPageUrl,
    bool? hasReachedEnd,
    bool? isLoadingMore,
    // Use Object? sentinel so passing null actually clears the filter.
    Object? categoryId = _unset,
  }) {
    return ReelState(
      reels: reels ?? this.reels,
      isLoading: isLoading ?? this.isLoading,
      errors: errors ?? this.errors,
      isSuccess: isSuccess ?? this.isSuccess,
      lastViewedReelIndex: lastViewedReelIndex ?? this.lastViewedReelIndex,
      nextPageUrl: nextPageUrl ?? this.nextPageUrl,
      hasReachedEnd: hasReachedEnd ?? this.hasReachedEnd,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      categoryId: categoryId == _unset ? this.categoryId : categoryId as String?,
    );
  }

  /// Set like state explicitly for a specific Reel
  ReelState setLiked(String reelId, {required bool isLiked}) {
    final updatedReels = reels.map((reel) {
      if (reel.id == reelId && reel.isLiked != isLiked) {
        return reel.copyWith(
          isLiked: isLiked,
          likes: isLiked ? reel.likes + 1 : reel.likes - 1,
        );
      }
      return reel;
    }).toList();

    return copyWith(reels: updatedReels);
  }

  ReelState incrementViews(String reelId) {
    final updatedReels = reels.map((reel) {
      if (reel.id == reelId) {
        return reel.copyWith(views: reel.views + 1);
      }
      return reel;
    }).toList();

    return copyWith(reels: updatedReels);
  }

  @override
  List<Object?> get props => [
        isLoading,
        errors,
        isSuccess,
        reels,
        lastViewedReelIndex,
        nextPageUrl,
        hasReachedEnd,
        isLoadingMore,
        categoryId,
      ];
}
