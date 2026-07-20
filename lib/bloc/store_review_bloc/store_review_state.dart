part of 'store_review_bloc.dart';

class StoreReviewState extends Equatable {
  final bool isLoading;
  final bool isLoadingSend;
  final List<String> errors;
  final bool isSuccess;
  final List<StoreReviewResult> list;

  const StoreReviewState({
    this.isLoading = false,
    this.isLoadingSend = false,
    this.errors = const [],
    this.list = const [],
    this.isSuccess = false,
  });

  copyWith(
      {bool isLoading = false,
        bool isLoadingSend = false,
        List<String> errors = const [],
        bool isSuccess = false,
        List<StoreReviewResult>? list}) {
    return StoreReviewState(
        isLoading: isLoading,
        isLoadingSend: isLoadingSend,
        errors: errors,
        isSuccess: isSuccess,
        list: list ?? this.list);
  }

  deleteStoreReview(int id) {
    list.removeWhere((element) => element.id == id);

    return copyWith(list: list, isSuccess: true);
  }

  @override
  List<Object?> get props =>
      [isLoading, errors, isSuccess, list, isLoadingSend];
}

