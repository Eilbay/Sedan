import 'package:equatable/equatable.dart';

class MarketModel extends Equatable {
  final int id;
  final String name;

  final String image;

  const MarketModel({
    required this.id,
    required this.name,
    this.image = '',
  });

  factory MarketModel.fromJson(Map<String, dynamic> j) => MarketModel(
        id: j['id'],
        name: j['name'],
        image: (j['image'] as String?) ?? '',
      );

  @override
  List<Object?> get props => [id];
}

enum SupplierRequestStatus { pending, approved, rejected, unknown }

SupplierRequestStatus parseStatus(String? s) {
  switch (s) {
    case 'pending':
      return SupplierRequestStatus.pending;
    case 'approved':
      return SupplierRequestStatus.approved;
    case 'rejected':
      return SupplierRequestStatus.rejected;
    default:
      return SupplierRequestStatus.unknown;
  }
}

class SupplierRequestModel {
  final int id;
  final MarketModel market;
  final SupplierRequestStatus status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  SupplierRequestModel({
    required this.id,
    required this.market,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory SupplierRequestModel.fromJson(Map<String, dynamic> j) {
    DateTime? parseDt(String? v) {
      return null;
    }

    return SupplierRequestModel(
      id: j['id'],
      market: MarketModel.fromJson(j['market']),
      status: parseStatus(j['status']),
      createdAt: parseDt(j['created_at']),
      updatedAt: parseDt(j['updated_at']),
    );
  }
}
