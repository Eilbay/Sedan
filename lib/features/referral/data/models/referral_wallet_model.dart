class ReferralWalletModel {
  final int id;
  final String user;
  final String userUsername;
  final double balance;
  final String createdAt;

  ReferralWalletModel({
    required this.id,
    required this.user,
    required this.userUsername,
    required this.balance,
    required this.createdAt,
  });

  factory ReferralWalletModel.fromJson(Map<String, dynamic> json) {
    final rawBalance = json['balance']?.toString() ?? '0';
    final parsedBalance = double.tryParse(rawBalance) ?? 0.0;

    return ReferralWalletModel(
      id: json['id'] as int,
      user: json['user'] as String,
      userUsername: json['user_username'] as String,
      balance: parsedBalance,
      createdAt: json['created_at'] as String,
    );
  }
}
