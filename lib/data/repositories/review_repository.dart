import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:optombai/core/error/app_exception.dart';
import 'package:optombai/data/api_client.dart';
import 'package:optombai/data/domain_set.dart';
import 'package:optombai/data/models/review/review_model.dart';
import 'package:optombai/data/repositories/i_review_repository.dart';

class ReviewRepository implements IReviewRepository {
  final Dio _dio = ApiClient.I.dio;

  Future<List<ReviewResult>> getReview(String postId, String token) async {
    try {
      final response = await _dio.get(ApiEndpoints.reviewsApi,
          queryParameters: {'post': postId}, options: options(token));
      debugPrint('${response.data}');
      var list = response.data["results"]
          .map((item) => ReviewResult.fromJson(item))
          .cast<ReviewResult>()
          .toList();

      return list;
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<List<ReviewResult>> createReview(
      ReviewResult review, String token) async {
    try {
      await _dio.post(ApiEndpoints.reviewsApi, data: review.toJson(), options: options(token));

      var list = await getReview(review.post, token);

      return list;
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<List<ReviewResult>> updateReview(
      ReviewResult review, String token) async {
    try {
      await _dio.patch("${ApiEndpoints.reviewsApi}${review.id}/",
          data: {"review": review.review, "stars": review.stars},
          options: options(token));

      var list = await getReview(review.post, token);

      return list;
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<void> deleteReview(int id, String token) async {
    try {
      await _dio.delete('${ApiEndpoints.reviewsApi}$id/', options: options(token));
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }
}
