class PmtModel {
  final String pmtId;
  final String amount;
  final String status;
  final DateTime createdAt;
  final String pmtMethod;
  final String? paymentType;

  PmtModel({
    required this.pmtId,
    required this.amount,
    required this.status,
    required this.createdAt,
    required this.pmtMethod,
    this.paymentType,
  });

  factory PmtModel.fromJson(Map<String, dynamic> json) {
    return PmtModel(
      pmtId: json['payment_id'],
      amount: json['amount'].toString(),
      status: json['status'],
      createdAt: _parseDate(json['created_at']),
      pmtMethod: json['payment_method'],
      paymentType: json['payment_type'],
    );
  }

  static DateTime _parseDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) {
      return DateTime.now();
    }
    try {
      return DateTime.parse(dateStr);
    } catch (e) {
      return DateTime.now();
    }
  }

  Map<String, dynamic> toJson() {
    final map = {
      "payment_id": pmtId,
      "amount": amount,
      "status": status,
      "created_at": createdAt.toIso8601String(),
      "payment_method": pmtMethod,
    };
    if (paymentType != null) {
      map["payment_type"] = paymentType!;
    }
    return map;
  }
}
