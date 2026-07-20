// ignore_for_file: public_member_api_docs, sort_constructors_first
class ReferralInviteeModel {
  final int id;
  final String user;
  final String referrer;
  final String referrerUsername;
  final String promocode;
  final String referralLink;
  final String createdAt;
  final int followersCount;
  final String? userName;
  final String? userCountry;

  ReferralInviteeModel({
    required this.id,
    required this.user,
    required this.referrer,
    required this.referrerUsername,
    required this.promocode,
    required this.referralLink,
    required this.createdAt,
    required this.followersCount,
    this.userName,
    this.userCountry,
  });

  factory ReferralInviteeModel.fromJson(Map<String, dynamic> map) {
    return ReferralInviteeModel(
      id: map['id'] as int,
      user: map['user'] as String,
      referrer: map['referrer'] as String,
      referrerUsername: map['referrer_username'] as String,
      promocode: map['promocode'] as String,
      referralLink: map['referral_link'] as String,
      createdAt: map['created_at'] as String,
      followersCount: map['followers_count'] as int,
    );
  }

  ReferralInviteeModel copyWith({
    int? id,
    String? user,
    String? referrer,
    String? referrerUsername,
    String? promocode,
    String? referralLink,
    String? createdAt,
    int? followersCount,
    String? userName,
    String? userCountry,
  }) {
    return ReferralInviteeModel(
      id: id ?? this.id,
      user: user ?? this.user,
      referrer: referrer ?? this.referrer,
      referrerUsername: referrerUsername ?? this.referrerUsername,
      promocode: promocode ?? this.promocode,
      referralLink: referralLink ?? this.referralLink,
      createdAt: createdAt ?? this.createdAt,
      followersCount: followersCount ?? this.followersCount,
      userName: userName ?? this.userName,
      userCountry: userCountry ?? this.userCountry,
    );
  }
}
