part of 'order_bloc.dart';

class OrderState extends Equatable {
  final List<Order> orders;
  final bool isLoading;
  final String? error;
  final bool paymentSuccess;

  const OrderState({
    this.orders = const [],
    this.isLoading = false,
    this.error,
    this.paymentSuccess = false,
  });

  /// Get only paid orders
  List<Order> get paidOrders => orders.where((o) => o.isPaid).toList();

  /// Get pending orders (not paid)
  List<Order> get pendingOrders => orders.where((o) => !o.isPaid).toList();

  /// Get order by ID
  Order? getOrderById(String orderId) {
    try {
      return orders.firstWhere((o) => o.id == orderId);
    } catch (_) {
      return null;
    }
  }

  OrderState copyWith({
    List<Order>? orders,
    bool? isLoading,
    String? error,
    bool? paymentSuccess,
    bool clearError = false,
    bool clearPaymentSuccess = false,
  }) {
    return OrderState(
      orders: orders ?? this.orders,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      paymentSuccess:
          clearPaymentSuccess ? false : (paymentSuccess ?? this.paymentSuccess),
    );
  }

  @override
  List<Object?> get props => [orders, isLoading, error, paymentSuccess];
}
