import 'package:bloc/bloc.dart';
import 'package:optombai/configs/constrants.dart';
import 'package:optombai/core/error/app_exception.dart';
import 'package:optombai/data/models/favorite/favorite_model.dart';
import 'package:optombai/data/repositories/i_favorite_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'favorite_event.dart';

part 'favorite_state.dart';

class FavoriteBloc extends Bloc<FavoriteEvent, FavoriteState> {
  final IFavoriteRepository _repository;
  final SharedPreferences preferences;

  FavoriteBloc(
      {required IFavoriteRepository repository, required this.preferences})
      : _repository = repository,
        super(const FavoriteState()) {
    on<FavoriteCreateEvent>(onFavoriteCreate);
    on<FavoriteAllEvent>(onGetAllFavorite);
    on<FavoriteDelete>(onDeleteFavorite);
    on<FavoriteWithFilter>(_getFavoriteWithFilter);
  }

  String getToken() => preferences.getString(TOKEN_KEY) ?? "";

  List<FavoriteResult> _newestSavedFirst(List<FavoriteResult> results) {
    final sorted = results.toList();
    sorted.sort((a, b) => b.id.compareTo(a.id));
    return sorted;
  }

  _getFavoriteWithFilter(FavoriteWithFilter event, emit) async {
    emit(state.copyWith(isLoading: true, results: []));
    try {
      var favoriteModel = await _repository.fetchFavoriteByFilter(
        getToken(),
        category: event.category,
        owner: event.owner,
        country: event.country,
        created: event.created,
        productType: event.productType,
        ordering: event.ordering,
        priceGte: event.priceGte,
        priceLte: event.priceLte,
        search: event.search,
      );
      final results = event.ordering == null
          ? _newestSavedFirst(favoriteModel.results)
          : favoriteModel.results;

      emit(state.copyWith(
          isSuccess: true,
          results: results,
          favoriteModel: favoriteModel.copyWith(results: results)));
    } on AppException catch (e) {
      emit(state.copyWith(errors: e.messages));
    }
  }

  onFavoriteCreate(FavoriteCreateEvent event, emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      int id = await _repository.createFavorites(event.post, getToken());

      var list = state.results.toList();

      list.insert(0, event.favoriteResult.copyWith(id: id));

      emit(state.copyWith(isSuccess: true, results: list));
    } on AppException catch (e) {
      emit(state.copyWith(errors: e.messages));
    }
  }

  onGetAllFavorite(FavoriteAllEvent event, emit) async {
    if (!event.forceRefresh && state.results.isNotEmpty) return;

    emit(state.copyWith(isLoading: true));
    try {
      var list = await _repository.getAllFavorites(
          event.post_owner, event.name, getToken());
      emit(state.copyWith(isSuccess: true, results: _newestSavedFirst(list)));
    } on AppException catch (e) {
      emit(state.copyWith(errors: e.messages));
    }
  }

  onDeleteFavorite(FavoriteDelete event, emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      await _repository.deleteFavorite(event.id, getToken());
      var updatedList =
          state.results.where((element) => element.id != event.id).toList();
      emit(state.copyWith(results: updatedList, isLoading: false));
      // emit(state.deleteProduct(event.id,));
    } on AppException catch (e) {
      emit(state.copyWith(errors: e.messages));
    }
  }
}
