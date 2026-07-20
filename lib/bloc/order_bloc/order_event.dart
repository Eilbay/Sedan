part of 'order_bloc.dart';

abstract class OrderEvent extends Equatable {
  const OrderEvent();

  @override
  List<Object?> get props => [];
}

/// Load orders from storage
class OrderLoadEvent extends OrderEvent {
  const OrderLoadEvent();
}

/// Save order (before pmt)
class OrderSaveEvent extends OrderEvent {
  final Order order;

  const OrderSaveEvent({required this.order});

  @override
  List<Object?> get props => [order.id];
}

/// Mark order as paid (after successful pmt)
class OrderPaymentSuccessEvent extends OrderEvent {
  final String orderId;

  const OrderPaymentSuccessEvent({required this.orderId});

  @override
  List<Object?> get props => [orderId];
}

/// Check and update order statuses based on time
class OrderCheckStatusUpdatesEvent extends OrderEvent {
  const OrderCheckStatusUpdatesEvent();
}

/// Delete order
class OrderDeleteEvent extends OrderEvent {
  final String orderId;

  const OrderDeleteEvent({required this.orderId});

  @override
  List<Object?> get props => [orderId];
}
