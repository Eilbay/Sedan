import 'package:optombai/data/models/favorite/favorite_model.dart';

abstract interface class IFavoriteRepository {
  Future<FavoriteModel> fetchFavoriteByFilter(
    String token, {
    String? category,
    String? created,
    int? country,
    int? productType,
    String? owner,
    String? priceGte,
    String? priceLte,
    String? search,
    String? ordering,
  });

  Future<int> createFavorites(String post, String token);

  Future<void> deleteFavorite(int id, String token);

  Future<List<FavoriteResult>> getAllFavorites(
      String? postOwner, String? name, String token);
}
