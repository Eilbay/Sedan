import 'package:optombai/core/enums/request_type.dart';
import 'package:optombai/data/models/posts/post_model.dart';
import 'package:optombai/data/models/posts/post_media_v2.dart';
import 'package:optombai/data/models/media_file.dart';
import 'package:optombai/data/models/posts/posts_stats_by_owner.dart';

abstract interface class IProductRepository {
  Future<List<Product>> fetchDetailsBulk(List<String> ids);

  Future<PostModel> fetchProductsByFilter({
    String? category,
    String? owner,
    String? price,
    String? priceGte,
    String? priceLte,
    String? search,
    String? ordering,
    int? typeProduct,
    int? typeOwner,
    int? countryId,
    int? regionId,
    String? currency,
    int? limit,
    int? offset,
    int? page,
    int? pageSize,
    bool forceRefresh,
    String token,
    bool? isVideo,
  });

  Future<Product> getProductInfo(String? id);

  Future<List<Product>> sameProduct({String? category, int? typeProduct});

  Future<PostModel> fetchAllProduct({String? nextUrl, String token});

  Future<void> deleteProduct(String productId, String token);

  Future<void> deleteImage(int id, String token);

  Future<PostsStatsByOwnerType> fetchPostsStatsByOwnerType();

  Future<void> createProduct(String token, Product results,
      List<MediaFile> mediaFiles, EnumRequestType requestType);

  Future<void> uploadMedia(
      List<MediaFile> mediaFiles, String postId, String token);

  Future<String> createPost(
      String token, Product results, EnumRequestType requestType);

  Future<void> uploadMediaWithProgress(
    List<MediaFile> mediaFiles,
    String postId,
    String token, {
    void Function(int fileIndex, int totalFiles, double fileProgress)?
        onProgress,
  });

  Future<int> registerView({
    required String postId,
    required String authHeader,
  });

  /// v2 API: upload a single media file first, then reference it via
  /// `media_ids` when creating the post. Returns the new media id.
  Future<PostMediaV2> uploadPostMediaV2(
    MediaFile media,
    String token, {
    void Function(int sent, int total)? onSendProgress,
  });

  /// v2 API: atomically create a post with already-uploaded media ids.
  /// [clientRequestId] is a UUID v4 — the same value on retry returns
  /// the previously-created post (no duplicate). Returns post id (UUID).
  Future<String> createPostV2({
    required String token,
    required Product product,
    required List<int> mediaIds,
    required String clientRequestId,
  });

  /// v2 API: cancel an uploaded media file (e.g. user backed out).
  /// Not strictly required — server auto-cleans after 24h.
  Future<void> deletePostMediaV2(int mediaId, String token);
}
