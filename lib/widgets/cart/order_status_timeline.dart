import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:optombai/data/models/cart/order_status_model.dart';

/// Timeline widget for displaying order status history
/// Design: orange dots connected by lines
class OrderStatusTimeline extends StatelessWidget {
  final List<OrderStatus> statusHistory;
  final bool showAllSteps;

  const OrderStatusTimeline({
    super.key,
    required this.statusHistory,
    this.showAllSteps = true,
  });

  @override
  Widget build(BuildContext context) {
    // All possible steps
    final allSteps = [
      OrderStatusType.created,
      OrderStatusType.assembling,
      OrderStatusType.delivered,
    ];

    // Find current status index
    final currentStatusIndex = statusHistory.isNotEmpty
        ? allSteps.indexOf(statusHistory.last.type)
        : -1;

    if (!showAllSteps) {
      // Only show completed steps
      return Column(
        children: statusHistory.asMap().entries.map((entry) {
          final index = entry.key;
          final status = entry.value;
          final isLast = index == statusHistory.length - 1;

          return _StatusStep(
            status: status,
            isCompleted: true,
            isCurrent: isLast,
            showLine: !isLast,
            lineCompleted: true,
          );
        }).toList(),
      );
    }

    // Show all steps with completion state
    return Column(
      children: allSteps.asMap().entries.map((entry) {
        final index = entry.key;
        final stepType = entry.value;
        final isLast = index == allSteps.length - 1;
        final isCompleted = index <= currentStatusIndex;
        final isCurrent = index == currentStatusIndex;

        // Find matching status from history
        OrderStatus? status;
        try {
          status = statusHistory.firstWhere((s) => s.type == stepType);
        } catch (_) {
          status = null;
        }

        return _StatusStep(
          status: status ??
              OrderStatus(
                type: stepType,
                timestamp: DateTime.now(),
                message: stepType.description,
              ),
          isCompleted: isCompleted,
          isCurrent: isCurrent,
          showLine: !isLast,
          lineCompleted: index < currentStatusIndex,
        );
      }).toList(),
    );
  }

}

class _StatusStep extends StatelessWidget {
  final OrderStatus status;
  final bool isCompleted;
  final bool isCurrent;
  final bool showLine;
  final bool lineCompleted;

  const _StatusStep({
    required this.status,
    required this.isCompleted,
    required this.isCurrent,
    required this.showLine,
    required this.lineCompleted,
  });

  @override
  Widget build(BuildContext context) {
    const orangeColor = Color(0xffFFA800);
    final greyColor = Colors.grey[300]!;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline column (dot + line)
        SizedBox(
          width: 32.w,
          child: Column(
            children: [
              // Dot
              Container(
                width: 24.w,
                height: 24.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted ? orangeColor : Colors.white,
                  border: Border.all(
                    color: isCompleted ? orangeColor : greyColor,
                    width: 2,
                  ),
                ),
                child: isCompleted
                    ? Icon(
                        _getStatusIcon(status.type),
                        color: Colors.white,
                        size: 14.sp,
                      )
                    : null,
              ),
              // Line
              if (showLine)
                Container(
                  width: 2,
                  height: 50.h,
                  margin: EdgeInsets.symmetric(vertical: 4.h),
                  decoration: BoxDecoration(
                    color: lineCompleted ? orangeColor : greyColor,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(width: 12.w),
        // Status info
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: showLine ? 16.h : 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status.type.displayName,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w500,
                    color: isCompleted ? Colors.black : Colors.grey[500],
                  ),
                ),
                SizedBox(height: 2.h),
                if (isCompleted)
                  Text(
                    DateFormat('dd.MM.yyyy, HH:mm').format(status.timestamp),
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.grey[500],
                    ),
                  )
                else
                  Text(
                    status.message,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.grey[400],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  IconData _getStatusIcon(OrderStatusType type) {
    switch (type) {
      case OrderStatusType.created:
        return Icons.check;
      case OrderStatusType.assembling:
        return Icons.inventory;
      case OrderStatusType.delivered:
        return Icons.location_on;
    }
  }
}
