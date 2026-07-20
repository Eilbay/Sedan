import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';
import 'package:optombai/data/models/cart/cart_item_model.dart';
import 'package:optombai/data/models/cart/delivery_type.dart';
import 'package:optombai/data/models/cart/order_status_model.dart';

part 'order_model.g.dart';

/// Order model for local storage
/// TODO: Replace with API model when backend is ready
/// Currently using Hive for local persistence
@HiveType(typeId: 14)
class Order extends Equatable {
  @HiveField(0)
  final String id; // Order number (generated locally)

  @HiveField(1)
  final List<CartItem> items;

  @HiveField(2)
  final double subtotal;

  @HiveField(3)
  final DeliveryType deliveryType;

  @HiveField(4)
  final double deliveryCost;

  @HiveField(5)
  final double total;

  @HiveField(6)
  final String? pickupPointId;

  @HiveField(7)
  final String? comment;

  @HiveField(8)
  final DateTime createdAt;

  @HiveField(9)
  final DateTime? paidAt;

  @HiveField(10)
  final List<OrderStatus> statusHistory;

  @HiveField(11)
  final bool isPaid;

  @HiveField(12)
  final String? userName;

  @HiveField(13)
  final String? userPhone;

  const Order({
    required this.id,
    required this.items,
    required this.subtotal,
    required this.deliveryType,
    required this.deliveryCost,
    required this.total,
    this.pickupPointId,
    this.comment,
    required this.createdAt,
    this.paidAt,
    required this.statusHistory,
    this.isPaid = false,
    this.userName,
    this.userPhone,
  });

  OrderStatus get currentStatus =>
      statusHistory.isNotEmpty ? statusHistory.last : OrderStatus.created();

  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);

  Order copyWith({
    String? id,
    List<CartItem>? items,
    double? subtotal,
    DeliveryType? deliveryType,
    double? deliveryCost,
    double? total,
    String? pickupPointId,
    String? comment,
    DateTime? createdAt,
    DateTime? paidAt,
    List<OrderStatus>? statusHistory,
    bool? isPaid,
    String? userName,
    String? userPhone,
    bool clearPickupPointId = false,
  }) {
    return Order(
      id: id ?? this.id,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      deliveryType: deliveryType ?? this.deliveryType,
      deliveryCost: deliveryCost ?? this.deliveryCost,
      total: total ?? this.total,
      pickupPointId:
          clearPickupPointId ? null : (pickupPointId ?? this.pickupPointId),
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
      paidAt: paidAt ?? this.paidAt,
      statusHistory: statusHistory ?? this.statusHistory,
      isPaid: isPaid ?? this.isPaid,
      userName: userName ?? this.userName,
      userPhone: userPhone ?? this.userPhone,
    );
  }

  /// Generate order number
  /// Format: EB + Year + Month + Random 4 digits
  /// Example: EB2025020001
  static String generateOrderNumber() {
    final now = DateTime.now();
    final random = now.millisecondsSinceEpoch % 10000;
    return 'EB${now.year}${now.month.toString().padLeft(2, '0')}${random.toString().padLeft(4, '0')}';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'items': items.map((e) => e.toJson()).toList(),
      'subtotal': subtotal,
      'deliveryType': deliveryType.index,
      'deliveryCost': deliveryCost,
      'total': total,
      'pickupPointId': pickupPointId,
      'comment': comment,
      'createdAt': createdAt.toIso8601String(),
      'paidAt': paidAt?.toIso8601String(),
      'isPaid': isPaid,
      'userName': userName,
      'userPhone': userPhone,
    };
  }

  @override
  List<Object?> get props => [id, isPaid, statusHistory, items];
}
