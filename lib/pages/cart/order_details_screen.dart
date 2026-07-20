import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:optombai/bloc/order_bloc/order_bloc.dart';
import 'package:optombai/core/theme_notifier.dart';
import 'package:optombai/data/models/cart/delivery_type.dart';
import 'package:optombai/data/models/cart/order_model.dart';
import 'package:optombai/data/models/cart/pickup_point_model.dart';
import 'package:optombai/widgets/cart/order_status_timeline.dart';
import 'package:optombai/widgets/common/price_row.dart';
import 'package:auto_route/auto_route.dart';

/// Order details screen with status timeline
@RoutePage()
class OrderDetailsScreen extends StatelessWidget {
  final String orderId;

  const OrderDetailsScreen({
    super.key,
    required this.orderId,
  });

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
          'Заказ №$orderId',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: BlocBuilder<OrderBloc, OrderState>(
        buildWhen: (previous, current) =>
            previous.orders != current.orders,
        builder: (context, state) {
          final order = state.getOrderById(orderId);

          if (order == null) {
            return const Center(
              child: Text('Заказ не найден'),
            );
          }

          return SingleChildScrollView(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status timeline
                _StatusSection(order: order, isDarkMode: isDarkMode),
                SizedBox(height: 24.h),

                // Delivery info
                _OrderDeliverySection(order: order, isDarkMode: isDarkMode),
                SizedBox(height: 16.h),

                // Order items
                _OrderItemsSection(
                  order: order,
                  isDarkMode: isDarkMode,
                  formatPrice: _formatPrice,
                ),
                SizedBox(height: 16.h),

                // Price summary
                _OrderPriceSection(
                  order: order,
                  isDarkMode: isDarkMode,
                  formatPrice: _formatPrice,
                ),
              ],
            ),
          );
        },
      ),
    );
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

class _StatusSection extends StatelessWidget {
  final Order order;
  final bool isDarkMode;

  const _StatusSection({required this.order, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xff0e1e33) : Colors.white,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Статус заказа',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          SizedBox(height: 16.h),
          OrderStatusTimeline(
            statusHistory: order.statusHistory,
            showAllSteps: true,
          ),
        ],
      ),
    );
  }
}

class _OrderDeliverySection extends StatelessWidget {
  final Order order;
  final bool isDarkMode;

  const _OrderDeliverySection({
    required this.order,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    final pickupPoint = PickupPoint.findById(order.pickupPointId);

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xff0e1e33) : Colors.white,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Информация о доставке',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          SizedBox(height: 12.h),

          // Delivery type
          _InfoRow(
            icon: Icons.local_shipping,
            text: order.deliveryType.displayName,
            isDarkMode: isDarkMode,
          ),

          // Pickup point
          if (pickupPoint != null) ...[
            SizedBox(height: 12.h),
            _InfoRow(
              icon: Icons.location_on,
              text: '${pickupPoint.name}\n${pickupPoint.address}',
              isDarkMode: isDarkMode,
              iconColor: Colors.blue,
            ),
          ],

          // Order date
          SizedBox(height: 12.h),
          _InfoRow(
            icon: Icons.calendar_today,
            text: 'Оформлен: ${DateFormat('dd.MM.yyyy в HH:mm').format(order.createdAt)}',
            isDarkMode: isDarkMode,
          ),

          // Pmt date
          if (order.paidAt != null) ...[
            SizedBox(height: 12.h),
            _InfoRow(
              icon: Icons.payment,
              text: 'Оплачен: ${DateFormat('dd.MM.yyyy в HH:mm').format(order.paidAt!)}',
              isDarkMode: isDarkMode,
              iconColor: Colors.green,
            ),
          ],

          // Comment
          if (order.comment != null && order.comment!.isNotEmpty) ...[
            SizedBox(height: 12.h),
            _InfoRow(
              icon: Icons.comment,
              text: 'Комментарий: ${order.comment}',
              isDarkMode: isDarkMode,
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isDarkMode;
  final Color? iconColor;

  const _InfoRow({
    required this.icon,
    required this.text,
    required this.isDarkMode,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20.sp,
          color: iconColor ?? Colors.grey,
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13.sp,
              color: isDarkMode ? Colors.white70 : Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}

class _OrderItemsSection extends StatelessWidget {
  final Order order;
  final bool isDarkMode;
  final String Function(double) formatPrice;

  const _OrderItemsSection({
    required this.order,
    required this.isDarkMode,
    required this.formatPrice,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xff0e1e33) : Colors.white,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Товары (${order.totalItems})',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          SizedBox(height: 12.h),
          ...order.items.map((item) => Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8.r),
                      child: Container(
                        width: 50.w,
                        height: 50.w,
                        color: Colors.grey[200],
                        child: item.productImage != null
                            ? CachedNetworkImage(
                                imageUrl: item.productImage!,
                                fit: BoxFit.cover,
                                errorWidget: (_, __, ___) => Icon(
                                  Icons.image,
                                  color: Colors.grey[400],
                                ),
                              )
                            : Icon(
                                Icons.image,
                                color: Colors.grey[400],
                              ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    // Product info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.productName,
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w500,
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            '${item.quantity} шт. × ${formatPrice(item.price)}',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Item total
                    Text(
                      formatPrice(item.totalPrice),
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _OrderPriceSection extends StatelessWidget {
  final Order order;
  final bool isDarkMode;
  final String Function(double) formatPrice;

  const _OrderPriceSection({
    required this.order,
    required this.isDarkMode,
    required this.formatPrice,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xff0e1e33) : Colors.white,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        children: [
          PriceRow(
            label: 'Подытог',
            value: formatPrice(order.subtotal),
            isDarkMode: isDarkMode,
            fontSize: 14.sp,
          ),
          SizedBox(height: 8.h),
          PriceRow(
            label: 'Доставка',
            value: order.deliveryCost == 0
                ? 'Бесплатно'
                : formatPrice(order.deliveryCost),
            isDarkMode: isDarkMode,
            isGreen: order.deliveryCost == 0,
            fontSize: 14.sp,
          ),
          SizedBox(height: 12.h),
          Divider(color: Colors.grey[300]),
          SizedBox(height: 12.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Итого',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              Text(
                formatPrice(order.total),
                style: TextStyle(
                  fontSize: 18.sp,
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
