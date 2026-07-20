import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:optombai/core/error/app_exception.dart';
import 'package:optombai/data/api_client.dart';
import 'package:optombai/data/domain_set.dart';
import 'package:optombai/data/models/store_review/store_review_model.dart';
import 'package:optombai/data/repositories/i_store_review_repository.dart';

class StoreReviewRepository implements IStoreReviewRepository {
  final Dio _dio = ApiClient.I.dio;

  Future<List<StoreReviewResult>> updateStoreReview(
      StoreReviewResult review, String token) async {
    try {
      var res = await _dio.patch("${ApiEndpoints.storeReviewsApi}${review.id}/",
          data: {"review": review.review, "stars": review.stars},
          options: options(token));
      debugPrint('${res.data}');
      var list = await getStoreReview(review.shop, token);

      return list;
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<List<StoreReviewResult>> getStoreReview(
      String shopId, String token) async {
    try {
      final response = await _dio.get(ApiEndpoints.storeReviewsApi,
          queryParameters: {'shop': shopId}, options: options(token));

      var list = response.data["results"]
          .map((item) => StoreReviewResult.fromJson(item))
          .cast<StoreReviewResult>()
          .toList();

      return list;
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<List<StoreReviewResult>> createStoreReview(
      StoreReviewResult review, String token) async {
    try {
      await _dio.post(ApiEndpoints.storeReviewsApi,
          data: review.toJson(), options: options(token));

      var list = await getStoreReview(review.shop, token);

      return list;
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<void> deleteReview(int id, String token) async {
    try {
      await _dio.delete('${ApiEndpoints.storeReviewsApi}$id/', options: options(token));
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }
}
