import 'package:dio/dio.dart';
import 'package:optombai/core/error/app_exception.dart';
import 'package:optombai/data/api_client.dart';
import 'package:optombai/data/models/reel/reel_model.dart';
import 'package:optombai/data/domain_set.dart';
import 'package:optombai/data/repositories/i_reel_repository.dart';

class ReelRepository implements IReelRepository {
  final Dio _dio = ApiClient.I.dio;

  @override
  Future<ReelListModel> fetchReels(
    String token, {
    String? categoryId,
    bool forceRefresh = false,
  }) async {
    try {
      final auth = token.isEmpty ? null : options(token);
      // A forced refresh must hit the network so a just-blocked author's
      // reels are dropped by the server-side filter instead of being served
      // from the 5-min cache.
      final reqOptions = forceRefresh
          ? ApiClient.I.forceRefreshOptions.copyWith(headers: auth?.headers)
          : auth;
      final response = await _dio.get(
        ApiEndpoints.reelsFeed,
        queryParameters: categoryId != null && categoryId.isNotEmpty
            ? {'category': categoryId}
            : null,
        options: reqOptions,
      );

      return ReelListModel.fromJson(response.data);
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  @override
  Future<void> likeReel(String reelId, String token) async {
    try {
      await _dio.post(
        '${ApiEndpoints.postsApi}$reelId/like/',
        options: options(token),
      );
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  @override
  Future<void> unlikeReel(String reelId, String token) async {
    try {
      await _dio.delete(
        '${ApiEndpoints.postsApi}$reelId/unlike/',
        options: options(token),
      );
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  /// Fetch next page of Reels by URL
  @override
  Future<ReelListModel> fetchMoreReels(String nextUrl, String token) async {
    try {
      final response = await _dio.get(
        nextUrl,
        options: (token.isEmpty) ? null : options(token),
      );

      return ReelListModel.fromJson(response.data);
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  @override
  Future<void> registerView(String reelId, String token) async {
    try {
      await _dio.post(
        '${ApiEndpoints.postsApi}$reelId/view/',
        options: options(token),
      );
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  @override
  Future<void> reportProgress(String reelId, String token) async {
    try {
      await _dio.post(
        ApiEndpoints.reelsFeedProgress,
        data: {'post_id': reelId},
        options: options(token),
      );
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  @override
  Future<bool> hasReelsInCategory(String categoryId) async {
    if (categoryId.isEmpty) return false;
    try {
      final response = await _dio.get(
        ApiEndpoints.reelsFeed,
        queryParameters: {'category': categoryId, 'page_size': 1},
      );
      final results = (response.data is Map)
          ? (response.data['results'] as List?)
          : null;
      return results != null && results.isNotEmpty;
    } on DioException {
      return false;
    }
  }
}
