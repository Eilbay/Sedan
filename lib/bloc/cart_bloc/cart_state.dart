part of 'cart_bloc.dart';

class CartState extends Equatable {
  final List<CartItem> items;
  final DeliveryType deliveryType;
  final PickupPoint? selectedPickupPoint;
  final String comment;
  final bool isLoading;
  final String? error;
  final Order? pendingOrder; // Order ready for pmt

  const CartState({
    this.items = const [],
    this.deliveryType = DeliveryType.pickup,
    this.selectedPickupPoint,
    this.comment = '',
    this.isLoading = false,
    this.error,
    this.pendingOrder,
  });

  /// Calculate subtotal (sum of all items)
  double get subtotal => items.fold(0, (sum, item) => sum + item.totalPrice);

  /// Get delivery cost based on selected type
  double get deliveryCost => deliveryType.cost;

  /// Calculate total (subtotal + delivery)
  double get total => subtotal + deliveryCost;

  /// Get total items count
  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  /// Check if cart is empty
  bool get isEmpty => items.isEmpty;

  /// Check if product is in cart
  bool isProductInCart(String productId) {
    return items.any((item) => item.productId == productId);
  }

  /// Get cart item by product ID
  CartItem? getItemByProductId(String productId) {
    try {
      return items.firstWhere((item) => item.productId == productId);
    } catch (_) {
      return null;
    }
  }

  CartState copyWith({
    List<CartItem>? items,
    DeliveryType? deliveryType,
    PickupPoint? selectedPickupPoint,
    String? comment,
    bool? isLoading,
    String? error,
    Order? pendingOrder,
    bool clearPickupPoint = false,
    bool clearPendingOrder = false,
    bool clearError = false,
  }) {
    return CartState(
      items: items ?? this.items,
      deliveryType: deliveryType ?? this.deliveryType,
      selectedPickupPoint: clearPickupPoint
          ? null
          : (selectedPickupPoint ?? this.selectedPickupPoint),
      comment: comment ?? this.comment,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      pendingOrder:
          clearPendingOrder ? null : (pendingOrder ?? this.pendingOrder),
    );
  }

  @override
  List<Object?> get props => [
        items,
        deliveryType,
        selectedPickupPoint,
        comment,
        isLoading,
        error,
        pendingOrder,
      ];
}
