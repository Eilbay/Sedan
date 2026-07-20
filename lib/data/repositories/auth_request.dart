import 'dart:convert';
import 'package:flutter/foundation.dart';

import 'package:dio/dio.dart';
import 'package:optombai/core/error/app_exception.dart';
import 'package:optombai/data/api_client.dart';
import 'package:optombai/data/domain_set.dart';
import 'package:optombai/data/models/account/token.dart';
import 'package:optombai/data/models/account/user/user_status.dart';
import 'package:optombai/data/repositories/i_auth_repository.dart';

class AuthRepository implements IAuthRepository {
  final Dio _dio = ApiClient.I.dio;

  String get endpointApi => '${ApiEndpoints.accountsApi}/users/';
  String get endpointStatusApi => '${ApiEndpoints.accountsApi}/statuses/';
  String get endpointActiveApi => '${ApiEndpoints.accountsApi}/users/account_activate/';
  String get endpointEmailApi => '${ApiEndpoints.accountsApi}/users/check_email_to_exist_user/';
  static String get endpointApiUser => '${ApiEndpoints.baseApi}/accounts/token/';
  String get endpointGetUserByToken => '${ApiEndpoints.accountsApi}/users/get_user_by_token/';
  String get endpointUpdatePassword => '${ApiEndpoints.accountsApi}/users/{id}/update_password/';
  String get endpointCheckOldPassword => '${ApiEndpoints.accountsApi}/users/{id}/update_password_check_old/';

  String get endpointSingin => '${ApiEndpoints.accountsApi}/users/social_signin/';

  String get endpointResetByPhone => '${ApiEndpoints.accountsApi}/users/reset_password_by_pn/';
  String get endpointResetByEmail => '${ApiEndpoints.accountsApi}/users/reset_password_by_email/';

  String get endpointResetConfirmByPhone => '${ApiEndpoints.accountsApi}/users/reset_password_confirm_by_pn/';
  String get endpointResetConfirmByEmail => '${ApiEndpoints.accountsApi}/users/reset_password_confirm_by_email/';

  Future<Map<String, dynamic>> registerUser({
    String? email,
    required String password,
    required String username,
    required String phoneNumber,
    int? regionId,
    bool isEmailConfirmation = false,
    String? referralCode,
  }) async {
    try {
      final body = <String, dynamic>{
        'username': username,
        'password': password,
        'phone_number': phoneNumber,
        if (regionId != null) 'region': regionId,
        if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
        if (referralCode != null && referralCode.trim().isNotEmpty) 'referral_code': referralCode.trim(),
      };

      final response = await _dio.post(
        endpointApi,
        data: body,
        queryParameters: {'is_email_conf': isEmailConfirmation ? 1 : 0},
      );

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<String> activateAccount(String token) async {
    try {
      final res = await _dio.post(endpointActiveApi, data: <String, dynamic>{'token': token});
      return res.data['account'] ?? "";
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<Token> login(String username, String password) async {
    try {
      final res = await _dio.post(
        endpointApiUser,
        data: {"username": username, "password": password, "email": username},
      );
      return Token.fromMap(res.data);
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<String> confirmResetCodeByPhone({
    required String phoneNumber,
    required String code,
  }) async {
    try {
      final res = await _dio.post(
        endpointResetConfirmByPhone,
        data: {
          'phone_number': phoneNumber,
          'token': code,
        },
      );

      final data = res.data;
      final id = (data['user_id'] ?? data['id'] ?? data['uid'] ?? '').toString();

      if (id.isEmpty) {
        throw const ValidationException(message: 'Сервер не вернул user_id для смены пароля');
      }
      return id;
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<String> confirmResetCodeByEmail({
    required String email,
    required String code,
  }) async {
    try {
      final res = await _dio.post(
        endpointResetConfirmByEmail,
        data: {
          'email': email,
          'token': code,
        },
      );

      final data = res.data;
      final id = (data['user_id'] ?? data['id'] ?? data['uid'] ?? '').toString();

      if (id.isEmpty) {
        throw const ValidationException(message: 'Сервер не вернул user_id для смены пароля');
      }
      return id;
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<int> getUserCountByType(
    String userType, {
    String? categories,
  }) async {
    try {
      final params = <String, dynamic>{
        'user_type': userType,
        if (categories != null && categories.isNotEmpty) 'post_owner__category': categories,
      };

      final response = await _dio.get(
        endpointApi,
        queryParameters: params,
      );
      return response.data['count'] ?? 0;
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<int> getClientCountByType(
    String userType, {
    String? categories,
  }) async {
    try {
      final params = <String, dynamic>{
        'user_type': userType,
        if (categories != null && categories.isNotEmpty) 'post_owner__category': categories,
      };

      final response = await _dio.get(Uri.parse(endpointApi).resolve('customers/').toString(), queryParameters: params);
      return response.data['count'] ?? 0;
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<Token> googleAuth(String token) async {
    try {
      var response = await _dio.post(endpointSingin, data: {"token": token});
      return Token.fromMap(response.data);
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<void> sendResetPasswordRequest(String value, String endpoint, String key) async {
    try {
      var response = await _dio.post(
        endpointApi + endpoint,
        data: {key: value},
      );
      debugPrint('$response');
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<void> checkEmailExists(String email) async {
    try {
      await _dio.post(
        endpointEmailApi,
        data: {'email': email},
      );
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<String> getUserToken(String token) async {
    try {
      var response = await _dio.post(endpointGetUserByToken, data: {"token": token});
      return response.data["id"] ?? "";
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<void> updatePassword(
    String password,
    String userId,
  ) async {
    try {
      String api = endpointUpdatePassword.replaceFirst("{id}", userId);
      debugPrint(api);
      final response = await _dio.patch(api, data: {'password': password});
      return response.data['password'];
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<void> checkOldPassword(
    String oldPassword,
    String password,
    String userId,
  ) async {
    try {
      String api = endpointCheckOldPassword.replaceFirst("{id}", userId);
      await _dio.patch(api, data: {'old_password': oldPassword, 'password': password});
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<String> refreshToken(String refreshToken) async {
    try {
      String api = "${endpointApiUser}refresh/";

      var response = await _dio.post(
        api,
        data: jsonEncode(
          <String, String>{
            'refresh': refreshToken,
          },
        ),
      );
      return response.data["access"];
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<UserStatus> updatePremiumStatus(String pmtId, String premiumId, String token) async {
    try {
      var response = await _dio.put(
        endpointStatusApi,
        data: {"payment_id": pmtId, "premium_id": premiumId, "token": token},
        options: options(token),
      );
      debugPrint('${response.data}');
      return UserStatus.fromJson(response.data);
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }
}
