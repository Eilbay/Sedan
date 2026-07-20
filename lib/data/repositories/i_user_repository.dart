import 'dart:io';

import 'package:optombai/core/enums/request_type.dart';
import 'package:optombai/data/models/account/user/socials/social_owner.dart';
import 'package:optombai/data/models/account/user/socials/social_type.dart';
import 'package:optombai/data/models/account/user/user.dart';
import 'package:optombai/data/models/account/user/users_activiti.dart';

abstract interface class IUserRepository {
  /// [forceRefresh] bypasses the Dio GET cache — required right after a
  /// profile mutation, otherwise the cached response (old avatar URL etc.)
  /// is served for up to 5 minutes.
  Future<User> getUserOwner(String token, {bool forceRefresh = false});

  Future<User> getUser(String token, String id);

  Future<Map<String, dynamic>> getUsersByTypeAndCountry({
    required String userType,
    String? country,
    String? categories,
    String? nextUrl,
    int? page,
    int limit = 20,
    int? market,
    bool isVerified,
    String? ordering,
  });

  Future<Map<String, dynamic>> getCustomers({
    required String token,
    String? countryId,
    String? categoryId,
    String? nextUrl,
    int? page,
    int limit = 20,
  });

  Future<User> getUserWithoutToken(String id);

  Future<List<UserActive>> getVisitProfileCount(String token, String id);

  Future<User> infoUserUpdate(
    String token,
    Map<String, dynamic> map,
    String id,
  );

  Future<User> userImage(String token, File file, String id);

  Future<void> newEmailCode(String email, String token);

  Future<String> updateEmail(String email, String code, String token);

  Future<List<SocialType>> getSocialTypes({String? token});

  Future<List<SocialOwner>> getSocial(String id, {String? token});

  Future<User> socialAddOrUpdate(
    String token,
    SocialOwner socialOwner,
    EnumRequestType typeRequest,
  );

  Future<void> deleteUser(String token, String id, String password);

  Future<Map<String, dynamic>> searchUsers({
    required String search,
    String? categoryId,
    int? countryId,
    String? ordering,
    String? nextUrl,
    int page = 1,
    int limit = 20,
  });
}
