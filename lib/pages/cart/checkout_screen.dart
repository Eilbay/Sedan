import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:optombai/bloc/cart_bloc/cart_bloc.dart';
import 'package:optombai/bloc/order_bloc/order_bloc.dart';
import 'package:optombai/core/theme_notifier.dart';
import 'package:optombai/data/models/cart/delivery_type.dart';
import 'package:optombai/data/models/cart/order_model.dart';
import 'package:optombai/data/models/cart/pickup_point_model.dart';
import 'package:optombai/app/router/app_router.dart';
import 'package:optombai/widgets/common/price_row.dart';
import 'package:auto_route/auto_route.dart';

/// Checkout screen with order summary and pmt button
/// TODO: Integrate with real backend order API when ready
@RoutePage()
class CheckoutScreen extends StatelessWidget {
  const CheckoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.select((ThemeNotifier n) => n.isDarkMode);

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF0A1C2C) : Colors.grey[50],
      appBar: AppBar(
        backgroundColor: isDarkMode ? const Color(0xFF0A1C2C) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
          onPressed: () => context.router.maybePop(),
        ),
        title: Text(
          'Оформление заказа',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: BlocBuilder<CartBloc, CartState>(
        buildWhen: (previous, current) =>
            previous.pendingOrder != current.pendingOrder,
        builder: (context, state) {
          final order = state.pendingOrder;

          if (order == null) {
            return const Center(
              child: Text('Нет данных заказа'),
            );
          }

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding:
                      EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Order number
                      _OrderHeader(order: order, isDarkMode: isDarkMode),
                      SizedBox(height: 10.h),

                      // Order items summary
                      _ItemsSummary(
                        order: order,
                        isDarkMode: isDarkMode,
                        formatPrice: _formatPrice,
                      ),
                      SizedBox(height: 8.h),

                      // Delivery info
                      _DeliveryInfo(order: order, isDarkMode: isDarkMode),
                      SizedBox(height: 8.h),

                      // Price breakdown
                      _PriceBreakdown(
                        order: order,
                        isDarkMode: isDarkMode,
                        formatPrice: _formatPrice,
                      ),
                    ],
                  ),
                ),
              ),

              // Pay button
              _PayButton(
                order: order,
                onPay: () => _openPaymentScreen(context, order),
              ),
            ],
          );
        },
      ),
    );
  }

  void _openPaymentScreen(BuildContext context, Order order) {
    // Save order first
    context.read<OrderBloc>().add(OrderSaveEvent(order: order));

    // Open pmt method selection screen
    context.router.push(CartPaymentRoute(order: order));
  }

  static String _formatPrice(double price) {
    if (price == price.truncate()) {
      return '${price.truncate()} \u20BD';
    }
    return '${price.toStringAsFixed(2)} \u20BD';
  }
}

// ---------------------------------------------------------------------------
// Private widgets
// ---------------------------------------------------------------------------

class _OrderHeader extends StatelessWidget {
  final Order order;
  final bool isDarkMode;

  const _OrderHeader({required this.order, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xff0e1e33) : Colors.white,
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Row(
        children: [
          Icon(Icons.receipt_long, size: 32.sp, color: const Color(0xffFFA800)),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Заказ №${order.id}',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                Text(
                  'Ожидает оплаты',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.orange,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemsSummary extends StatelessWidget {
  final Order order;
  final bool isDarkMode;
  final String Function(double) formatPrice;

  const _ItemsSummary({
    required this.order,
    required this.isDarkMode,
    required this.formatPrice,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xff0e1e33) : Colors.white,
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Товары (${order.totalItems})',
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          SizedBox(height: 6.h),
          ...order.items.map((item) => Padding(
                padding: EdgeInsets.only(bottom: 4.h),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.productName,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: isDarkMode ? Colors.white70 : Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${item.quantity}×${formatPrice(item.price)}',
                      style:
                          TextStyle(fontSize: 11.sp, color: Colors.grey[500]),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _DeliveryInfo extends StatelessWidget {
  final Order order;
  final bool isDarkMode;

  const _DeliveryInfo({required this.order, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    final pickupPoint = PickupPoint.findById(order.pickupPointId);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xff0e1e33) : Colors.white,
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Row(
        children: [
          Icon(Icons.location_on, size: 18.sp, color: Colors.blue),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.deliveryType == DeliveryType.pickup
                      ? (pickupPoint?.name ?? 'Пункт выдачи')
                      : 'Курьерская доставка',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                if (pickupPoint != null)
                  Text(
                    pickupPoint.address,
                    style: TextStyle(fontSize: 11.sp, color: Colors.grey[500]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceBreakdown extends StatelessWidget {
  final Order order;
  final bool isDarkMode;
  final String Function(double) formatPrice;

  const _PriceBreakdown({
    required this.order,
    required this.isDarkMode,
    required this.formatPrice,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xff0e1e33) : Colors.white,
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Column(
        children: [
          PriceRow(
            label: 'Подытог',
            value: formatPrice(order.subtotal),
            isDarkMode: isDarkMode,
          ),
          SizedBox(height: 4.h),
          PriceRow(
            label: 'Доставка',
            value: order.deliveryCost == 0
                ? 'Бесплатно'
                : formatPrice(order.deliveryCost),
            isDarkMode: isDarkMode,
            isGreen: order.deliveryCost == 0,
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 6.h),
            child: Divider(color: Colors.grey[300], height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'К оплате',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              Text(
                formatPrice(order.total),
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xffFFA800),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PayButton extends StatelessWidget {
  final Order order;
  final VoidCallback onPay;

  const _PayButton({required this.order, required this.onPay});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 44.h,
          child: ElevatedButton(
            onPressed: onPay,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xffFFA800),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r)),
              elevation: 0,
            ),
            child: Text(
              'Оплатить ${CheckoutScreen._formatPrice(order.total)}',
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }
}
