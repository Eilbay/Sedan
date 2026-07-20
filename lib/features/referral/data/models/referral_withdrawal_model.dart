class ReferralWithdrawalModel {
  final int id;
  final String user;
  final String userUsername;
  final double amount;
  final String details;
  final String status;
  final String createdAt;
  final String? processedAt;
  final String? adminComment;

  ReferralWithdrawalModel({
    required this.id,
    required this.user,
    required this.userUsername,
    required this.amount,
    required this.details,
    required this.status,
    required this.createdAt,
    required this.processedAt,
    required this.adminComment,
  });

  factory ReferralWithdrawalModel.fromJson(Map<String, dynamic> json) {
    final rawAmount = json['amount']?.toString() ?? '0';

    return ReferralWithdrawalModel(
      id: json['id'] as int,
      user: json['user'] as String,
      userUsername: json['user_username'] as String,
      amount: double.tryParse(rawAmount) ?? 0.0,
      details: json['details'] as String,
      status: json['status'] as String,
      createdAt: json['created_at'] as String,
      processedAt: json['processed_at'] as String?,
      adminComment: json['admin_comment'] as String?,
    );
  }
}
