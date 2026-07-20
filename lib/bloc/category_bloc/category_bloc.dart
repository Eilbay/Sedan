import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart' hide Category;
import 'package:optombai/core/error/app_exception.dart';
import 'package:optombai/data/models/category/category_model.dart';
import 'package:optombai/data/repositories/i_category_repository.dart';
import 'package:equatable/equatable.dart';

part 'category_event.dart';

part 'category_state.dart';

class CategoryBloc extends Bloc<CategoryEvent, CategoryState> {
  final ICategoryRepository _repository;

  CategoryBloc({required ICategoryRepository repository})
      : _repository = repository,
        super(const CategoryState()) {
    on<CategoryAllEvent>(_onGetCategories);
    on<CategoryGetEvent>(_onGetCategory);
  }
  _onGetCategory(CategoryGetEvent event, emit) async {
    if (event.id == null) {
      emit(state.copyWith(currentCategory: const Category()));
      return;
    }
    emit(state.copyWith(isLoading: true));
    try {
      final category = await _repository.fetchCategory(event.id!);
      emit(state.copyWith(currentCategory: category));
    } on AppException catch (e) {
      debugPrint('Error fetching categories: $e');
    }
  }

  _onGetCategories(CategoryAllEvent event, Emitter<CategoryState> emit) async {
    if (!event.forceRefresh && state.categories.isNotEmpty) {
      debugPrint('[PRELOAD] Categories SKIP (cached, ${state.categories.length} items)');
      return;
    }
    if (!event.forceRefresh && state.isLoading) {
      debugPrint('[PRELOAD] Categories SKIP (already loading)');
      return;
    }

    debugPrint('[PRELOAD] Categories FETCHING');
    final sw = Stopwatch()..start();
    emit(state.copyWith(isLoading: true));
    try {
      final categories = await _repository.fetchData(
        categoryTypes: event.categoryTypes,
      );
      debugPrint('[PRELOAD] Categories DONE ${sw.elapsedMilliseconds}ms — ${categories.length} items');
      emit(state.copyWith(
          isSuccess: true, categories: categories, isLoading: false));
    } on AppException catch (e) {
      debugPrint('[PRELOAD] Categories ERROR ${sw.elapsedMilliseconds}ms — $e');
      emit(state.copyWith(isLoading: false));
    }
  }
}
