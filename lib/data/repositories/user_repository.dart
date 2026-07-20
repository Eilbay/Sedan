import 'dart:io';

import 'package:dio/dio.dart';
import 'package:optombai/core/error/app_exception.dart';
import 'package:optombai/data/api_client.dart';
import 'package:optombai/core/enums/request_type.dart';
import 'package:optombai/data/domain_set.dart';
import 'package:optombai/data/models/account/user/socials/social_owner.dart';
import 'package:optombai/data/models/account/user/socials/social_type.dart';
import 'package:optombai/data/models/account/user/user.dart';

import 'package:optombai/data/models/account/user/users_activiti.dart';
import 'package:optombai/data/repositories/i_user_repository.dart';

String get endpointSocialTypes => '${ApiEndpoints.accountsApi}/social_types/';
String get endpointSocial => '${ApiEndpoints.accountsApi}/socials/';

String get endpointApi => '${ApiEndpoints.accountsApi}/users';
String get endPointVisit => '${ApiEndpoints.accountsApi}/visits/';

String get endpointGetUserInfo => '$endpointApi/get_userinfo/';
String get endpointUpdateUser =>
    '$endpointApi/send_confirm_code_for_update_email/';
String get endpointGetUserByToken => '$endpointApi/get_user_by_token/';
String get endpointUpdateEmail => '$endpointApi/{id}/update_email/';

class UserRepository implements IUserRepository {
  final Dio _dio = ApiClient.I.dio;

  Options _auth(String token) => Options(
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

  Options _authFormData(String token) => Options(
        headers: {
          'Authorization': 'Bearer $token',
          //'Content-Type': 'multipart/form-data',
        },
      );

  Future<User> getUserOwner(String token, {bool forceRefresh = false}) async {
    try {
      // After a profile mutation the cached GET still carries the old data
      // (e.g. previous avatar URL) for up to 5 minutes — bypass it.
      final options = forceRefresh
          ? ApiClient.I.forceRefreshOptions
              .copyWith(headers: _auth(token).headers)
          : _auth(token);
      final response = await _dio.get(endpointGetUserInfo, options: options);
      return User.fromJsonGetUserInfo(response.data);
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<User> getUser(String token, String id) async {
    try {
      final response =
          await _dio.get('$endpointApi/$id/', options: _auth(token));
      return User.fromJson(response.data);
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<Map<String, dynamic>> getUsersByTypeAndCountry({
    required String userType,
    String? country,
    String? categories,
    String? nextUrl,
    int? page,
    int limit = 20,
    int? market,
    bool isVerified = false,
    String? ordering,
  }) async {
    try {
      final params = <String, dynamic>{
        'user_type': userType,
        if (country != null && country.isNotEmpty && country != 'null')
          'country': country,
        if (categories != null && categories.isNotEmpty)
          'post_category': categories,
        'limit': limit,
        if (page != null) 'offset': (page - 1) * limit,
        if (market != null) 'market': market,
        // Server-side filter: only verified accounts. Keeps `count`/`next`
        // consistent so pagination shows the real number of verified pages
        // (no phantom pages from client-side filtering).
        if (isVerified) 'is_verified': true,
        // Server-side sort.
        if (ordering != null && ordering.trim().isNotEmpty)
          'ordering': ordering,
      };

      final response = await _dio.get(
        nextUrl ?? endpointApi,
        queryParameters: params,
      );

      final List results = (response.data['results'] as List?) ?? const [];
      return {
        'users': results.map((json) => User.fromJson(json)).toList(),
        'count': response.data['count'] ?? 0,
        'next': response.data['next'],
        'previous': response.data['previous'],
      };
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<Map<String, dynamic>> getCustomers({
    required String token,
    String? countryId,
    String? categoryId,
    String? nextUrl,
    int? page,
    int limit = 20,
  }) async {
    try {
      final params = <String, dynamic>{
        if (countryId != null && countryId.isNotEmpty && countryId != 'null')
          'country_id': countryId,
        if (categoryId != null && categoryId.isNotEmpty)
          'category_id': categoryId,
        'limit': limit,
        if (page != null) 'offset': (page - 1) * limit,
      };

      final response = await _dio.get(
        nextUrl ?? '$endpointApi/customers/',
        queryParameters: params,
        //options: _auth(token),
      );

      final List results = (response.data['results'] as List?) ?? const [];
      return {
        'users': results.map((json) => User.fromJson(json)).toList(),
        'count': response.data['count'] ?? 0,
        'next': response.data['next'],
        'previous': response.data['previous'],
      };
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<User> getUserWithoutToken(String id) async {
    try {
      final response = await _dio.get('$endpointApi/$id/');
      return User.fromJson(response.data);
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<List<UserActive>> getVisitProfileCount(String token, String id) async {
    try {
      final response = await _dio.get(
        endPointVisit,
        options: _auth(token),
        queryParameters: {'user': id},
      );

      final List results = (response.data['results'] as List?) ?? const [];
      return results.map((item) => UserActive.fromJson(item)).toList();
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<User> infoUserUpdate(
    String token,
    Map<String, dynamic> map,
    String id,
  ) async {
    try {
      await _dio.patch(
        '$endpointApi/$id/',
        data: map,
        options: _auth(token),
      );
      return await getUserOwner(token, forceRefresh: true);
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<User> userImage(String token, File file, String id) async {
    try {
      final form = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          file.path,
          filename: file.path.split('/').last,
        ),
      });

      await _dio.patch(
        '$endpointApi/$id/',
        data: form,
        options: _authFormData(token),
      );

      return await getUserOwner(token, forceRefresh: true);
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<void> newEmailCode(String email, String token) async {
    try {
      await _dio.post(
        endpointUpdateUser,
        data: {'email': email},
        options: _auth(token),
      );
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<String> updateEmail(String email, String code, String token) async {
    try {
      final responseCode = await _dio.post(
        endpointGetUserByToken,
        data: {'token': code},
      );

      if (responseCode.statusCode != 200) {
        throw Exception('Invalid code: status ${responseCode.statusCode}');
      }

      final String id = responseCode.data['id'].toString();
      final String api = endpointUpdateEmail.replaceFirst('{id}', id);

      final response = await _dio.patch(
        api,
        data: {'email': email},
        options: _auth(token),
      );

      return (response.data['email'] ?? email).toString();
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<List<SocialType>> getSocialTypes({String? token}) async {
    try {
      final response = await _dio.get(
        endpointSocialTypes,
        options: token == null ? null : _auth(token),
      );
      final List results = (response.data['results'] as List?) ?? const [];
      return results.map((item) => SocialType.fromJson(item)).toList();
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<List<SocialOwner>> getSocial(String id, {String? token}) async {
    try {
      final response = await _dio.get(
        '${ApiEndpoints.getSocials}$id/',
        options: token == null ? null : _auth(token),
      );
      final List results = (response.data['results'] as List?) ?? const [];
      return results.map((item) => SocialOwner.fromJson(item)).toList();
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<User> socialAddOrUpdate(
    String token,
    SocialOwner socialOwner,
    EnumRequestType typeRequest,
  ) async {
    try {
      if (typeRequest == EnumRequestType.post) {
        await _dio.post(
          endpointSocial,
          data: socialOwner.toJson(),
          options: _auth(token),
        );
      } else if (typeRequest == EnumRequestType.put) {
        await _dio.put(
          '$endpointSocial${socialOwner.id}/',
          data: socialOwner.toJson(),
          options: _auth(token),
        );
      } else {
        await _dio.delete(
          '$endpointSocial${socialOwner.id}/',
          options: _auth(token),
        );
      }

      return await getUserOwner(token, forceRefresh: true);
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<void> deleteUser(String token, String id, String password) async {
    try {
      await _dio.delete(
        '$endpointApi/$id/',
        data: {'password': password},
        options: _auth(token),
      );
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<Map<String, dynamic>> searchUsers({
    required String search,
    String? categoryId,
    int? countryId,
    String? ordering,
    String? nextUrl,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final params = <String, dynamic>{
        'search': search,
        'limit': limit,
        'offset': (page - 1) * limit,
        if (categoryId != null && categoryId.isNotEmpty)
          'post_owner__category': categoryId,
        if (countryId != null) 'country': countryId,
        if (ordering != null && ordering.trim().isNotEmpty)
          'ordering': ordering,
      };

      // A server-issued `next` link already carries every filter of the
      // original query — same append pattern as getUsersByTypeAndCountry.
      final response = await _dio.get(
        nextUrl ?? endpointApi,
        queryParameters: params,
      );

      final List results = (response.data['results'] as List?) ?? const [];
      return {
        'users': results.map((json) => User.fromJson(json)).toList(),
        'count': response.data['count'] ?? 0,
        'next': response.data['next'],
        'previous': response.data['previous'],
      };
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }
}
