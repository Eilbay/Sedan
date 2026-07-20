import 'package:hive_flutter/hive_flutter.dart';
import 'package:optombai/data/models/cart/cart_item_model.dart';
import 'package:optombai/data/models/cart/order_model.dart';
import 'package:optombai/data/models/cart/order_status_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for cart and orders local storage using Hive
/// TODO: Replace with API calls when backend is ready
/// Currently all data is stored locally
class CartStorageService {
  static const String _cartBoxName = 'cartItems';
  static const String _ordersBoxName = 'orders';
  static const String _selectedPickupPointKey = 'selected_pickup_point_id';

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _sharedPrefs async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  Box<CartItem> get _cartBox => Hive.box<CartItem>(_cartBoxName);
  Box<Order> get _ordersBox => Hive.box<Order>(_ordersBoxName);

  // ============ Cart Operations ============

  /// Get all items in cart
  List<CartItem> getCartItems() {
    return _cartBox.values.toList();
  }

  /// Add product to cart or increase quantity if exists
  Future<void> addToCart(CartItem item) async {
    int existingIndex = -1;
    for (int i = 0; i < _cartBox.length; i++) {
      if (_cartBox.getAt(i)?.productId == item.productId) {
        existingIndex = i;
        break;
      }
    }

    if (existingIndex != -1) {
      final existing = _cartBox.getAt(existingIndex)!;
      await _cartBox.putAt(
        existingIndex,
        existing.copyWith(quantity: existing.quantity + 1),
      );
    } else {
      await _cartBox.add(item);
    }
  }

  /// Update quantity of cart item
  Future<void> updateQuantity(String itemId, int quantity) async {
    int index = -1;
    for (int i = 0; i < _cartBox.length; i++) {
      if (_cartBox.getAt(i)?.id == itemId) {
        index = i;
        break;
      }
    }
    if (index != -1) {
      final item = _cartBox.getAt(index)!;
      if (quantity <= 0) {
        await _cartBox.deleteAt(index);
      } else {
        await _cartBox.putAt(index, item.copyWith(quantity: quantity));
      }
    }
  }

  /// Remove item from cart
  Future<void> removeFromCart(String itemId) async {
    int index = -1;
    for (int i = 0; i < _cartBox.length; i++) {
      if (_cartBox.getAt(i)?.id == itemId) {
        index = i;
        break;
      }
    }
    if (index != -1) {
      await _cartBox.deleteAt(index);
    }
  }

  /// Clear entire cart
  Future<void> clearCart() async {
    await _cartBox.clear();
  }

  // ============ Pickup Point Operations ============

  /// Save selected pickup point ID
  Future<void> saveSelectedPickupPointId(String? pickupPointId) async {
    final prefs = await _sharedPrefs;
    if (pickupPointId != null) {
      await prefs.setString(_selectedPickupPointKey, pickupPointId);
    } else {
      await prefs.remove(_selectedPickupPointKey);
    }
  }

  /// Load saved pickup point ID
  Future<String?> getSelectedPickupPointId() async {
    final prefs = await _sharedPrefs;
    return prefs.getString(_selectedPickupPointKey);
  }

  /// Clear saved pickup point
  Future<void> clearSelectedPickupPoint() async {
    final prefs = await _sharedPrefs;
    await prefs.remove(_selectedPickupPointKey);
  }

  /// Check if product is in cart
  bool isInCart(String productId) {
    return _cartBox.values.any((item) => item.productId == productId);
  }

  /// Get cart item by product ID
  CartItem? getCartItemByProductId(String productId) {
    try {
      return _cartBox.values.firstWhere((item) => item.productId == productId);
    } catch (_) {
      return null;
    }
  }

  /// Get total items count in cart
  int get cartItemsCount {
    return _cartBox.values.fold(0, (sum, item) => sum + item.quantity);
  }

  /// Get cart subtotal
  double get cartSubtotal {
    return _cartBox.values.fold(0, (sum, item) => sum + item.totalPrice);
  }

  // ============ Order Operations ============

  /// Get all orders sorted by date (newest first)
  List<Order> getOrders() {
    final orders = _ordersBox.values.toList();
    orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return orders;
  }

  /// Get only paid orders
  List<Order> getPaidOrders() {
    return getOrders().where((o) => o.isPaid).toList();
  }

  /// Save new order
  Future<void> saveOrder(Order order) async {
    await _ordersBox.put(order.id, order);
  }

  /// Update order status
  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    final order = _ordersBox.get(orderId);
    if (order != null) {
      final updatedHistory = [...order.statusHistory, status];
      await _ordersBox.put(
        orderId,
        order.copyWith(statusHistory: updatedHistory),
      );
    }
  }

  /// Mark order as paid
  Future<void> markOrderPaid(String orderId) async {
    final order = _ordersBox.get(orderId);
    if (order != null) {
      await _ordersBox.put(
        orderId,
        order.copyWith(
          isPaid: true,
          paidAt: DateTime.now(),
        ),
      );
    }
  }

  /// Get order by ID
  Order? getOrder(String orderId) => _ordersBox.get(orderId);

  /// Delete order
  Future<void> deleteOrder(String orderId) async {
    await _ordersBox.delete(orderId);
  }

  /// Check and update order statuses based on time
  /// Works correctly even if app was closed for days
  /// TODO: This logic should be on backend when API is ready
  ///
  /// Timeline:
  /// 1. created - on payment
  /// 2. assembling - right after payment
  /// 3. delivered - next day at 16:00
  Future<bool> checkAndUpdateOrderStatuses() async {
    final now = DateTime.now();
    bool hasUpdates = false;

    for (final order in _ordersBox.values) {
      if (!order.isPaid || order.paidAt == null) continue;

      final paidAt = order.paidAt!;
      final currentStatus = order.currentStatus.type;

      // Assembling starts right after pmt
      final assemblingTime = paidAt.add(const Duration(minutes: 1));

      // Delivered at next day 16:00
      final deliveredTime = DateTime(
        paidAt.year,
        paidAt.month,
        paidAt.day + 1,
        16,
        0,
      );

      // Determine what status should be NOW
      OrderStatusType expectedStatus;
      if (now.isAfter(deliveredTime)) {
        expectedStatus = OrderStatusType.delivered;
      } else if (now.isAfter(assemblingTime)) {
        expectedStatus = OrderStatusType.assembling;
      } else {
        expectedStatus = OrderStatusType.created;
      }

      // Add missing statuses in order
      if (currentStatus != expectedStatus) {
        final statusesToAdd = <OrderStatus>[];

        if (currentStatus == OrderStatusType.created) {
          if (expectedStatus.index >= OrderStatusType.assembling.index) {
            statusesToAdd.add(OrderStatus(
              type: OrderStatusType.assembling,
              timestamp: assemblingTime,
              message: OrderStatusType.assembling.description,
            ));
          }
          if (expectedStatus == OrderStatusType.delivered) {
            statusesToAdd.add(OrderStatus(
              type: OrderStatusType.delivered,
              timestamp: deliveredTime,
              message: OrderStatusType.delivered.description,
            ));
          }
        } else if (currentStatus == OrderStatusType.assembling) {
          if (expectedStatus == OrderStatusType.delivered) {
            statusesToAdd.add(OrderStatus(
              type: OrderStatusType.delivered,
              timestamp: deliveredTime,
              message: OrderStatusType.delivered.description,
            ));
          }
        }

        // Apply all missing statuses
        if (statusesToAdd.isNotEmpty) {
          final updatedHistory = [...order.statusHistory, ...statusesToAdd];
          await _ordersBox.put(
            order.id,
            order.copyWith(statusHistory: updatedHistory),
          );
          hasUpdates = true;
        }
      }
    }

    return hasUpdates;
  }
}
