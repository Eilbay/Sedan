import 'package:optombai/data/models/store_review/store_review_model.dart';

abstract interface class IStoreReviewRepository {
  Future<List<StoreReviewResult>> updateStoreReview(
      StoreReviewResult review, String token);

  Future<List<StoreReviewResult>> getStoreReview(
      String shopId, String token);

  Future<List<StoreReviewResult>> createStoreReview(
      StoreReviewResult review, String token);

  Future<void> deleteReview(int id, String token);
}
