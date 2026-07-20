import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:optombai/configs/constrants.dart';
import 'package:optombai/core/error/app_exception.dart';
import 'package:optombai/data/models/store_review/store_review_model.dart';
import 'package:optombai/data/repositories/i_store_review_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'store_review_event.dart';

part 'store_review_state.dart';

class StoreReviewBloc extends Bloc<StoreReviewEvent, StoreReviewState> {
  final IStoreReviewRepository _repository;
  final SharedPreferences preferences;

  StoreReviewBloc({required IStoreReviewRepository repository, required this.preferences})
      : _repository = repository,
        super(const StoreReviewState()) {
    on<StoreReviewCreateEvent>(onStoreReviewCreate);
    on<AllStoreReviewEvent>(getAllStoreReview);
    on<UpdateStoreReviewEvent>(updateStoreReviewEvent);
    on<StoreReviewDeleteEvent>(onStoreReviewFavoriteEvent);
  }

  String getToken() => preferences.getString(TOKEN_KEY) ?? "";

  onStoreReviewFavoriteEvent(StoreReviewDeleteEvent event, emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      await _repository.deleteReview(event.id, getToken());
      emit(state.deleteStoreReview(event.id));
    } on AppException catch (e) {
      emit(state.copyWith(errors: e.messages));
    }
  }

  updateStoreReviewEvent(UpdateStoreReviewEvent event, emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      var list = await _repository.updateStoreReview(
          event.review, getToken());
      emit(state.copyWith(list: list, isSuccess: true));
    } on AppException catch (e) {
      debugPrint("error updateReview  $e");
      emit(state.copyWith());
    }
  }

  getAllStoreReview(AllStoreReviewEvent event, emit) async {
    final token = getToken();
    if (token.isEmpty) return;

    try {
      var list = await _repository.getStoreReview(event.shop_id, token);
      emit(state.copyWith(list: list));
    } on AppException {
      emit(state.copyWith());
    }
  }

  onStoreReviewCreate(StoreReviewCreateEvent event, emit) async {
    emit(state.copyWith(isLoadingSend: true));
    try {
      var list = await _repository.createStoreReview(
          event.review, getToken());
      emit(state.copyWith(isSuccess: true, list: list));
    } on AppException {
      emit(state.copyWith());
    }
  }
}
