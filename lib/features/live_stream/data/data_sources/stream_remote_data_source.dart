import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:optombai/core/error/stream_log_file.dart';
import 'package:optombai/data/domain_set.dart';
import 'package:optombai/features/live_stream/data/models/live_stream_model.dart';
import 'package:optombai/features/live_stream/data/models/stream_ban_model.dart';

class StreamRemoteDataSource {
  const StreamRemoteDataSource({required this.dio});

  final Dio dio;

  Options headers(String token) => Options(
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

  Future<StreamModel?> createStream({required String token}) async {
    try {
      final response = await dio.post(
        ApiEndpoints.streamsListApi,
        data: <String, dynamic>{'title': 'string', 'description': 'string'},
        options: headers(token),
      );
      final map = _asMap(response.data);
      if (map == null) return null;
      return StreamModel.fromJson(map);
    } on DioException catch (e, st) {
      _logDioError(
          scope: 'createStream',
          endpoint: ApiEndpoints.streamsListApi,
          error: e,
          stackTrace: st);
      rethrow;
    }
  }

  Future<StreamModel?> startStream({
    required String token,
    required String streamId,
  }) async {
    final url = '${ApiEndpoints.streamsListApi}$streamId/start/';
    try {
      final response = await dio.post(url, options: headers(token));
      final map = _asMap(response.data);
      if (map == null) return null;
      return StreamModel.fromJson(map);
    } on DioException catch (e, st) {
      _logDioError(
          scope: 'startStream', endpoint: url, error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<StreamModel?> endStream({
    required String token,
    required String streamId,
  }) async {
    final url = '${ApiEndpoints.streamsListApi}$streamId/end/';
    try {
      final response = await dio.post(url, options: headers(token));
      final map = _asMap(response.data);
      if (map == null) return null;
      return StreamModel.fromJson(map);
    } on DioException catch (e, st) {
      _logDioError(scope: 'endStream', endpoint: url, error: e, stackTrace: st);
      return null;
    }
  }

  /// Owner-only ping to keep the broadcast fresh on the server. Without it,
  /// the server falls back to a coarser `started_at`-based liveness check.
  Future<void> sendHeartbeat({
    required String token,
    required String streamId,
  }) async {
    final url = '${ApiEndpoints.streamsListApi}$streamId/heartbeat/';
    try {
      await dio.post(url, options: headers(token));
    } on DioException catch (e, st) {
      _logDioError(
          scope: 'sendHeartbeat', endpoint: url, error: e, stackTrace: st);
    }
  }

  Future<StreamModel?> getStream({required String streamId}) async {
    final url = '${ApiEndpoints.streamsListApi}$streamId/';
    try {
      final response = await dio.get(url);
      final map = _asMap(response.data);
      if (map == null) return null;
      return StreamModel.fromJson(map);
    } on DioException catch (e, st) {
      _logDioError(scope: 'getStream', endpoint: url, error: e, stackTrace: st);
      return null;
    }
  }

  Future<Streams?> getStreams({required String token}) async {
    final results = <StreamModel>[];
    dynamic firstPrevious;
    dynamic remainingNext;

    try {
      final requestOptions = token.isEmpty ? null : headers(token);
      var url = ApiEndpoints.streamsListApi;
      Map<String, dynamic>? query = const {
        'status': 'live',
        'page_size': 100,
      };
      final visitedUrls = <String>{};

      // Follow pagination defensively. Filtering/deduplication happens in the
      // presentation layer, so stopping at page one can otherwise produce an
      // empty list even while later pages contain valid broadcasts.
      for (var pageIndex = 0; pageIndex < 20; pageIndex++) {
        if (!visitedUrls.add(url)) break;
        final response = await dio.get(
          url,
          queryParameters: query,
          options: requestOptions,
        );

        if (response.statusCode != 200) break;

        final page = Streams.fromJson(response.data);
        if (pageIndex == 0) firstPrevious = page.previous;
        results.addAll(page.results);
        remainingNext = page.next;

        final nextUrl = page.next?.toString().trim() ?? '';
        if (nextUrl.isEmpty) break;
        url = nextUrl;
        query = null;
      }

      if (results.isEmpty && remainingNext == null) {
        return Streams(next: null, previous: firstPrevious, results: results);
      }
      return Streams(
        next: remainingNext,
        previous: firstPrevious,
        results: results,
      );
    } on DioException catch (e, st) {
      _logDioError(
        scope: 'getStreams',
        endpoint: ApiEndpoints.streamsListApi,
        error: e,
        stackTrace: st,
      );
      if (results.isNotEmpty) {
        return Streams(
          next: remainingNext,
          previous: firstPrevious,
          results: results,
        );
      }
      return null;
    } catch (e) {
      log('Error fetching streams: $e');
      return null;
    }
  }

  /// Check the stream detail directly. Searching only the first page of the
  /// live list falsely marks a valid stream ended as soon as it moves to a
  /// later page.
  Future<bool> isStreamLive({required String streamId}) async {
    final url = '${ApiEndpoints.streamsListApi}$streamId/';
    try {
      final response = await dio.get(url);

      if (response.statusCode == 200) {
        final map = _asMap(response.data);
        if (map == null) return true;
        final isLive = StreamModel.fromJson(map).isLive;
        debugPrint(
          '[StreamApi] isStreamLive($streamId) = $isLive (detail)',
        );
        return isLive;
      }
      return true;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return false;
      debugPrint('[StreamApi] isStreamLive error: $e');
      return true;
    } catch (e) {
      debugPrint('[StreamApi] isStreamLive error: $e');
      return true;
    }
  }

  Future<StreamBanModel?> banUser({
    required String token,
    required String streamId,
    required String userId,
    int? minutes,
    String? until,
    String? reason,
  }) async {
    final url = ApiEndpoints.streamBan(streamId);
    try {
      final body = <String, dynamic>{'user_id': userId};
      if (minutes != null) body['minutes'] = minutes;
      if (until != null) body['until'] = until;
      if (reason != null && reason.isNotEmpty) body['reason'] = reason;

      final response = await dio.post(url, data: body, options: headers(token));
      final map = _asMap(response.data);
      if (map == null) return null;
      return StreamBanModel.fromJson(map);
    } on DioException catch (e, st) {
      _logDioError(scope: 'banUser', endpoint: url, error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<void> unbanUser({
    required String token,
    required String streamId,
    required String userId,
  }) async {
    final url = ApiEndpoints.streamUnban(streamId);
    try {
      await dio.post(url, data: {'user_id': userId}, options: headers(token));
    } on DioException catch (e, st) {
      _logDioError(scope: 'unbanUser', endpoint: url, error: e, stackTrace: st);
      rethrow;
    }
  }

  void _logDioError({
    required String scope,
    required String endpoint,
    required DioException error,
    required StackTrace stackTrace,
  }) {
    final method = error.requestOptions.method;
    final status = error.response?.statusCode;
    final responseBody = _short(error.response?.data);
    final requestBody = _short(error.requestOptions.data);

    StreamLogFile.log(
      '[StreamApi][$scope] $method $endpoint -> status=$status, '
      'request=$requestBody, response=$responseBody, message=${error.message}',
      isWarning: true,
    );
    debugPrint(stackTrace.toString());
  }

  Map<String, dynamic>? _asMap(dynamic payload) {
    if (payload is Map<String, dynamic>) return payload;
    if (payload is Map) return Map<String, dynamic>.from(payload);
    return null;
  }

  String _short(Object? value, {int max = 700}) {
    final text = value?.toString() ?? 'null';
    if (text.length <= max) return text;
    return '${text.substring(0, max)}...';
  }
}
