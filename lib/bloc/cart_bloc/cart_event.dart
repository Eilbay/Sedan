part of 'cart_bloc.dart';

abstract class CartEvent extends Equatable {
  const CartEvent();

  @override
  List<Object?> get props => [];
}

/// Load cart items from storage
class CartLoadEvent extends CartEvent {
  const CartLoadEvent();
}

/// Add product to cart
class CartAddItemEvent extends CartEvent {
  final Product product;

  const CartAddItemEvent({required this.product});

  @override
  List<Object?> get props => [product.id];
}

/// Update item quantity
class CartUpdateQuantityEvent extends CartEvent {
  final String itemId;
  final int quantity;

  const CartUpdateQuantityEvent({
    required this.itemId,
    required this.quantity,
  });

  @override
  List<Object?> get props => [itemId, quantity];
}

/// Remove item from cart
class CartRemoveItemEvent extends CartEvent {
  final String itemId;

  const CartRemoveItemEvent({required this.itemId});

  @override
  List<Object?> get props => [itemId];
}

/// Clear entire cart
class CartClearEvent extends CartEvent {
  const CartClearEvent();
}

/// Select delivery type
class CartSelectDeliveryEvent extends CartEvent {
  final DeliveryType deliveryType;

  const CartSelectDeliveryEvent({required this.deliveryType});

  @override
  List<Object?> get props => [deliveryType];
}

/// Select pickup point
class CartSelectPickupPointEvent extends CartEvent {
  final PickupPoint? pickupPoint;

  const CartSelectPickupPointEvent({this.pickupPoint});

  @override
  List<Object?> get props => [pickupPoint?.id];
}

/// Set order comment
class CartSetCommentEvent extends CartEvent {
  final String comment;

  const CartSetCommentEvent({required this.comment});

  @override
  List<Object?> get props => [comment];
}

/// Create order for checkout
class CartCheckoutEvent extends CartEvent {
  final String? userName;
  final String? userPhone;

  const CartCheckoutEvent({this.userName, this.userPhone});

  @override
  List<Object?> get props => [userName, userPhone];
}

/// Clear pending order
class CartClearPendingOrderEvent extends CartEvent {
  const CartClearPendingOrderEvent();
}
