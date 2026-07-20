class ReferralTransactionModel {
  final int id;
  final int walletId;
  final String walletUsername;
  final String type;
  final double amount;
  final String? relatedUserId;
  final String description;
  final String createdAt;
  final bool isConfirmed;

  ReferralTransactionModel({
    required this.id,
    required this.walletId,
    required this.walletUsername,
    required this.type,
    required this.amount,
    this.relatedUserId,
    required this.description,
    required this.createdAt,
    required this.isConfirmed,
  });

  factory ReferralTransactionModel.fromJson(Map<String, dynamic> json) {
    final rawAmount = json['amount']?.toString() ?? '0';
    final parsedAmount = double.tryParse(rawAmount) ?? 0.0;

    return ReferralTransactionModel(
      id: json['id'] as int,
      walletId: json['referral_wallet'] as int,
      walletUsername: json['referral_wallet_user'] as String,
      type: json['type'] as String,
      amount: parsedAmount,
      relatedUserId: json['related_user']?.toString(),
      description: json['description'] as String,
      createdAt: json['created_at'] as String,
      isConfirmed: json['is_confirmed'] as bool,
    );
  }
}
