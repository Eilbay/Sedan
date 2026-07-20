class PitModel {
  final double balance;
  final String currency;
  final String createdAt;
  final String updatedAt;

  PitModel({
    required this.balance,
    this.currency = 'KGS',
    this.createdAt = '',
    this.updatedAt = '',
  });

  factory PitModel.fromJson(Map<String, dynamic> json) {
    return PitModel(
      balance: _parseDouble(json['balance']),
      currency: json['currency']?.toString() ?? 'KGS',
      createdAt: json['created_at']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString() ?? '',
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'balance': balance,
      'currency': currency,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}

class PitInitRequest {
  final String amount;
  final String provider; // "finik" or "freedompay"
  final String currency;

  PitInitRequest({
    required this.amount,
    required this.provider,
    this.currency = 'KGS',
  });

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'provider': provider,
      'currency': currency,
    };
  }
}

class PitInitResponse {
  final String paymentId;
  final String provider;
  final String status;
  final String amount;
  final String currency;

  PitInitResponse({
    required this.paymentId,
    required this.provider,
    required this.status,
    required this.amount,
    required this.currency,
  });

  factory PitInitResponse.fromJson(Map<String, dynamic> json) {
    return PitInitResponse(
      paymentId: json['payment_id']?.toString() ?? '',
      provider: json['provider']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      amount: json['amount']?.toString() ?? '0',
      currency: json['currency']?.toString() ?? 'KGS',
    );
  }

  double get amountAsDouble {
    return double.tryParse(amount) ?? 0.0;
  }
}

class IAPPitResponse {
  final bool success;
  final String message;
  final double? newBalance;
  final double? addedAmount;

  IAPPitResponse({
    required this.success,
    this.message = '',
    this.newBalance,
    this.addedAmount,
  });

  factory IAPPitResponse.fromJson(Map<String, dynamic> json) {
    return IAPPitResponse(
      success: json['success'] == true,
      message: json['message']?.toString() ?? '',
      newBalance: _parseDouble(json['new_balance']),
      addedAmount: _parseDouble(json['added_amount']),
    );
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}
