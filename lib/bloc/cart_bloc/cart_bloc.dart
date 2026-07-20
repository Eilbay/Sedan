import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:optombai/data/models/cart/cart_item_model.dart';
import 'package:optombai/data/models/cart/delivery_type.dart';
import 'package:optombai/data/models/cart/order_model.dart';
import 'package:optombai/data/models/cart/order_status_model.dart';
import 'package:optombai/data/models/cart/pickup_point_model.dart';
import 'package:optombai/data/models/posts/post_model.dart';
import 'package:optombai/services/cart_storage_service.dart';

part 'cart_event.dart';
part 'cart_state.dart';

/// BLoC for cart management
/// TODO: Replace local storage with API calls when backend is ready
class CartBloc extends Bloc<CartEvent, CartState> {
  final CartStorageService _storageService;

  CartBloc(this._storageService) : super(const CartState()) {
    on<CartLoadEvent>(_onLoad);
    on<CartAddItemEvent>(_onAddItem);
    on<CartUpdateQuantityEvent>(_onUpdateQuantity);
    on<CartRemoveItemEvent>(_onRemoveItem);
    on<CartClearEvent>(_onClear);
    on<CartSelectDeliveryEvent>(_onSelectDelivery);
    on<CartSelectPickupPointEvent>(_onSelectPickupPoint);
    on<CartSetCommentEvent>(_onSetComment);
    on<CartCheckoutEvent>(_onCheckout);
    on<CartClearPendingOrderEvent>(_onClearPendingOrder);
  }

  Future<void> _onLoad(CartLoadEvent event, Emitter<CartState> emit) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final items = _storageService.getCartItems();

      // Load saved pickup point
      final savedPickupPointId = await _storageService.getSelectedPickupPointId();
      final savedPickupPoint = savedPickupPointId != null
          ? PickupPoint.findById(savedPickupPointId)
          : null;

      emit(state.copyWith(
        items: items,
        isLoading: false,
        selectedPickupPoint: savedPickupPoint,
      ));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onAddItem(
      CartAddItemEvent event, Emitter<CartState> emit) async {
    try {
      final cartItem = CartItem.fromProduct(event.product);
      await _storageService.addToCart(cartItem);
      final items = _storageService.getCartItems();
      emit(state.copyWith(items: items, clearError: true));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _onUpdateQuantity(
      CartUpdateQuantityEvent event, Emitter<CartState> emit) async {
    try {
      await _storageService.updateQuantity(event.itemId, event.quantity);
      final items = _storageService.getCartItems();
      emit(state.copyWith(items: items, clearError: true));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _onRemoveItem(
      CartRemoveItemEvent event, Emitter<CartState> emit) async {
    try {
      await _storageService.removeFromCart(event.itemId);
      final items = _storageService.getCartItems();
      emit(state.copyWith(items: items, clearError: true));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _onClear(CartClearEvent event, Emitter<CartState> emit) async {
    try {
      await _storageService.clearCart();
      await _storageService.clearSelectedPickupPoint();
      emit(state.copyWith(
        items: [],
        clearPendingOrder: true,
        comment: '',
        clearPickupPoint: true,
        deliveryType: DeliveryType.pickup,
        clearError: true,
      ));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  void _onSelectDelivery(
      CartSelectDeliveryEvent event, Emitter<CartState> emit) {
    emit(state.copyWith(deliveryType: event.deliveryType, clearError: true));
  }

  Future<void> _onSelectPickupPoint(
      CartSelectPickupPointEvent event, Emitter<CartState> emit) async {
    // Save pickup point to storage
    await _storageService.saveSelectedPickupPointId(event.pickupPoint?.id);

    if (event.pickupPoint == null) {
      emit(state.copyWith(clearPickupPoint: true, clearError: true));
    } else {
      emit(state.copyWith(
          selectedPickupPoint: event.pickupPoint, clearError: true));
    }
  }

  void _onSetComment(CartSetCommentEvent event, Emitter<CartState> emit) {
    emit(state.copyWith(comment: event.comment, clearError: true));
  }

  Future<void> _onCheckout(
      CartCheckoutEvent event, Emitter<CartState> emit) async {
    if (state.items.isEmpty) return;

    try {
      final order = Order(
        id: Order.generateOrderNumber(),
        items: List.from(state.items),
        subtotal: state.subtotal,
        deliveryType: state.deliveryType,
        deliveryCost: state.deliveryCost,
        total: state.total,
        pickupPointId: state.selectedPickupPoint?.id,
        comment: state.comment.isEmpty ? null : state.comment,
        createdAt: DateTime.now(),
        statusHistory: [OrderStatus.created()],
        userName: event.userName,
        userPhone: event.userPhone,
      );

      emit(state.copyWith(pendingOrder: order, clearError: true));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  void _onClearPendingOrder(
      CartClearPendingOrderEvent event, Emitter<CartState> emit) {
    emit(state.copyWith(clearPendingOrder: true));
  }
}
