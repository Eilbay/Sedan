import 'package:equatable/equatable.dart';

class UserStatus extends Equatable {
  final int id;
  final String user;
  final bool isAgree;
  final bool isActive;
  final bool isPremium;
  final String? premiumActivated;
  final String? premium_expired_date;
  final String passwordLastUpdate;
  final String createdAt;

  const UserStatus({
    this.premiumActivated,
    this.premium_expired_date,
    required this.id,
    required this.user,
    required this.isAgree,
    required this.isPremium,
    required this.isActive,
    required this.passwordLastUpdate,
    required this.createdAt,
  });

  factory UserStatus.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic v) {
      if (v is int) return v;
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    bool parseBool(dynamic v) {
      if (v is bool) return v;
      if (v is int) return v != 0;
      if (v is String) return v.toLowerCase() == 'true' || v == '1';
      return false;
    }

    String? parseNullableString(dynamic v) {
      if (v == null) return null;
      final s = v.toString();
      return s.isEmpty ? null : s;
    }

    return UserStatus(
      id: parseInt(json['id']),
      user: (json['user'] ?? '').toString(),
      premiumActivated: parseNullableString(json['premium_activated']),
      premium_expired_date: parseNullableString(json['premium_expired_date']),
      isAgree: parseBool(json['is_agree']),
      isActive: parseBool(json['is_active']),
      isPremium: parseBool(json['is_premium']),
      passwordLastUpdate: (json['password_last_update'] ?? '').toString(),
      createdAt: (json['created_at'] ?? '').toString(),
    );
  }

  UserStatus copyWith({
    int? id,
    String? user,
    bool? isAgree,
    bool? isActive,
    bool? isPremium,
    String? premiumActivated,
    String? premium_expired_date,
    String? passwordLastUpdate,
    String? createdAt,
  }) {
    return UserStatus(
      id: id ?? this.id,
      user: user ?? this.user,
      isAgree: isAgree ?? this.isAgree,
      isActive: isActive ?? this.isActive,
      isPremium: isPremium ?? this.isPremium,
      premiumActivated: premiumActivated ?? this.premiumActivated,
      premium_expired_date: premium_expired_date ?? this.premium_expired_date,
      passwordLastUpdate: passwordLastUpdate ?? this.passwordLastUpdate,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        user,
        isAgree,
        isActive,
        isPremium,
        premiumActivated,
        premium_expired_date,
        passwordLastUpdate,
        createdAt,
      ];
}
