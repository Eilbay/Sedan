import 'package:optombai/configs/constrants.dart';
import 'package:optombai/core/error/app_exception.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Single source of truth for chat auth readiness.
///
/// Chat flows can start milliseconds after a successful login while the
/// access token is still being persisted to local storage. This guard waits
/// briefly for the token to become available before any chat request or
/// websocket handshake goes out.
class ChatAuthGuard {
  ChatAuthGuard(this._preferences);

  final SharedPreferences _preferences;

  static const Duration _pollInterval = Duration(milliseconds: 50);
  static const Duration _defaultTimeout = Duration(milliseconds: 800);

  String get token => _preferences.getString(TOKEN_KEY) ?? '';

  bool get hasToken => token.isNotEmpty;

  Future<String> requireToken({Duration timeout = _defaultTimeout}) async {
    final deadline = DateTime.now().add(timeout);
    var current = token;

    while (current.isEmpty && DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(_pollInterval);
      current = token;
    }

    if (current.isEmpty) {
      throw const AuthException(statusCode: 401);
    }

    return current;
  }
}
