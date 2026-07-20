import 'package:optombai/data/models/comment/comment.dart';

abstract interface class ICommentRepository {
  Future<CommentsResponse> getComments(
    String postId,
    String token, {
    int limit = 20,
    int offset = 0,
  });

  Future<Comment> createComment(
    String postId,
    String content,
    String token,
  );

  Future<void> deleteComment(
    int commentId,
    String postId,
    String token,
  );
}
