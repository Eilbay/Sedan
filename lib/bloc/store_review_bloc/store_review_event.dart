part of 'store_review_bloc.dart';

@immutable
abstract class StoreReviewEvent extends Equatable {}

class StoreReviewCreateEvent extends StoreReviewEvent{
  final StoreReviewResult review;

  StoreReviewCreateEvent({required this.review});

  @override
  List<Object?> get props => [review];
}

class AllStoreReviewEvent extends StoreReviewEvent{
  final String shop_id;

  AllStoreReviewEvent(this.shop_id);

  @override
  List<Object?> get props => [shop_id];
}

class UpdateStoreReviewEvent extends StoreReviewEvent{
final  StoreReviewResult review;

  UpdateStoreReviewEvent({required this.review});

@override
List<Object?> get props => [review];

}

class StoreReviewDeleteEvent extends StoreReviewEvent {
  final int id;

  StoreReviewDeleteEvent({required this.id});

  @override
  List<Object?> get props => [id];
}

