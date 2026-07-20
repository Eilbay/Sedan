class ReferralBonusLogModel {
  final int id;
  final int transactionId;
  final int fromUserId;
  final String fromUserUsername;
  final int toUserId;
  final String toUserUsername;
  final int level;
  final double percent;
  final double amount;
  final String reason;
  final DateTime createdAt;

  ReferralBonusLogModel({
    required this.id,
    required this.transactionId,
    required this.fromUserId,
    required this.fromUserUsername,
    required this.toUserId,
    required this.toUserUsername,
    required this.level,
    required this.percent,
    required this.amount,
    required this.reason,
    required this.createdAt,
  });

  factory ReferralBonusLogModel.fromJson(Map<String, dynamic> json) {
    final rawPercent = json['percent']?.toString() ?? '0';
    final rawAmount = json['amount']?.toString() ?? '0';

    return ReferralBonusLogModel(
      id: json['id'] as int,
      transactionId: json['transaction'] as int,
      fromUserId: json['from_user'] as int,
      fromUserUsername: json['from_user_username'] as String,
      toUserId: json['to_user'] as int,
      toUserUsername: json['to_user_username'] as String,
      level: json['level'] as int,
      percent: double.tryParse(rawPercent) ?? 0.0,
      amount: double.tryParse(rawAmount) ?? 0.0,
      reason: json['reason'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
