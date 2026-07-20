import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:optombai/data/models/cart/order_model.dart';
import 'package:optombai/services/cart_storage_service.dart';

part 'order_event.dart';
part 'order_state.dart';

/// BLoC for order management
/// TODO: Replace local storage with API calls when backend is ready
class OrderBloc extends Bloc<OrderEvent, OrderState> {
  final CartStorageService _storageService;
  Timer? _statusCheckTimer;

  OrderBloc(this._storageService) : super(const OrderState()) {
    on<OrderLoadEvent>(_onLoad);
    on<OrderSaveEvent>(_onSave);
    on<OrderPaymentSuccessEvent>(_onPaymentSuccess);
    on<OrderCheckStatusUpdatesEvent>(_onCheckStatusUpdates);
    on<OrderDeleteEvent>(_onDelete);

    // Start periodic status check (every hour)
    _startStatusCheckTimer();
  }

  void _startStatusCheckTimer() {
    _statusCheckTimer?.cancel();
    _statusCheckTimer = Timer.periodic(
      const Duration(hours: 1),
      (_) => add(const OrderCheckStatusUpdatesEvent()),
    );
  }

  @override
  Future<void> close() {
    _statusCheckTimer?.cancel();
    return super.close();
  }

  Future<void> _onLoad(OrderLoadEvent event, Emitter<OrderState> emit) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final orders = _storageService.getOrders();
      emit(state.copyWith(orders: orders, isLoading: false));

      // Check for status updates on load
      add(const OrderCheckStatusUpdatesEvent());
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onSave(OrderSaveEvent event, Emitter<OrderState> emit) async {
    try {
      await _storageService.saveOrder(event.order);
      final orders = _storageService.getOrders();
      emit(state.copyWith(orders: orders, clearError: true));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _onPaymentSuccess(
      OrderPaymentSuccessEvent event, Emitter<OrderState> emit) async {
    try {
      await _storageService.markOrderPaid(event.orderId);
      final orders = _storageService.getOrders();
      emit(state.copyWith(
        orders: orders,
        paymentSuccess: true,
        clearError: true,
      ));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _onCheckStatusUpdates(
      OrderCheckStatusUpdatesEvent event, Emitter<OrderState> emit) async {
    try {
      final hasUpdates = await _storageService.checkAndUpdateOrderStatuses();
      if (hasUpdates) {
        final orders = _storageService.getOrders();
        emit(state.copyWith(orders: orders));
      }
    } catch (e) {
      // Silent fail for background status check
    }
  }

  Future<void> _onDelete(
      OrderDeleteEvent event, Emitter<OrderState> emit) async {
    try {
      await _storageService.deleteOrder(event.orderId);
      final orders = _storageService.getOrders();
      emit(state.copyWith(orders: orders, clearError: true));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }
}
