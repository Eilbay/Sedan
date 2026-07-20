part of 'favorite_bloc.dart';

class FavoriteState extends Equatable {
  final bool isLoading;
  final List<String> errors;
  final bool isSuccess;
  final List<FavoriteResult> results;
  final FavoriteModel? favoriteModel;

  const FavoriteState({
    this.favoriteModel = const FavoriteModel(),
    this.results = const [],
    this.isLoading = false,
    this.errors = const [],
    this.isSuccess = false,
  });

  copyWith(
      {bool isLoading = false,
      List<String> errors = const [],
      bool isSuccess = false,
      FavoriteModel? favoriteAll,
      List<FavoriteResult>? results,
      FavoriteModel? favoriteModel}) {
    return FavoriteState(
      results: results ?? this.results,
      isLoading: isLoading,
      errors: errors,
      isSuccess: isSuccess,
      favoriteModel: favoriteModel ?? this.favoriteModel,
    );
  }

  deleteProduct(int id) {
    var list = results.toList();
    list.removeWhere((element) => element.id == id);

    return copyWith(results: list, isSuccess: true);
  }

  @override
  List<Object?> get props => [isLoading, errors, isSuccess, results,favoriteModel];
}
