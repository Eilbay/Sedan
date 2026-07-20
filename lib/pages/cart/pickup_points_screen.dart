import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:optombai/bloc/cart_bloc/cart_bloc.dart';
import 'package:optombai/core/theme_notifier.dart';
import 'package:optombai/data/models/cart/pickup_point_model.dart';
import 'package:optombai/widgets/cart/pickup_point_card.dart';
import 'package:auto_route/auto_route.dart';

/// Screen for selecting pickup point
/// TODO: Replace hardcoded points with API data when backend is ready
@RoutePage()
class PickupPointsScreen extends StatelessWidget {
  const PickupPointsScreen({super.key});

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
          'Пункт выдачи',
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
            previous.selectedPickupPoint != current.selectedPickupPoint,
        builder: (context, state) {
          return ListView.builder(
            padding: EdgeInsets.all(16.w),
            itemCount: PickupPoint.bishkekPoints.length,
            itemBuilder: (context, index) {
              final point = PickupPoint.bishkekPoints[index];
              final isSelected = state.selectedPickupPoint?.id == point.id;

              return Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: PickupPointCard(
                  point: point,
                  isSelected: isSelected,
                  onSelect: () => _selectPoint(context, point),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _selectPoint(BuildContext context, PickupPoint point) {
    context.read<CartBloc>().add(CartSelectPickupPointEvent(pickupPoint: point));
    context.router.maybePop();
  }
}
