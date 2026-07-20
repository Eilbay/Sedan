import 'package:dio/dio.dart';
import 'package:optombai/core/error/app_exception.dart';
import 'package:optombai/data/api_client.dart';
import 'package:optombai/data/domain_set.dart';
import 'package:optombai/data/models/comment/comment.dart';
import 'package:optombai/data/repositories/i_comment_repository.dart';

class CommentRepository implements ICommentRepository {
  final Dio _dio = ApiClient.I.dio;

  /// GET /api/v1/comments/?post={postId}&limit={limit}&offset={offset}
  Future<CommentsResponse> getComments(
    String postId,
    String token, {
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.commentsApi,
        queryParameters: {
          'post': postId,
          'limit': limit,
          'offset': offset,
        },
        options: options(token),
      );

      return CommentsResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  /// POST /api/v1/comments/?post={postId}
  Future<Comment> createComment(
    String postId,
    String content,
    String token,
  ) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.commentsApi,
        queryParameters: {'post': postId},
        data: {'content': content},
        options: options(token),
      );

      return Comment.fromJson(response.data);
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  /// DELETE /api/v1/comments/{commentId}/?post={postId}
  Future<void> deleteComment(
    int commentId,
    String postId,
    String token,
  ) async {
    try {
      await _dio.delete(
        '${ApiEndpoints.commentsApi}$commentId/',
        queryParameters: {'post': postId},
        options: options(token),
      );
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }
}
