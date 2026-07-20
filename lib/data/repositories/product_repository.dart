import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:optombai/core/debug/talker_instance.dart';
import 'package:optombai/core/error/app_exception.dart';
import 'package:optombai/data/api_client.dart';
import 'package:optombai/core/enums/request_type.dart';
import 'package:optombai/data/domain_set.dart';
import 'package:optombai/data/models/posts/post_model.dart';
import 'package:optombai/data/models/posts/post_media_v2.dart';
import 'package:optombai/data/models/media_file.dart';
import 'package:optombai/data/models/posts/posts_stats_by_owner.dart';
import 'package:optombai/data/repositories/i_product_repository.dart';

String get _uploadPhotoApi => ApiEndpoints.postsImagesApi;
String get _endpointPostApi => ApiEndpoints.postsApi;
// v2 list serializer returns `currency` per post (v1 list/detail omit it
// entirely) and otherwise matches v1's field set and filter query params
// 1:1 (verified via curl). The `currency` query param now converts price
// AND currency together for every item in the response, Lalafo-style
// (verified via curl 2026-07-07: a native-USD post is unaffected by
// ?currency=USD, converts to KGS-equivalent price + currency=KGS under
// ?currency=KGS, and native-KGS posts convert to USD under ?currency=USD —
// price and currency always stay consistent with each other now).
String get _endpointPostFeedApi => ApiEndpoints.postsApiV2;

class ProductRepository implements IProductRepository {
  final Dio _dio = ApiClient.I.dio;

  Future<List<Product>> fetchDetailsBulk(List<String> ids) async {
    return Future.wait(ids.map(getProductInfo));
  }

  Map<String, dynamic> _clean(Map<String, dynamic> src) {
    final out = <String, dynamic>{};
    src.forEach((k, v) {
      if (v == null) return;
      if (v is String && v.trim().isEmpty) return;
      out[k] = v;
    });
    return out;
  }

  /// Options for a feed GET. Attaches the bearer token when present (the
  /// backend needs it to apply per-user block filtering — an anonymous feed
  /// request returns blocked authors), and the cache-bypass policy on a
  /// forced refresh. Returns null for an anonymous, cacheable read.
  Options? _feedOptions({required String token, required bool forceRefresh}) {
    final base = forceRefresh ? ApiClient.I.forceRefreshOptions : null;
    if (token.isEmpty) return base;
    return (base ?? Options())
        .copyWith(headers: {'Authorization': 'Bearer $token'});
  }

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
    bool forceRefresh = false,
    String token = '',
    bool? isVideo,
  }) async {
    try {
      if (typeOwner == 0) typeOwner = null;

      if (typeProduct == null) {
        debugPrint(
            '[PRELOAD] fetchProductsByFilter WITHOUT typeProduct! caller:');
        debugPrint(StackTrace.current.toString());
      }

      final pageSize = limit ?? 20;

      final response = await _dio.get(
        _endpointPostFeedApi,
        queryParameters: _clean({
          'category': category,
          'owner': owner,
          'price': price,
          'price__gte': priceGte != null ? double.tryParse(priceGte) : null,
          'price__lte': priceLte != null ? double.tryParse(priceLte) : null,
          'search': search,
          'ordering': ordering,
          'product_type': typeProduct,
          'owner__user_type': typeOwner,
          'owner__country': countryId,
          'region': regionId,
          'currency': currency,
          'page_size': pageSize,
          'page': page,
          // Photo/Video tabs: server-side media filter (true=video, false=photo).
          if (isVideo != null) 'is_video': isVideo,
        }),
        // The feed must be requested WITH the auth token so the backend can
        // apply per-user block filtering (an anonymous request returns blocked
        // authors). A forced refresh additionally bypasses the 5-min cache so
        // a just-blocked author is dropped immediately.
        options: _feedOptions(token: token, forceRefresh: forceRefresh),
      );

      return PostModel.fromJson(
          Map<String, dynamic>.from(response.data as Map));
    } on DioException catch (e) {
      if (_isPaginationOutOfRange(e)) return const PostModel();
      throw ErrorHandler.handle(e);
    }
  }

  Future<Product> getProductInfo(String? id) async {
    try {
      final productId = id?.trim() ?? '';
      if (productId.isEmpty) return Product();

      // Prefer the v2 detail serializer so the item detail screen uses the
      // same price/currency shape as the v2 list feed. Keep a v1 fallback for
      // compatibility with older deployments that may not expose v2 detail yet.
      try {
        final res = await _dio.get('${ApiEndpoints.postsApiV2}$productId/');
        return Product.fromJson(Map<String, dynamic>.from(res.data as Map));
      } on DioException catch (e) {
        if (!_shouldFallbackToV1Detail(e)) rethrow;
        debugPrint(
          '[PRODUCT] v2 detail missing for $productId, falling back to v1',
        );
      }

      final res = await _dio.get("$_endpointPostApi$productId/");
      return Product.fromJson(Map<String, dynamic>.from(res.data as Map));
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  bool _shouldFallbackToV1Detail(DioException e) {
    final status = e.response?.statusCode;
    if (status != 404 && status != 405) return false;
    final data = e.response?.data;
    if (data is Map) {
      final detail = data['detail']?.toString().toLowerCase() ?? '';
      return detail.contains('not found') || detail.contains('не найдены');
    }
    return true;
  }

  Future<List<Product>> sameProduct(
      {String? category, int? typeProduct}) async {
    try {
      final response = await _dio.get(_endpointPostApi, queryParameters: {
        'category': category,
        "product_type": typeProduct,
      });

      var list = response.data["results"]
          .map((item) => Product.fromJson(item))
          .cast<Product>()
          .toList();

      return list;
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<PostModel> fetchAllProduct(
      {String? nextUrl, String token = ''}) async {
    try {
      final response = await _dio.get(
        nextUrl ?? _endpointPostFeedApi,
        options: _feedOptions(token: token, forceRefresh: false),
      );
      return PostModel.fromJson(response.data);
    } on DioException catch (e) {
      if (_isPaginationOutOfRange(e)) return const PostModel();
      throw ErrorHandler.handle(e);
    }
  }

  /// Backend returns `404 { detail: "Посты не найдены" }` instead of an
  /// empty page when callers request a page beyond the last one. Map that
  /// to an empty `PostModel` so list/profile pagination stops cleanly
  /// instead of surfacing a phantom error.
  bool _isPaginationOutOfRange(DioException e) {
    if (e.response?.statusCode != 404) return false;
    final data = e.response?.data;
    if (data is! Map) return false;
    final detail = data['detail']?.toString() ?? '';
    return detail.contains('не найдены') || detail.contains('not found');
  }

  Future<void> deleteProduct(String productId, String token) async {
    try {
      await _dio.delete("$_endpointPostApi$productId/",
          options: options(token));
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<void> deleteImage(int id, String token) async {
    try {
      await _dio.delete("$_uploadPhotoApi$id/", options: options(token));
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<PostsStatsByOwnerType> fetchPostsStatsByOwnerType() async {
    try {
      final res = await _dio.get("${_endpointPostApi}stats/by-owner-type/");
      return PostsStatsByOwnerType.fromJson(
        Map<String, dynamic>.from(res.data as Map),
      );
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<void> createProduct(String token, Product results,
      List<MediaFile> mediaFiles, EnumRequestType requestType) async {
    try {
      var map = results.toJson();

      if (requestType == EnumRequestType.post) {
        final response = await _dio.post(
          _endpointPostApi,
          data: FormData.fromMap(map),
          options: optionsFormData(token),
        );
        final String id = response.data["id"];
        await uploadMedia(mediaFiles, id, token);
      }

      if (requestType == EnumRequestType.patch) {
        final response = await _dio.patch(
          '$_endpointPostApi${results.id}/',
          data: map,
          options: options(token),
        );
        final String id = response.data["id"];
        await uploadMedia(mediaFiles, id, token);
      }
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  @override
  Future<String> createPost(
      String token, Product results, EnumRequestType requestType) async {
    try {
      final map = results.toJson();

      if (requestType == EnumRequestType.post) {
        final response = await _dio.post(
          _endpointPostApi,
          data: FormData.fromMap(map),
          options: optionsFormData(token),
        );
        return response.data["id"] as String;
      }

      if (requestType == EnumRequestType.patch) {
        final response = await _dio.patch(
          '$_endpointPostApi${results.id}/',
          data: map,
          options: options(token),
        );
        return response.data["id"] as String;
      }

      throw const ServerException(message: 'Invalid request type');
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  @override
  Future<void> uploadMediaWithProgress(
    List<MediaFile> mediaFiles,
    String postId,
    String token, {
    void Function(int fileIndex, int totalFiles, double fileProgress)?
        onProgress,
  }) async {
    for (int i = 0; i < mediaFiles.length; i++) {
      await _uploadMediaFile(
        mediaFiles[i],
        postId,
        token,
        onSendProgress: (sent, total) {
          if (total > 0) {
            onProgress?.call(i, mediaFiles.length, sent / total);
          }
        },
      );
      onProgress?.call(i + 1, mediaFiles.length, 1.0);
    }
  }

  Future<void> uploadMedia(
      List<MediaFile> mediaFiles, String postId, String token) async {
    await Future.wait(
      mediaFiles.map((file) => _uploadMediaFile(file, postId, token)),
    );
  }

  /// Aborts an upload if no bytes are sent for this long — protects
  /// against silent stalls on weak connections where TCP stays open
  /// but throughput is zero.
  ///
  /// Set just under the backend's ~30s body-read timeout on
  /// `POST /v2/post-media/` — that way we cancel client-side first and
  /// surface a clear actionable message instead of a generic socket
  /// error after the server has already dropped the connection.
  static const _stallTimeout = Duration(seconds: 25);

  /// Send timeout per upload attempt. Large videos over mobile data routinely
  /// need more than the previous 5 min, so a slow-but-progressing upload was
  /// being killed prematurely. Raised here; genuinely stuck uploads (zero
  /// throughput) are still aborted far sooner by the stall watchdog
  /// ([_stallTimeout]).
  static const _uploadSendTimeout = Duration(minutes: 15);

  /// Max attempts for a single media upload before the error is surfaced.
  /// Retries only cover transient socket drops / send timeouts on flaky
  /// mobile networks (see [_isRetryableUploadError]).
  static const _maxUploadAttempts = 3;

  /// Transient upload failures worth retrying — socket drops, send timeouts,
  /// and stall-watchdog cancels. A 413 (too large) or other badResponse is
  /// deterministic, so retrying it would only waste the user's data.
  bool _isRetryableUploadError(DioException e) {
    if (e.type == DioExceptionType.cancel && e.error == 'stall_timeout') {
      return true;
    }
    return _isSocketDropped(e);
  }

  /// Server-side body-read timeout / peer reset closing the connection
  /// mid-upload. Dio surfaces this as connectionError / connectionTimeout /
  /// sendTimeout, or as `unknown` with no response when the raw socket is
  /// reset (observed: type=unknown, status=null, sent=104MB of 224MB).
  bool _isSocketDropped(DioException e) =>
      e.type == DioExceptionType.connectionError ||
      e.type == DioExceptionType.connectionTimeout ||
      e.type == DioExceptionType.sendTimeout ||
      (e.type == DioExceptionType.unknown && e.response == null);

  /// Translates a failed media upload into a user-facing [AppException],
  /// including the file size and any server `detail`.
  AppException _mapUploadError(DioException e, MediaFile media) {
    final what = media.isVideo ? 'видео' : 'файл';
    final sizeLabel = media.formattedSize;
    final body = e.response?.data;
    final serverDetail = body is Map && body['detail'] is String
        ? body['detail'] as String
        : null;

    if (e.type == DioExceptionType.cancel && e.error == 'stall_timeout') {
      return NetworkException(
        message:
            'Слабый интернет — загрузка прервана ($sizeLabel). Подключитесь '
            'к Wi-Fi или уменьшите $what и попробуйте снова.',
      );
    }
    // Server explicitly rejects the body as too large. Some proxy configs
    // answer with 413 instead of silently dropping the socket.
    if (e.response?.statusCode == 413) {
      return NetworkException(
        message: serverDetail != null
            ? 'Сервер отклонил $what ($sizeLabel): $serverDetail'
            : 'Сервер отклонил $what — слишком большой файл ($sizeLabel). '
                'Уменьшите размер или длительность и попробуйте снова.',
      );
    }
    if (_isSocketDropped(e)) {
      return NetworkException(
        message: 'Сервер прервал загрузку $what ($sizeLabel) — возможно, файл '
            'слишком большой или сеть нестабильна. Подключитесь к Wi-Fi '
            'или уменьшите файл.',
      );
    }
    return ErrorHandler.handle(e);
  }

  Future<void> _uploadMediaFile(
    MediaFile media,
    String post,
    String token, {
    void Function(int sent, int total)? onSendProgress,
  }) async {
    final cancelToken = CancelToken();
    var lastSent = 0;
    var lastProgressAt = DateTime.now();
    Timer? watchdog;

    try {
      final filename = media.file.path.split('/').last;
      final contentType = _resolveContentType(filename, media.isVideo);

      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          media.file.path,
          filename: filename,
          contentType: contentType,
        ),
        'post': post,
      });

      // Don't set Content-Type manually — Dio auto-adds the correct
      // multipart/form-data with boundary when data is FormData.
      // Skip retries via extra flag — MultipartFile streams can't be re-consumed.
      final uploadOptions = Options(
        headers: {'Authorization': 'Bearer $token'},
        sendTimeout: _uploadSendTimeout,
        receiveTimeout: const Duration(minutes: 2),
        extra: {'noRetry': true},
      );

      watchdog = Timer.periodic(const Duration(seconds: 5), (_) {
        if (DateTime.now().difference(lastProgressAt) > _stallTimeout) {
          cancelToken.cancel('stall_timeout');
        }
      });

      final response = await _dio.post(
        _uploadPhotoApi,
        data: formData,
        options: uploadOptions,
        cancelToken: cancelToken,
        onSendProgress: (sent, total) {
          if (sent > lastSent) {
            lastSent = sent;
            lastProgressAt = DateTime.now();
          }
          onSendProgress?.call(sent, total);
        },
      );
      PostImage.fromJson(response.data);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel && e.error == 'stall_timeout') {
        throw const NetworkException(
          message: 'Слабый интернет — загрузка прервана. Подключитесь к Wi-Fi '
              'или уменьшите файл и попробуйте снова.',
        );
      }
      // Server explicitly rejects the body as too large. Some proxy configs
      // answer with 413 instead of silently dropping the socket.
      if (e.response?.statusCode == 413) {
        throw const NetworkException(
          message: 'Видео слишком большое для загрузки. Уменьшите размер или '
              'длительность видео и попробуйте снова.',
        );
      }
      // Server-side body-read timeout (~30s) closes the connection mid-upload.
      // Dio surfaces this as connectionError / connectionTimeout / sendTimeout,
      // or as `unknown` with no response when the peer resets the raw socket
      // (observed: type=unknown, status=null, sent=104MB of 224MB). Translate
      // all of these to the same actionable message the stall watchdog uses.
      final socketDropped = e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          (e.type == DioExceptionType.unknown && e.response == null);
      if (socketDropped) {
        throw const NetworkException(
          message: 'Сервер прервал загрузку — файл слишком большой или сеть '
              'нестабильна. Подключитесь к Wi-Fi или уменьшите файл.',
        );
      }
      throw ErrorHandler.handle(e);
    } finally {
      watchdog?.cancel();
    }
  }

  static DioMediaType _resolveContentType(String filename, bool isVideo) {
    final ext = filename.split('.').last.toLowerCase();
    if (isVideo) {
      return switch (ext) {
        'mp4' || 'm4v' => DioMediaType.parse('video/mp4'),
        'mov' => DioMediaType.parse('video/quicktime'),
        'webm' => DioMediaType.parse('video/webm'),
        'avi' => DioMediaType.parse('video/x-msvideo'),
        '3gp' => DioMediaType.parse('video/3gpp'),
        'mkv' => DioMediaType.parse('video/x-matroska'),
        _ => DioMediaType.parse('video/mp4'),
      };
    }
    return switch (ext) {
      'png' => DioMediaType.parse('image/png'),
      'webp' => DioMediaType.parse('image/webp'),
      'gif' => DioMediaType.parse('image/gif'),
      'heic' || 'heif' => DioMediaType.parse('image/heic'),
      _ => DioMediaType.parse('image/jpeg'),
    };
  }

  Future<int> registerView({
    required String postId,
    required String authHeader,
  }) async {
    try {
      final res = await _dio.post(
        "$_endpointPostApi$postId/view/",
        data: const {},
        options: Options(
          headers: {'Authorization': 'Bearer $authHeader'},
          responseType: ResponseType.json,
          validateStatus: (code) => code != null && code < 500,
        ),
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        final data = Map<String, dynamic>.from(res.data as Map);
        return _asIntLocal(data['views']);
      }
      throw DioException(
        requestOptions: res.requestOptions,
        response: res,
        type: DioExceptionType.badResponse,
      );
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // v2 upload flow: media-first, then atomic post create.
  // ─────────────────────────────────────────────────────────────────

  @override
  Future<PostMediaV2> uploadPostMediaV2(
    MediaFile media,
    String token, {
    void Function(int sent, int total)? onSendProgress,
  }) async {
    final filename = media.file.path.split('/').last;
    final contentType = _resolveContentType(filename, media.isVideo);

    DioException? lastError;
    for (var attempt = 1; attempt <= _maxUploadAttempts; attempt++) {
      final cancelToken = CancelToken();
      var lastSent = 0;
      var lastProgressAt = DateTime.now();
      Timer? watchdog;
      try {
        // Rebuild FormData each attempt — a MultipartFile stream is consumed
        // on send and cannot be replayed, so a retry needs a fresh one.
        final formData = FormData.fromMap({
          'image': await MultipartFile.fromFile(
            media.file.path,
            filename: filename,
            contentType: contentType,
          ),
        });

        final uploadOptions = Options(
          headers: {'Authorization': 'Bearer $token'},
          sendTimeout: _uploadSendTimeout,
          receiveTimeout: const Duration(minutes: 2),
          extra: {'noRetry': true},
        );

        watchdog = Timer.periodic(const Duration(seconds: 5), (_) {
          if (DateTime.now().difference(lastProgressAt) > _stallTimeout) {
            cancelToken.cancel('stall_timeout');
          }
        });

        final response = await _dio.post(
          ApiEndpoints.postMediaApiV2,
          data: formData,
          options: uploadOptions,
          cancelToken: cancelToken,
          onSendProgress: (sent, total) {
            if (sent > lastSent) {
              lastSent = sent;
              lastProgressAt = DateTime.now();
            }
            onSendProgress?.call(sent, total);
          },
        );
        final parsed =
            PostMediaV2.fromJson(response.data as Map<String, dynamic>);
        talker.info(
          '[UPLOAD] /v2/post-media/ OK | id=${parsed.id} '
          'isVideo=${parsed.isVideo} bytes=$lastSent attempt=$attempt',
        );
        return parsed;
      } on DioException catch (e) {
        lastError = e;
        final retryable = _isRetryableUploadError(e);
        talker.warning(
          '[UPLOAD] /v2/post-media/ attempt $attempt/$_maxUploadAttempts FAIL | '
          'status=${e.response?.statusCode} type=${e.type} sent=$lastSent '
          'size=${media.formattedSize} retryable=$retryable err=${e.message} '
          'cause=${e.error} (${e.error.runtimeType})',
        );
        if (retryable && attempt < _maxUploadAttempts) {
          // Linear backoff lets a transient network blip clear before retry.
          await Future<void>.delayed(Duration(seconds: 2 * attempt));
          continue;
        }
        throw _mapUploadError(e, media);
      } finally {
        watchdog?.cancel();
      }
    }
    // The loop always returns or throws above; this satisfies the analyzer.
    throw _mapUploadError(lastError!, media);
  }

  @override
  Future<String> createPostV2({
    required String token,
    required Product product,
    required List<int> mediaIds,
    required String clientRequestId,
  }) async {
    try {
      // Explicit whitelist of fields v2 accepts. Verified via curl:
      // sending Category objects / created_at / null fields triggers
      // 400. We keep things tight and only forward what the v2 spec
      // documents, plus media_ids + client_request_id.
      final body = <String, dynamic>{
        if (product.name.isNotEmpty) 'name': product.name,
        if (product.description.isNotEmpty) 'description': product.description,
        // Server expects price as a decimal string ("100.00"), not number.
        if (product.price != null) 'price': product.price!.toStringAsFixed(2),
        if (product.category?.isNotEmpty == true) 'category': product.category,
        if (product.postType?.isNotEmpty == true)
          'product_type': product.postType,
        // Verified via curl: v2 accepts `currency` on create and echoes it
        // back in the response, even though it was previously missing from
        // this whitelist (product.currency was silently dropped).
        'currency': product.currency,
        'media_ids': mediaIds,
        'client_request_id': clientRequestId,
      };

      final response = await _dio.post(
        ApiEndpoints.postsApiV2,
        data: body,
        options: options(token),
      );
      final data = response.data as Map<String, dynamic>;
      final postId = (data['id'] ?? '').toString();
      talker.info(
        '[UPLOAD] /v2/posts/ OK | status=${response.statusCode} postId=$postId '
        'reqId=$clientRequestId mediaCount=${mediaIds.length}',
      );
      return postId;
    } on DioException catch (e) {
      talker.warning(
        '[UPLOAD] /v2/posts/ FAIL | status=${e.response?.statusCode} '
        'reqId=$clientRequestId media_ids=$mediaIds '
        'body=${e.response?.data} err=${e.message}',
      );
      throw ErrorHandler.handle(e);
    }
  }

  @override
  Future<void> deletePostMediaV2(int mediaId, String token) async {
    try {
      await _dio.delete(
        '${ApiEndpoints.postMediaApiV2}$mediaId/',
        options: options(token),
      );
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }
}

int _asIntLocal(dynamic v, {int fallback = 0}) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? fallback;
  return fallback;
}
