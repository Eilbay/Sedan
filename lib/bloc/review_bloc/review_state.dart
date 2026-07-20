part of 'review_bloc.dart';

class ReviewState extends Equatable {
  final bool isLoading;
  final bool isLoadingSend;
  final List<String> errors;
  final bool isSuccess;
  final List<ReviewResult> list;

  const ReviewState({
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
      List<ReviewResult>? list}) {
    return ReviewState(
        isLoading: isLoading,
        isLoadingSend: isLoadingSend,
        errors: errors,
        isSuccess: isSuccess,
        list: list ?? this.list);
  }

  deleteReview(int id) {
    // var list = list;
    list.removeWhere((element) => element.id == id);

    return copyWith(list: list, isSuccess: true);
  }

  @override
  List<Object?> get props =>
      [isLoading, errors, isSuccess, list, isLoadingSend];
}
