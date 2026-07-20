import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ConfigService {
  static const String _configUrl = 'https://elibay-api.vercel.app/config.json';
  static const String _configKey = 'app_config';
  static const String _startPointKey = 'start_point';

  static const String _defaultStartPoint = 'https://optombai.com';

  // Soft/hard update gate — see UpdateGateOverlay. All optional: a missing
  // or unreachable config simply means the update gate never triggers.
  static const String _latestVersionIosKey = 'latest_version_ios';
  static const String _latestVersionAndroidKey = 'latest_version_android';
  static const String _minVersionKey = 'min_version';
  static const String _storeUrlIosKey = 'store_url_ios';
  static const String _storeUrlAndroidKey = 'store_url_android';

  static late SharedPreferences _preferences;
  static String _currentStartPoint = _defaultStartPoint;

  /// Fast initialization without network requests.
  /// Loads only previously saved config or fallback defaults.
  static void initFast(SharedPreferences preferences) {
    _preferences = preferences;
    _loadConfigFromPreferences();
  }

  static Future<void> init(SharedPreferences preferences) async {
    initFast(preferences);

    try {
      await _fetchConfig();
    } catch (e) {
      debugPrint('Config load error: $e');
      _loadConfigFromPreferences();
    }
  }

  static Future<void> _fetchConfig() async {
    final dio = Dio();

    try {
      debugPrint('Loading config from Vercel...');

      final response = await dio.get(
        _configUrl,
        options: Options(
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      if (response.statusCode == 200) {
        final config = response.data;
        final startPoint = config['start_point'];

        if (startPoint != null) {
          debugPrint('Config loaded: start_point = $startPoint');

          await _preferences.setString(_startPointKey, startPoint);
          _currentStartPoint = startPoint;

          await _preferences.setString(
            _configKey,
            response.data.toString(),
          );
        }

        await _saveIfPresent(_latestVersionIosKey, config['latest_version_ios']);
        await _saveIfPresent(
            _latestVersionAndroidKey, config['latest_version_android']);
        await _saveIfPresent(_minVersionKey, config['min_version']);
        await _saveIfPresent(_storeUrlIosKey, config['store_url_ios']);
        await _saveIfPresent(_storeUrlAndroidKey, config['store_url_android']);
      }
    } on DioException catch (e) {
      debugPrint('Dio error: ${e.message}');
      _loadConfigFromPreferences();
    } catch (e) {
      debugPrint('Unexpected error: $e');
      _loadConfigFromPreferences();
    }
  }

  static Future<void> _saveIfPresent(String key, dynamic value) async {
    if (value is! String || value.isEmpty) return;
    await _preferences.setString(key, value);
  }

  static void _loadConfigFromPreferences() {
    try {
      final saved = _preferences.getString(_startPointKey);
      if (saved != null && saved.isNotEmpty) {
        debugPrint('Using saved config: $saved');
        _currentStartPoint = saved;
      } else {
        debugPrint('Using default config: $_defaultStartPoint');
        _currentStartPoint = _defaultStartPoint;
      }
    } catch (e) {
      debugPrint('Error reading config: $e');
      _currentStartPoint = _defaultStartPoint;
    }
  }

  static String getStartPoint() {
    return _currentStartPoint;
  }

  static String getApiUrl() {
    return '$_currentStartPoint/api/v1';
  }

  static String? getLatestVersionIos() =>
      _preferences.getString(_latestVersionIosKey);

  static String? getLatestVersionAndroid() =>
      _preferences.getString(_latestVersionAndroidKey);

  static String? getMinVersion() => _preferences.getString(_minVersionKey);

  static String? getStoreUrlIos() => _preferences.getString(_storeUrlIosKey);

  static String? getStoreUrlAndroid() =>
      _preferences.getString(_storeUrlAndroidKey);

  static Future<void> refreshConfig() async {
    try {
      debugPrint('Refreshing config...');
      await _fetchConfig();
      debugPrint('Config refreshed');
    } catch (e) {
      debugPrint('Config refresh error: $e');
    }
  }

  static Map<String, dynamic> getDebugInfo() {
    return {
      'current_start_point': _currentStartPoint,
      'default_start_point': _defaultStartPoint,
      'config_url': _configUrl,
      'saved_config': _preferences.getString(_configKey),
    };
  }
}
