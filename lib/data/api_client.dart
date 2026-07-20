import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:flutter/foundation.dart';
import 'package:optombai/configs/constrants.dart';
import 'package:optombai/core/debug/talker_instance.dart';
import 'package:optombai/services/config_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talker_dio_logger/talker_dio_logger.dart';
import 'package:talker_flutter/talker_flutter.dart';

class TimingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra['ts'] = DateTime.now().microsecondsSinceEpoch;
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final ts = response.requestOptions.extra['ts'] as int?;
    if (ts != null) {
      final ms = (DateTime.now().microsecondsSinceEpoch - ts) / 1000;
      debugPrint(
        'HTTP ${response.requestOptions.method} ${response.requestOptions.uri} -> ${ms.toStringAsFixed(0)} ms',
      );
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final ts = err.requestOptions.extra['ts'] as int?;
    if (ts != null) {
      final ms = (DateTime.now().microsecondsSinceEpoch - ts) / 1000;
      debugPrint(
        'HTTP ERR ${err.requestOptions.method} ${err.requestOptions.uri} -> ${ms.toStringAsFixed(0)} ms',
      );
    }
    handler.next(err);
  }
}

class RetryInterceptor extends Interceptor {
  final Dio dio;
  final int maxRetries;

  RetryInterceptor({required this.dio, this.maxRetries = 2});

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final statusCode = err.response?.statusCode ?? 0;
    final retryCount = (err.requestOptions.extra['retryCount'] as int?) ?? 0;

    // Skip retry for file uploads (MultipartFile streams can't be re-consumed)
    final noRetry = err.requestOptions.extra['noRetry'] == true;

    // Only retry on 5xx server errors, not on client errors or timeouts
    if (!noRetry && statusCode >= 500 && retryCount < maxRetries) {
      final delay = Duration(milliseconds: 300 * (retryCount + 1));
      await Future.delayed(delay);

      err.requestOptions.extra['retryCount'] = retryCount + 1;
      try {
        final response = await dio.fetch(err.requestOptions);
        return handler.resolve(response);
      } catch (_) {}
    }
    handler.next(err);
  }
}

/// Collapses oversized or HTML error bodies before they reach the loggers
/// and the error handler. A Django debug page (DEBUG=True on a 500) is
/// thousands of HTML lines — logging it verbatim floods the console and is
/// useless as an error payload. The page `<title>` already states the
/// exception, so it is kept as a concise one-line summary.
class ErrorBodyCompactor extends Interceptor {
  static const int _maxBodyLength = 1000;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final response = err.response;
    final data = response?.data;
    if (response != null && data is String) {
      response.data = _compact(data, response);
    }
    handler.next(err);
  }

  String _compact(String body, Response<dynamic> response) {
    final contentType = response.headers.value('content-type') ?? '';
    final looksHtml =
        contentType.contains('text/html') || body.trimLeft().startsWith('<');
    if (looksHtml) {
      final title = _htmlTitle(body);
      return title != null
          ? 'HTML error page — $title'
          : 'HTML error page (${body.length} chars)';
    }
    if (body.length > _maxBodyLength) {
      return '${body.substring(0, _maxBodyLength)}… '
          '(${body.length} chars, truncated)';
    }
    return body;
  }

  String? _htmlTitle(String html) {
    final match =
        RegExp(r'<title>(.*?)</title>', dotAll: true).firstMatch(html);
    final title = match?.group(1)?.trim();
    return (title != null && title.isNotEmpty) ? title : null;
  }
}

/// Rejects requests with empty Bearer tokens immediately, without sending
/// them to the server. Saves network round-trips for unauthenticated users.
class EmptyBearerInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final auth = options.headers['Authorization'];
    if (auth is String) {
      final token = auth.replaceFirst('Bearer ', '').trim();
      if (token.isEmpty) {
        handler.reject(
          DioException(
            requestOptions: options,
            response: Response(
              requestOptions: options,
              statusCode: 401,
              data: {'detail': 'No auth token'},
            ),
            type: DioExceptionType.badResponse,
          ),
          true,
        );
        return;
      }
    }
    handler.next(options);
  }
}

/// Reads the `exp` claim of a JWT to decide if it is already expired, so the
/// client can refresh proactively instead of paying a wasted 401 round-trip.
extension JwtExpiryX on String {
  bool get isJwtExpired {
    try {
      final parts = split('.');
      if (parts.length != 3) return false;
      var payload = parts[1].replaceAll('-', '+').replaceAll('_', '/');
      payload = payload.padRight((payload.length + 3) ~/ 4 * 4, '=');
      final claims = jsonDecode(utf8.decode(base64.decode(payload)));
      final exp = (claims is Map) ? claims['exp'] : null;
      if (exp is! int) return false;
      final expiry =
          DateTime.fromMillisecondsSinceEpoch(exp * 1000, isUtc: true);
      // 15s skew so a token about to expire mid-flight is refreshed up front.
      return DateTime.now()
          .toUtc()
          .isAfter(expiry.subtract(const Duration(seconds: 15)));
    } catch (_) {
      // Unparseable token — let the server be the authority (onError path).
      return false;
    }
  }
}

class TokenRefreshInterceptor extends QueuedInterceptor {
  final Dio dio;
  bool _isRefreshing = false;

  TokenRefreshInterceptor({required this.dio});

  /// True when an error means the session is terminally dead — the backend
  /// rejected the refresh token (401 / `token_not_valid`), as opposed to a
  /// transient network failure (no response). Used to decide whether to drop
  /// the stored tokens and fall back to anonymous access.
  bool _isDeadSession(Object error) {
    if (error is! DioException) return false;
    if (error.response?.statusCode == 401) return true;
    final data = error.response?.data;
    return data is Map && data['code'] == 'token_not_valid';
  }

  /// Proactive refresh: if a request carries a bearer whose stored token is
  /// already expired, refresh ONCE before sending. As a QueuedInterceptor this
  /// serializes startup traffic — the first request refreshes, the rest reuse
  /// the fresh token — so the cold-start flood skips the wasted 401→refresh
  /// round-trip entirely. Anonymous requests (no bearer) are never touched.
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final auth = options.headers['Authorization'];
    if (auth is! String || auth.replaceFirst('Bearer ', '').trim().isEmpty) {
      return handler.next(options);
    }
    if (options.path.contains('token/refresh')) {
      return handler.next(options);
    }

    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(TOKEN_KEY) ?? '';

    if (stored.isEmpty) {
      return handler.next(options);
    }
    // Stored token still valid (or already refreshed by an earlier queued
    // request) — adopt it and proceed without a network call.
    if (!stored.isJwtExpired) {
      options.headers['Authorization'] = 'Bearer $stored';
      return handler.next(options);
    }

    final refreshToken = prefs.getString(REFRESH_TOKEN_KEY) ?? '';
    if (refreshToken.isEmpty) {
      return handler.next(options);
    }

    try {
      final refreshDio = Dio(BaseOptions(
        baseUrl: dio.options.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ));
      final response = await refreshDio.post(
        '${ConfigService.getApiUrl()}/accounts/token/refresh/',
        data: {'refresh': refreshToken},
      );
      final newAccess = response.data['access'] as String;
      await prefs.setString(TOKEN_KEY, newAccess);
      options.headers['Authorization'] = 'Bearer $newAccess';
    } catch (e) {
      // Dead refresh token → drop creds and let this request go anonymous.
      // Transient failure → keep the (stale) token; the onError 401 path is
      // the fallback and a flaky network never logs the user out.
      if (_isDeadSession(e)) {
        await prefs.remove(TOKEN_KEY);
        await prefs.remove(REFRESH_TOKEN_KEY);
        // Keep the registration flag in sync with the (now absent) token so
        // auth gates (e.g. the profile tab) treat the user as a guest.
        await prefs.setBool(REGISTER_KEY, false);
        options.headers.remove('Authorization');
        talker.warning(
            '[AUTH] Proactive refresh: session expired — anonymous mode');
      }
    }
    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode != 401) {
      return handler.next(err);
    }

    // Skip if this IS the refresh request itself
    if (err.requestOptions.path.contains('token/refresh')) {
      return handler.next(err);
    }

    final prefs = await SharedPreferences.getInstance();
    final refreshToken = prefs.getString(REFRESH_TOKEN_KEY) ?? '';
    if (refreshToken.isEmpty) {
      return handler.next(err);
    }

    if (!_isRefreshing) {
      _isRefreshing = true;

      // Step 1 — refresh the access token.
      String newAccess;
      try {
        final refreshDio = Dio(BaseOptions(
          baseUrl: dio.options.baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ));

        final response = await refreshDio.post(
          '${ConfigService.getApiUrl()}/accounts/token/refresh/',
          data: {'refresh': refreshToken},
        );

        newAccess = response.data['access'] as String;
        await prefs.setString(TOKEN_KEY, newAccess);
      } catch (e) {
        _isRefreshing = false;
        // If the refresh token itself is dead (server rejected it with 401 /
        // token_not_valid), the session is terminally expired. Clear the dead
        // tokens so every subsequent request falls back to ANONYMOUS access —
        // the public feeds (posts, reels-feed) return 200 without a token, so
        // the user keeps browsing instead of staring at empty screens while the
        // app loops 401s with a token the backend will never accept again.
        // A transient/network refresh failure keeps the tokens so a flaky
        // connection never logs the user out.
        if (_isDeadSession(e)) {
          await prefs.remove(TOKEN_KEY);
          await prefs.remove(REFRESH_TOKEN_KEY);
          // Keep the registration flag in sync with the (now absent) token so
          // auth gates (e.g. the profile tab) treat the user as a guest.
          await prefs.setBool(REGISTER_KEY, false);
          talker.warning(
              '[AUTH] Session expired — cleared dead tokens, anonymous mode');
          // Replay the triggering request without auth so public content loads
          // right away. Auth-only endpoints still 401 (expected) and surface
          // their own error.
          try {
            err.requestOptions.headers.remove('Authorization');
            final data = err.requestOptions.data;
            if (data is FormData) err.requestOptions.data = data.clone();
            final anonResponse = await dio.fetch(err.requestOptions);
            return handler.resolve(anonResponse);
          } catch (_) {
            return handler.next(err);
          }
        }
        return handler.next(err);
      }

      // Step 2 — replay the original request with the new token.
      try {
        err.requestOptions.headers['Authorization'] = 'Bearer $newAccess';

        // FormData is a single-use stream consumed by the first send.
        // dio.fetch() on an already-finalized FormData throws, so the
        // body must be cloned before the retry (chat sendMessage and
        // every multipart upload hit this path).
        final data = err.requestOptions.data;
        if (data is FormData) {
          err.requestOptions.data = data.clone();
        }

        final retryResponse = await dio.fetch(err.requestOptions);
        _isRefreshing = false;
        return handler.resolve(retryResponse);
      } catch (e, st) {
        // Token is valid now, but replaying the request failed (e.g. a
        // file attachment is gone, or clone() failed). Do NOT surface
        // the stale 401 — that would wrongly tell the user to log in
        // again. Return a clear, retryable error instead.
        _isRefreshing = false;
        talker.handle(e, st, 'Request replay after token refresh failed');
        return handler.reject(
          DioException(
            requestOptions: err.requestOptions,
            response: Response(
              requestOptions: err.requestOptions,
              statusCode: 400,
              data: {'detail': 'Не удалось выполнить запрос, повторите попытку'},
            ),
            type: DioExceptionType.badResponse,
          ),
        );
      }
    }

    return handler.next(err);
  }
}

/// Coalesces identical in-flight GET requests. Two call sites asking for the
/// same URL in the same frame (e.g. `settings/currencies` fired twice at app
/// start) would otherwise both hit the network — Dio's cache only dedupes
/// *completed* responses, never concurrent ones. The first request goes to the
/// network; any duplicate arriving while it is still in flight rides on the
/// same result. Only GETs are coalesced — mutating verbs always run.
class InFlightGetDedupInterceptor extends Interceptor {
  static const String _tag = '_dedupKey';

  final Map<String, Completer<Response>> _inFlight = {};

  String _key(RequestOptions o) =>
      '${o.method}|${o.uri}|${o.headers['Authorization'] ?? ''}';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (options.method.toUpperCase() != 'GET') {
      return handler.next(options);
    }
    // A retry / refresh-replay reuses the same options object that is already
    // the in-flight primary — let it pass, else it would wait on its own
    // completer and deadlock.
    if (options.extra.containsKey(_tag)) {
      return handler.next(options);
    }

    final key = _key(options);
    final existing = _inFlight[key];
    if (existing != null) {
      // Duplicate — ride on the primary. Time-bounded so a missed completion
      // can never hang the caller; on timeout/failure it runs for real.
      existing.future.timeout(const Duration(seconds: 12)).then((response) {
        handler.resolve(Response(
          requestOptions: options,
          data: response.data,
          statusCode: response.statusCode,
          statusMessage: response.statusMessage,
          headers: response.headers,
          extra: response.extra,
        ));
      }).catchError((_) {
        options.extra[_tag] = key;
        _inFlight[key] = Completer<Response>();
        handler.next(options);
      });
      return;
    }

    options.extra[_tag] = key;
    _inFlight[key] = Completer<Response>();
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _settle(response.requestOptions, (c) => c.complete(response));
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _settle(err.requestOptions, (c) => c.completeError(err));
    handler.next(err);
  }

  void _settle(
    RequestOptions o,
    void Function(Completer<Response>) action,
  ) {
    final key = o.extra[_tag] as String?;
    if (key == null) return;
    final completer = _inFlight.remove(key);
    if (completer != null && !completer.isCompleted) action(completer);
  }
}

class ApiClient {
  ApiClient._internal() {
    _cacheOptions = CacheOptions(
      store: MemCacheStore(maxSize: 50 * 1024 * 1024, maxEntrySize: 2 * 1024 * 1024),
      policy: CachePolicy.request,
      maxStale: const Duration(minutes: 5),
      hitCacheOnErrorExcept: [401, 403],
    );

    dio = Dio(BaseOptions(
      baseUrl: 'https://optombai.com',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      headers: const {
        'Connection': 'keep-alive',
        'Accept-Encoding': 'gzip',
      },
    ));

    dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () {
        final c = HttpClient();
        c.idleTimeout = const Duration(seconds: 20);
        c.maxConnectionsPerHost = 8;
        return c;
      },
    );

    dio.interceptors.add(EmptyBearerInterceptor());
    dio.interceptors.add(TokenRefreshInterceptor(dio: dio));
    dio.interceptors.add(RetryInterceptor(dio: dio));
    // Compact HTML/oversized error bodies before the loggers print them.
    dio.interceptors.add(ErrorBodyCompactor());
    // Collapse concurrent identical GETs (runs before the cache so truly
    // simultaneous duplicates — which both miss the cache — are coalesced).
    dio.interceptors.add(InFlightGetDedupInterceptor());
    dio.interceptors.add(DioCacheInterceptor(options: _cacheOptions));
    dio.interceptors.add(TimingInterceptor());

    // Single HTTP logger. Feeds all traffic into the Talker history so the
    // debug screen (profile > 7-tap on version) can inspect requests,
    // responses, and errors across release and debug builds.
    //
    // Headers are dropped from the console — they carry the long Bearer
    // token and gzip boilerplate that bury the useful lines and make logs
    // hard to copy. Colour pens mark success vs failure at a glance.
    dio.interceptors.add(TalkerDioLogger(
      talker: talker,
      settings: TalkerDioLoggerSettings(
        printRequestHeaders: false,
        printResponseHeaders: false,
        printErrorHeaders: false,
        printRequestData: true,
        printResponseData: true,
        printResponseMessage: true,
        printErrorData: true,
        printErrorMessage: true,
        requestPen: AnsiPen()..gray(level: 0.5),
        responsePen: AnsiPen()..green(),
        errorPen: AnsiPen()..red(),
      ),
    ));
  }

  static final ApiClient I = ApiClient._internal();
  late final Dio dio;
  late final CacheOptions _cacheOptions;

  /// Cache options for GET requests (default — cache with 5min stale)
  CacheOptions get cacheOptions => _cacheOptions;

  /// Dio [Options] that force a single GET to hit the network and ignore any
  /// cached entry (the fresh response is still stored). Use for explicit
  /// refreshes — pull-to-refresh, or the post-block feed reload — where a
  /// stale cached page would otherwise mask server-side changes such as
  /// block filtering.
  Options get forceRefreshOptions =>
      _cacheOptions.copyWith(policy: CachePolicy.refresh).toOptions();

  /// Clear all cached responses
  Future<void> clearCache() async {
    await _cacheOptions.store?.clean();
  }
}
