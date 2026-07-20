import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:optombai/data/models/cart/order_model.dart';
import 'package:optombai/data/models/cart/order_status_model.dart';

/// Card for displaying order in list
class OrderCard extends StatelessWidget {
  final Order order;
  final VoidCallback? onTap;

  const OrderCard({
    super.key,
    required this.order,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12.r),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row: Order number and status
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Заказ №${order.id}',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Flexible(
                    child: _buildStatusChip(order.currentStatus),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              // Order info
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16.sp, color: Colors.grey),
                  SizedBox(width: 8.w),
                  Text(
                    DateFormat('dd.MM.yyyy, HH:mm').format(order.createdAt),
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              Row(
                children: [
                  Icon(Icons.shopping_bag, size: 16.sp, color: Colors.grey),
                  SizedBox(width: 8.w),
                  Text(
                    '${order.totalItems} ${_getItemsText(order.totalItems)}',
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              // Total
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Итого:',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    _formatPrice(order.total),
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
        ),
      ),
    );
  }

  Widget _buildStatusChip(OrderStatus status) {
    Color backgroundColor;
    Color textColor;

    switch (status.type) {
      case OrderStatusType.created:
        backgroundColor = Colors.blue[50]!;
        textColor = Colors.blue[700]!;
        break;
      case OrderStatusType.assembling:
        backgroundColor = Colors.orange[50]!;
        textColor = Colors.orange[700]!;
        break;
      case OrderStatusType.delivered:
        backgroundColor = Colors.green[50]!;
        textColor = Colors.green[700]!;
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Text(
        status.type.displayName,
        style: TextStyle(
          fontSize: 11.sp,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
    );
  }

  String _getItemsText(int count) {
    if (count % 10 == 1 && count % 100 != 11) {
      return 'товар';
    } else if ([2, 3, 4].contains(count % 10) &&
        ![12, 13, 14].contains(count % 100)) {
      return 'товара';
    } else {
      return 'товаров';
    }
  }

  String _formatPrice(double price) {
    if (price == price.truncate()) {
      return '${price.truncate()} \u20BD';
    }
    return '${price.toStringAsFixed(2)} \u20BD';
  }
}
