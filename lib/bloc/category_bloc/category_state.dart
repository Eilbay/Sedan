part of 'category_bloc.dart';

class CategoryState extends Equatable {
  final bool isLoading;
  final List<String> errors;
  final bool isSuccess;
  final List<Category> categories;
  final Category? currentCategory;

  const CategoryState({
    this.currentCategory,
    this.isLoading = false,
      this.categories = const [],
    this.errors = const [],
    this.isSuccess = false,
  });

  copyWith({
    bool isLoading = false,
    List<String> errors = const [],
    bool isSuccess = false,
    List<Category>? categories,
    Category? currentCategory,
  }) {
    return CategoryState(
      categories: categories ?? this.categories,
      isLoading: isLoading,
      errors: errors,
      isSuccess: isSuccess,
      currentCategory: currentCategory ?? this.currentCategory
    );
  }

  @override
  List<Object?> get props => [isLoading, errors, isSuccess, categories, currentCategory];
}
