import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'order_status_model.g.dart';

/// Order status type enum
/// TODO: Replace with API status codes when backend is ready
@HiveType(typeId: 11)
enum OrderStatusType {
  @HiveField(0)
  created,

  @HiveField(1)
  assembling,

  @HiveField(2)
  delivered,
}

extension OrderStatusTypeExtension on OrderStatusType {
  String get displayName {
    switch (this) {
      case OrderStatusType.created:
        return 'Оформлен';
      case OrderStatusType.assembling:
        return 'В сборке';
      case OrderStatusType.delivered:
        return 'Доставлен';
    }
  }

  String get description {
    switch (this) {
      case OrderStatusType.created:
        return 'Заказ оформлен';
      case OrderStatusType.assembling:
        return 'Идёт сборка на складе';
      case OrderStatusType.delivered:
        return 'Доставлен в пункт выдачи';
    }
  }
}

/// Order status model with timestamp
/// TODO: Replace with API model when backend is ready
@HiveType(typeId: 12)
class OrderStatus extends Equatable {
  @HiveField(0)
  final OrderStatusType type;

  @HiveField(1)
  final DateTime timestamp;

  @HiveField(2)
  final String message;

  const OrderStatus({
    required this.type,
    required this.timestamp,
    required this.message,
  });

  factory OrderStatus.created() => OrderStatus(
        type: OrderStatusType.created,
        timestamp: DateTime.now(),
        message: 'Заказ оформлен',
      );

  factory OrderStatus.assembling() => OrderStatus(
        type: OrderStatusType.assembling,
        timestamp: DateTime.now(),
        message: 'Идёт сборка на складе',
      );

  factory OrderStatus.delivered() => OrderStatus(
        type: OrderStatusType.delivered,
        timestamp: DateTime.now(),
        message: 'Доставлен в пункт выдачи',
      );

  @override
  List<Object?> get props => [type, timestamp, message];
}
