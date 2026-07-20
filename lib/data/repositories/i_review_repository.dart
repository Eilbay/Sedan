import 'package:optombai/data/models/review/review_model.dart';

abstract interface class IReviewRepository {
  Future<List<ReviewResult>> getReview(String postId, String token);

  Future<List<ReviewResult>> createReview(
      ReviewResult review, String token);

  Future<List<ReviewResult>> updateReview(
      ReviewResult review, String token);

  Future<void> deleteReview(int id, String token);
}
