class ReferralProfileModel {
  final int id;
  final String user;
  final String? referrer;
  final String promocode;
  final String referralLink;
  final String createdAt;
  final int followersCount;

  ReferralProfileModel({
    required this.id,
    required this.user,
    this.referrer,
    required this.promocode,
    required this.referralLink,
    required this.createdAt,
    required this.followersCount,
  });

  factory ReferralProfileModel.fromJson(Map<String, dynamic> map) {
    return ReferralProfileModel(
      id: map['id'] as int,
      user: map['user'] as String,
      referrer: map['referrer'] != null ? map['referrer'] as String : null,
      promocode: map['promocode'] as String,
      referralLink: map['referral_link'] as String,
      createdAt: map['created_at'] as String,
      followersCount: map['followers_count'] as int,
    );
  }
}
