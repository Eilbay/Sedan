import 'package:optombai/data/models/block/block_model.dart';

abstract interface class IBlockRepository {
  /// POST /blocks/ — block a user. Idempotent: re-blocking returns
  /// the existing record. Body: { "user_id": ..., "reason": ... }.
  Future<BlockModel> blockUser({
    required String userId,
    String? reason,
    required String token,
  });

  /// DELETE /blocks/{user_id}/ — unblock. 204 on success, 404 if not blocked.
  Future<void> unblockUser({
    required String userId,
    required String token,
  });

  /// GET /blocks/ — paginated list of users I have blocked.
  Future<BlockListModel> fetchBlocks({
    required String token,
    int? page,
    int? pageSize,
    String? nextUrl,
  });
}
