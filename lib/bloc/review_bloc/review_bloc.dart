import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:optombai/configs/constrants.dart';
import 'package:optombai/core/error/app_exception.dart';
import 'package:optombai/data/models/review/review_model.dart';
import 'package:optombai/data/repositories/i_review_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'review_event.dart';

part 'review_state.dart';

class ReviewBloc extends Bloc<ReviewEvent, ReviewState> {
  final IReviewRepository _repository;
  final SharedPreferences preferences;

  ReviewBloc({required IReviewRepository repository, required this.preferences})
      : _repository = repository,
        super(const ReviewState()) {
    on<ReviewCreateEvent>(onReviewCreate);
    on<AllReviewsEvent>(getAllReview);
    on<UpdateReviewEvent>(updateReviewEvent);
    on<ReviewDeleteEvent>(onReviewDeleteEvent);
  }

  String getToken() => preferences.getString(TOKEN_KEY) ?? "";

  onReviewDeleteEvent(ReviewDeleteEvent event, emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      await _repository.deleteReview(event.id, getToken());

      emit(state.deleteReview(event.id));
    } on AppException catch (e) {
      emit(state.copyWith(errors: e.messages));
    }
  }

  updateReviewEvent(UpdateReviewEvent event, emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      var list = await _repository.updateReview(event.review, getToken());
      emit(state.copyWith(list: list, isSuccess: true));
    } on AppException catch (e) {
      emit(state.copyWith(isLoading: false, errors: e.messages));
    }
  }

  getAllReview(AllReviewsEvent event, emit) async {
    final sw = Stopwatch()..start();
    debugPrint('[PRELOAD] AllReviews FETCHING post=${event.post_id}');
    try {
      var list = await _repository.getReview(event.post_id, getToken());
      debugPrint('[PRELOAD] AllReviews DONE ${sw.elapsedMilliseconds}ms — ${list.length} items');
      emit(state.copyWith(list: list));
    } on AppException catch (e) {
      debugPrint('[PRELOAD] AllReviews ERROR ${sw.elapsedMilliseconds}ms — ${e.messages}');
      emit(state.copyWith(isLoading: false, errors: e.messages));
    }
  }

  onReviewCreate(ReviewCreateEvent event, emit) async {
    emit(state.copyWith(isLoadingSend: true));
    try {
      var list = await _repository.createReview(event.review, getToken());
      emit(state.copyWith(isSuccess: true, list: list));
    } on AppException catch (e) {
      emit(state.copyWith(isLoading: false, errors: e.messages));
    }
  }
}
