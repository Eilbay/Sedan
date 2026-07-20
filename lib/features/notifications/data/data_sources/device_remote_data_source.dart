import 'package:dio/dio.dart';
import 'package:optombai/configs/constrants.dart';
import 'package:optombai/core/error/app_exception.dart';
import 'package:optombai/data/domain_set.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DeviceRemoteDataSource {
  DeviceRemoteDataSource(this._dio, this._preferences);

  final Dio _dio;
  final SharedPreferences _preferences;

  String _token() => _preferences.getString(TOKEN_KEY) ?? '';

  Options _auth() => Options(headers: {'Authorization': 'Bearer ${_token()}'});

  Future<void> register({
    required String fcmToken,
    required String platform,
  }) async {
    try {
      await _dio.post(
        ApiEndpoints.devicesRegister,
        data: {'token': fcmToken, 'platform': platform},
        options: _auth(),
      );
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<void> unregister(String fcmToken) async {
    try {
      await _dio.post(
        ApiEndpoints.devicesUnregister,
        data: {'token': fcmToken},
        options: _auth(),
      );
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }
}
