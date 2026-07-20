part of 'document_bloc.dart';

class DocumentState extends Equatable {
  final bool isLoading;
  final List<String> errors;
  final bool isSuccess;
  final List<DocumentImageModel> results;

  const DocumentState({
    this.results = const [],
    this.isLoading = false,
    this.errors = const [],
    this.isSuccess = false,
  });

  copyWith({
    bool isLoading = false,
    List<String> errors = const [],
    bool isSuccess = false,
    List<DocumentImageModel>? results,
  }) {
    return DocumentState(
      results: results ?? this.results,
      isLoading: isLoading,
      errors: errors,
      isSuccess: isSuccess,
    );
  }

  deleteImage(int id) {
    var list = results.toList();
    list.removeWhere((element) => element.id == id);

    return copyWith(results: list, isSuccess: true);
  }

  @override
  List<Object?> get props => [isLoading, errors, isSuccess, results];
}
