import 'package:dio/dio.dart';

/// Base exception type for all domain-layer errors.
sealed class AppException implements Exception {
  const AppException({required this.message, this.statusCode});

  final String message;
  final int? statusCode;

  /// Returns user-facing error messages parsed from the original error.
  List<String> get messages => [message];

  @override
  String toString() => '$runtimeType($message)';
}

/// No network connectivity or request timed out.
class NetworkException extends AppException {
  const NetworkException({super.message = 'Network error', super.statusCode});
}

/// Server returned an error response (4xx / 5xx).
class ServerException extends AppException {
  const ServerException({
    required super.message,
    super.statusCode,
    this.errors = const [],
  });

  /// Structured error messages parsed from the response body.
  final List<String> errors;

  @override
  List<String> get messages => errors.isNotEmpty ? errors : [message];
}

/// 401 / 403 — user must re-authenticate.
class AuthException extends AppException {
  const AuthException({
    super.message = 'Authentication required',
    super.statusCode,
  });

  bool get isExitRequired => statusCode == 403;
}

/// 403 with `code: BLOCKED` — current user is blocked by the target,
/// or the target was blocked by current user, so the action is forbidden.
/// Does NOT mean the user should be logged out.
class BlockedException extends AppException {
  const BlockedException({
    super.message = 'You cannot interact with this user',
    super.statusCode = 403,
  });
}

/// 404 — requested resource not found.
class NotFoundException extends AppException {
  const NotFoundException({
    super.message = 'Resource not found',
    super.statusCode = 404,
  });
}

/// Client-side validation error (not from server).
class ValidationException extends AppException {
  const ValidationException({required super.message});
}

/// Converts [DioException] into a typed [AppException].
class ErrorHandler {
  const ErrorHandler._();

  static AppException handle(DioException e) {
    final response = e.response;
    final statusCode = response?.statusCode;

    // Connection / timeout errors
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      return const NetworkException();
    }

    if (response == null) {
      return NetworkException(message: e.message ?? 'Network error');
    }

    // 401 — token missing/expired, the user must re-authenticate.
    if (statusCode == 401) {
      return const AuthException(statusCode: 401);
    }

    // 403 — forbidden. This is a permission / domain error, NOT a dead
    // session (DRF returns 401 for auth failures). The body always
    // carries a human-readable `detail` — it must reach the user, never
    // be replaced with a generic auth message or trigger a logout.
    if (statusCode == 403) {
      final body = response.data;
      final detail = body is Map ? body['detail'] : null;
      final message = detail is String && detail.isNotEmpty ? detail : null;

      // Moderation blocks are flagged explicitly by the backend.
      if (body is Map && body['code'] == 'BLOCKED') {
        return BlockedException(
          message: message ?? 'Вы не можете писать этому пользователю',
        );
      }

      // Any other 403 — surface the server's reason verbatim.
      return ServerException(
        message: message ?? 'Действие недоступно',
        statusCode: 403,
      );
    }

    // Not found
    if (statusCode == 404) {
      return const NotFoundException();
    }

    // Parse structured error messages from response body
    final errors = _parseErrors(response.data);

    return ServerException(
      message: errors.firstOrNull ?? 'Server error ($statusCode)',
      statusCode: statusCode,
      errors: errors,
    );
  }

  /// Parses error messages from various API response formats.
  static List<String> _parseErrors(dynamic data) {
    if (data == null) return const [];

    if (data is String) return [data];

    if (data is Map) {
      // Backend wraps DRF validation errors as
      // {"detail":"Проверьте правильность...","code":"validation_error","fields":{"phone":["..."],"email":["..."]}}
      // The generic `detail` is useless — surface the per-field messages
      // so the user actually knows what to fix.
      final fields = data['fields'];
      if (fields is Map) {
        final fieldErrors = _flattenFieldErrors(fields);
        if (fieldErrors.isNotEmpty) return fieldErrors;
      }

      // {"detail": "message"} format
      if (data['detail'] is String) {
        return [data['detail'] as String];
      }

      // Bare {"field": ["error1", "error2"]} format (no envelope)
      final flat = _flattenFieldErrors(data);
      if (flat.isNotEmpty) return flat;

      // {"message": "text"} format
      if (data['message'] is String) {
        return [data['message'] as String];
      }
    }

    return const [];
  }

  /// Flattens DRF-style `{field: [error, ...] | error}` map into a flat
  /// list of user-readable strings, skipping non-text values.
  static List<String> _flattenFieldErrors(Map fields) {
    final errors = <String>[];
    fields.forEach((_, value) {
      if (value is List) {
        for (final item in value) {
          if (item is String && item.isNotEmpty) errors.add(item);
        }
      } else if (value is String && value.isNotEmpty) {
        errors.add(value);
      }
    });
    return errors;
  }
}
