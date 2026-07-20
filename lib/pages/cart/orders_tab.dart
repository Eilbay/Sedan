import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:optombai/bloc/order_bloc/order_bloc.dart';
import 'package:optombai/core/theme_notifier.dart';
import 'package:optombai/app/router/app_router.dart';
import 'package:optombai/widgets/cart/order_card.dart';
import 'package:optombai/widgets/shimmer/shimmer_list_tile.dart';
import 'package:auto_route/auto_route.dart';

/// Orders tab showing paid orders with status
@RoutePage(name: 'OrdersTabRoute')
class OrdersTab extends StatelessWidget {
  const OrdersTab({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.select((ThemeNotifier n) => n.isDarkMode);

    return BlocBuilder<OrderBloc, OrderState>(
      buildWhen: (previous, current) =>
          previous.orders != current.orders ||
          previous.isLoading != current.isLoading,
      builder: (context, state) {
        if (state.isLoading) {
          return Column(
            children: List.generate(
              4,
              (_) => const ShimmerListTile(),
            ),
          );
        }

        final paidOrders = state.paidOrders;

        if (paidOrders.isEmpty) {
          return _EmptyOrdersView(isDarkMode: isDarkMode);
        }

        return RefreshIndicator(
          onRefresh: () async {
            context.read<OrderBloc>().add(const OrderLoadEvent());
          },
          child: ListView.builder(
            padding: EdgeInsets.all(16.w),
            itemCount: paidOrders.length,
            itemBuilder: (context, index) {
              final order = paidOrders[index];
              return Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: OrderCard(
                  order: order,
                  onTap: () => _openOrderDetails(context, order.id),
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _openOrderDetails(BuildContext context, String orderId) {
    context.router.push(OrderDetailsRoute(orderId: orderId));
  }
}

class _EmptyOrdersView extends StatelessWidget {
  final bool isDarkMode;

  const _EmptyOrdersView({required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 80.sp,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16.h),
          Text(
            'Заказов пока нет',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Оформите первый заказ',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}
