part of 'review_bloc.dart';

abstract class ReviewEvent extends Equatable {}

class ReviewCreateEvent extends ReviewEvent {
  final ReviewResult review;

  ReviewCreateEvent({required this.review});

  @override
  List<Object?> get props => [review];
}

class AllReviewsEvent extends ReviewEvent {
  final String post_id;

  AllReviewsEvent(this.post_id);

  @override
  List<Object?> get props => [post_id];
}

class UpdateReviewEvent extends ReviewEvent {
  final ReviewResult review;

  UpdateReviewEvent({required this.review});

  @override
  List<Object?> get props => [review];
}

class ReviewDeleteEvent extends ReviewEvent {
  final int id;

  ReviewDeleteEvent({required this.id});

  @override
  List<Object?> get props => [id];
}
