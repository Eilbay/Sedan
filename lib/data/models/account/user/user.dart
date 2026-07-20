import 'dart:io';
import 'package:dio/dio.dart';
import 'package:optombai/data/models/account/user/socials/social_owner.dart';
import 'package:optombai/data/models/account/user/supplier/supplier_markter.dart';
import 'package:optombai/data/models/account/user/user_banner.dart';
import 'package:optombai/data/models/account/user/user_status.dart';
import 'package:optombai/data/models/account/user/users_activiti.dart';
import 'package:optombai/data/models/category/category_model.dart';
import 'package:optombai/data/models/region/kg_region.dart';

import 'package:equatable/equatable.dart';

import 'package:optombai/data/models/countries/countries.dart';

// ignore: must_be_immutable
class User with EquatableMixin {
  String id;
  String email;
  String username;
  String description;
  String phone_number;
  String? userType;
  String password;
  String about_us;
  bool? is_active;
  bool? by_admin;
  bool? is_verified;
  dynamic image;
  int reviewsCount;
  bool? isRecommended;
  bool? isPremium;
  CountryModel? country;
  int postsCount;
  double rating;
  String? level;
  double balance;
  UserBanner? userBanner;
  UserStatus? userStatus;
  UserActive? userActive;
  CountryModel? userCountry;
  List<SocialOwner> socials;
  String itn;
  String legalAddress;
  String director;
  String web_site;
  int? usersCount;

  List<Category> categories;
  List<String> categoryIds;

  final List<SupplierMarketLink> supplierMarkets;

  String? manufacturer_segment;
  Map<String, dynamic>? about_us_data;

  /// True when the viewer has this user blocked. Backend returns this
  /// flag on `GET /api/v1/accounts/users/{id}/` so the UI can render
  /// a "blocked" banner + unblock CTA without an extra request to
  /// `BlockBloc.blockedIds`.
  bool isBlockedByMe;
  KgRegion? region;

  User.copyWith(User user)
      : id = user.id,
        email = user.email,
        username = user.username,
        userType = user.userType,
        phone_number = user.phone_number,
        image = user.image,
        password = user.password,
        about_us = user.about_us,
        by_admin = user.by_admin,
        is_active = user.is_active,
        is_verified = user.is_verified,
        isRecommended = user.isRecommended,
        reviewsCount = user.reviewsCount,
        level = user.level,
        description = user.description,
        country = user.country,
        postsCount = user.postsCount,
        balance = user.balance,
        rating = user.rating,
        socials = user.socials,
        legalAddress = user.legalAddress,
        director = user.director,
        web_site = user.web_site,
        userActive = user.userActive,
        itn = user.itn,
        userCountry = user.userCountry,
        usersCount = user.usersCount,
        manufacturer_segment = user.manufacturer_segment,
        about_us_data = user.about_us_data,
        categories = user.categories,
        supplierMarkets = user.supplierMarkets,
        categoryIds = user.categoryIds,
        isBlockedByMe = user.isBlockedByMe,
        region = user.region;

  User(
      {this.id = '',
      this.email = "",
      this.username = "",
      this.description = "",
      this.phone_number = "",
      this.level = "",
      this.image,
      this.userType = "",
      this.password = "",
      this.about_us = "",
      this.by_admin = false,
      this.is_active = false,
      this.is_verified = false,
      this.reviewsCount = 0,
      this.isRecommended = false,
      this.isPremium,
      this.country,
      this.postsCount = 0,
      this.balance = 0,
      this.rating = 0,
      this.itn = "",
      this.web_site = "",
      this.userActive,
      this.userBanner,
      this.userStatus,
      this.legalAddress = "",
      this.director = "",
      this.userCountry,
      this.usersCount,
      this.manufacturer_segment,
      this.about_us_data,
      this.categories = const [],
      this.categoryIds = const [],
      this.supplierMarkets = const [],
      this.socials = const [],
      this.isBlockedByMe = false,
      this.region});

  factory User.fromJson(Map<String, dynamic> json) {
    final countryData = json['country'];
    final parsedCountry = countryData is Map<String, dynamic> ? CountryModel.fromJson(countryData) : null;

    return User(
      id: json['id'] ?? "",
      email: json['email'] ?? "",
      username: json['username'] ?? "",
      description: json['description'] ?? "",
      phone_number: json['phone_number'] ?? "",
      level: json['level'] ?? "",
      image: normalizeImage(json['image']),
      userType: json['user_type'] ?? "",
      password: json['password'] ?? "",
      about_us: json['about_us'] ?? "",
      reviewsCount: json['reviews_count'] ?? 0,
      country: parsedCountry,
      postsCount: json["posts_count"] ?? 0,
      balance: json["balance"] ?? 0,
      rating: json["rating"] ?? 0,
      itn: json["itn"] ?? "",
      isRecommended: json['isRecommended'],
      isPremium: json['is_premium'],
      by_admin: json['by_admin'],
      is_active: json['is_active'],
      is_verified: json['is_verified'],
      userActive: UserActive.fromJson(json['user_profile_activity'] ?? {}),
      userBanner: UserBanner.fromJson(json['user_banner'] ?? {}),
      userStatus: UserStatus.fromJson(json["user_status"] ?? {}),
      userCountry: parsedCountry,
      web_site: json['web_site'] ?? "",
      legalAddress: json['legal_address'] ?? "",
      usersCount: json['count'] ?? 0,
      manufacturer_segment: json['manufacturer_segment']?.toString(),
      about_us_data:
          json['about_us_data'] is Map<String, dynamic> ? Map<String, dynamic>.from(json['about_us_data']) : null,
      categories: _parseCategories(json['categories']),
      categoryIds: _parseCategoryIds(json['categories']),
      director: json["director"] ?? "",
      supplierMarkets:
          ((json['suppliers'] ?? json['supplier']) as List?)?.whereType<Map<String, dynamic>>().map(SupplierMarketLink.fromJson).toList() ??
              const [],
      socials: (json['social_owner'] as List<dynamic>?)
              ?.map((item) => SocialOwner.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      isBlockedByMe: json['is_blocked_by_me'] == true,
      region: KgRegion.fromJson(json['region']),
    );
  }

  User.fromJsonGetUserInfo(Map<String, dynamic> json)
      : id = (json['id'] ?? '').toString(),
        email = (json['email'] ?? '').toString(),
        username = (json['username'] ?? '').toString(),
        description = (json['description'] ?? '').toString(),
        phone_number = (json['phone_number'] ?? '').toString(),
        level = (json['level'] ?? '').toString(),
        image = normalizeImage(json['image']),
        userType = json['user_type']?.toString(),
        password = '',
        about_us = (json['about_us'] ?? '').toString(),
        by_admin = (json['by_admin'] as bool?) ?? false,
        is_active = (json['is_active'] as bool?) ?? false,
        is_verified = (json['is_verified'] as bool?) ?? false,
        reviewsCount = (json['reviews_count'] as int?) ?? 0,
        isRecommended = (json['is_recommended'] as bool?) ?? false,
        postsCount = (json['posts_count'] as int?) ?? 0,
        categories = _parseCategories(json['categories']),
        categoryIds = _parseCategoryIds(json['categories']),
        balance = (json['balance'] is num) ? (json['balance'] as num).toDouble() : 0,
        rating = (json['rating'] is num) ? (json['rating'] as num).toDouble() : 0,
        itn = (json['itn'] ?? '').toString(),
        web_site = (json['web_site'] ?? '').toString(),
        legalAddress = (json['legal_address'] ?? '').toString(),
        director = (json['director'] ?? '').toString(),
        usersCount = json['count'] as int?,
        manufacturer_segment = json['manufacturer_segment']?.toString(),
        supplierMarkets = ((json['suppliers'] ?? json['supplier']) as List?)
                ?.whereType<Map<String, dynamic>>()
                .map(SupplierMarketLink.fromJson)
                .toList() ??
            const [],
        about_us_data =
            json['about_us_data'] is Map<String, dynamic> ? Map<String, dynamic>.from(json['about_us_data']) : null,
        userStatus = (() {
          final m = json['user_status'];
          if (m is Map<String, dynamic>) {
            final us = UserStatus.fromJson(m);

            final hasPremiumKey = m.containsKey('is_premium');
            return hasPremiumKey
                ? us
                : UserStatus(
                    id: us.id,
                    user: us.user,
                    isAgree: us.isAgree,
                    isActive: us.isActive,
                    isPremium: (json['is_premium'] as bool?) ?? false,
                    premiumActivated: us.premiumActivated,
                    premium_expired_date: us.premium_expired_date,
                    passwordLastUpdate: us.passwordLastUpdate,
                    createdAt: us.createdAt,
                  );
          }

          return UserStatus(
            id: 0,
            user: '',
            isAgree: false,
            isActive: false,
            isPremium: (json['is_premium'] as bool?) ?? false,
            premiumActivated: null,
            premium_expired_date: null,
            passwordLastUpdate: '',
            createdAt: '',
          );
        })(),
        userBanner = (json['user_banner'] is Map<String, dynamic>)
            ? UserBanner.fromJson(json['user_banner'] as Map<String, dynamic>)
            : null,
        userActive = (json['user_profile_activity'] is Map<String, dynamic>)
            ? UserActive.fromJson(json['user_profile_activity'] as Map<String, dynamic>)
            : null,
        country = (json['country'] is Map<String, dynamic>)
            ? CountryModel.fromJson(json['country'] as Map<String, dynamic>)
            : null,
        userCountry = (json['country'] is Map<String, dynamic>)
            ? CountryModel.fromJson(json['country'] as Map<String, dynamic>)
            : null,
        socials = (json['social_owner'] is List)
            ? (json['social_owner'] as List)
                .whereType<Map<String, dynamic>>()
                .map((e) => SocialOwner.fromJson(e))
                .toList()
            : const [],
        isBlockedByMe = json['is_blocked_by_me'] == true,
        region = KgRegion.fromJson(json['region']);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'description': description,
    };
  }

  static List<Category> _parseCategories(dynamic raw) {
    if (raw is! List) return const [];

    final objects = raw.whereType<Map<String, dynamic>>().toList();
    if (objects.isNotEmpty) {
      return objects.map((e) => Category.fromJson(e)).toList();
    }

    return const [];
  }

  static List<String> _parseCategoryIds(dynamic raw) {
    if (raw is! List) return const [];

    return raw
        .where((e) => e != null)
        .map((e) {
          if (e is String) return e;
          if (e is num) return e.toInt().toString();
          return null;
        })
        .whereType<String>()
        .toList();
  }

  Map<String, dynamic> toJsonAdd() {
    final map = <String, dynamic>{};
    map['username'] = username;
    map['description'] = description;
    map['phone_number'] = phone_number;
    map['user_type'] = userType;
    map['about_us'] = about_us;
    map['itn'] = itn;
    map['legal_address'] = legalAddress;
    map["director"] = director;
    map["web_site"] = web_site;
    map['country'] = country?.id;
    map['region'] = region?.id;
    if (manufacturer_segment != null && manufacturer_segment!.isNotEmpty) {
      map['manufacturer_segment'] = manufacturer_segment;
    }

    if (about_us_data != null && about_us_data!.isNotEmpty) {
      map['about_us_data'] = about_us_data;
    }

    return map;
  }

  Future<Map<String, dynamic>> toJsonCreate() async {
    final map = <String, dynamic>{};

    if (image != null && image is File) {
      map["image"] = await MultipartFile.fromFile(image.path, filename: image.path.split('/').last);
    }
    return map;
  }

  @override
  List<Object?> get props => [
        id,
        email,
        username,
        description,
        phone_number,
        userType,
        password,
        about_us,
        is_active,
        by_admin,
        is_verified,
        image,
        reviewsCount,
        isRecommended,
        isPremium,
        country,
        postsCount,
        rating,
        level,
        balance,
        userBanner,
        userStatus,
        userActive,
        userCountry,
        socials,
        itn,
        legalAddress,
        director,
        web_site,
        usersCount,
        categories,
        categoryIds,
        supplierMarkets,
        manufacturer_segment,
        about_us_data,
        isBlockedByMe,
      ];
}

String? normalizeImage(dynamic v) {
  if (v == null) return null;
  final s = v.toString().trim();
  if (s.isEmpty) return null;
  if (s.startsWith('http://') || s.startsWith('https://')) return s;
  return s;
}
