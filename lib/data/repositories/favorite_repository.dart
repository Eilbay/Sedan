import 'package:dio/dio.dart';
import 'package:optombai/core/error/app_exception.dart';
import 'package:optombai/data/api_client.dart';
import 'package:optombai/data/models/favorite/favorite_model.dart';
import 'package:optombai/data/domain_set.dart';
import 'package:optombai/data/repositories/i_favorite_repository.dart';

class FavoriteRepository implements IFavoriteRepository {
  final Dio _dio = ApiClient.I.dio;

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
  }) async {
    try {
      final response = await _dio.get(ApiEndpoints.favoritesApi,
          queryParameters: {
            'post__category': category,
            'post__created_at': created,
            'post__owner__country': country,
            "post__owner": owner,
            "post__product_type": productType,
            "price__gte": priceGte,
            "price__lte": priceLte,
            "search": search,
            "ordering": ordering,
          },
          options: options(token));
      return FavoriteModel.fromJson(response.data);
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<int> createFavorites(String post, String token) async {
    try {
      var res = await _dio.post(ApiEndpoints.favoritesApi,
          data: {'post': post}, options: options(token));

      return res.data["id"];
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<void> deleteFavorite(int id, String token) async {
    try {
      await _dio.delete('${ApiEndpoints.favoritesApi}$id/', options: options(token));
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<List<FavoriteResult>> getAllFavorites(
      String? postOwner, String? name, String token) async {
    try {
      final response = await _dio.get(ApiEndpoints.favoritesApi,
          queryParameters: {'post_owner': postOwner, "search": name},
          options: options(token));
      var list = response.data["results"]
          .map((item) => FavoriteResult.fromJson(item))
          .cast<FavoriteResult>()
          .toList();

      return list;
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }
}
