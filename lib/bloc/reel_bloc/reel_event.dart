part of 'reel_bloc.dart';

@immutable
abstract class ReelEvent extends Equatable {}

class FetchReelsEvent extends ReelEvent {
  final bool forceRefresh;

  FetchReelsEvent({this.forceRefresh = false});

  @override
  List<Object?> get props => [forceRefresh];
}

/// Switches the reels feed to a category filter. Null = "Все", no filter.
/// Clears current reels and refetches from the server via ?category=<uuid>.
class FilterReelsByCategoryEvent extends ReelEvent {
  final String? categoryId;

  FilterReelsByCategoryEvent(this.categoryId);

  @override
  List<Object?> get props => [categoryId];
}

class LikeReelEvent extends ReelEvent {
  final String reelId;

  LikeReelEvent({required this.reelId});

  @override
  List<Object?> get props => [reelId];
}

class UnlikeReelEvent extends ReelEvent {
  final String reelId;

  UnlikeReelEvent({required this.reelId});

  @override
  List<Object?> get props => [reelId];
}

class RegisterViewEvent extends ReelEvent {
  final String reelId;

  RegisterViewEvent({required this.reelId});

  @override
  List<Object?> get props => [reelId];
}

class FetchMoreReelsEvent extends ReelEvent {
  @override
  List<Object?> get props => [];
}

class SaveLastViewedReelIndexEvent extends ReelEvent {
  final int index;

  SaveLastViewedReelIndexEvent({required this.index});

  @override
  List<Object?> get props => [index];
}

class InvalidateReelsCacheEvent extends ReelEvent {
  @override
  List<Object?> get props => [];
}

class LoadCachedReelsEvent extends ReelEvent {
  @override
  List<Object?> get props => [];
}

/// Drops a reel from the local list — used after a successful report so
/// the reporter does not keep seeing the content while the next fetch
/// hits the network.
class OptimisticRemoveReelEvent extends ReelEvent {
  final String reelId;

  OptimisticRemoveReelEvent(this.reelId);

  @override
  List<Object?> get props => [reelId];
}
