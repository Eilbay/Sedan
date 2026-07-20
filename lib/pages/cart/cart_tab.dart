import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:optombai/bloc/cart_bloc/cart_bloc.dart';
import 'package:optombai/core/theme_notifier.dart';
import 'package:optombai/data/models/cart/delivery_type.dart';
import 'package:optombai/app/router/app_router.dart';
import 'package:optombai/widgets/cart/cart_item_card.dart';
import 'package:optombai/widgets/cart/delivery_selector.dart';
import 'package:optombai/widgets/common/price_row.dart';
import 'package:auto_route/auto_route.dart';

/// Cart tab with items list, delivery options, and checkout button
@RoutePage(name: 'CartTabRoute')
class CartTab extends StatelessWidget {
  const CartTab({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.select((ThemeNotifier n) => n.isDarkMode);

    return BlocBuilder<CartBloc, CartState>(
      builder: (context, state) {
        if (state.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.isEmpty) {
          return RefreshIndicator(
            onRefresh: () async {
              context.read<CartBloc>().add(const CartLoadEvent());
            },
            child: ListView(
              children: [
                SizedBox(height: 200.h),
                _EmptyCartView(isDarkMode: isDarkMode),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Scrollable content
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  context.read<CartBloc>().add(const CartLoadEvent());
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Cart items
                      ...state.items.map((item) => Padding(
                            padding: EdgeInsets.only(bottom: 8.h),
                            child: CartItemCard(item: item),
                          )),

                      SizedBox(height: 8.h),

                      // Pickup point section
                      _PickupPointSection(
                        state: state,
                        isDarkMode: isDarkMode,
                        onPickupTap: () => _openPickupPointsScreen(context),
                      ),

                      SizedBox(height: 8.h),

                      // Delivery options
                      _DeliverySection(
                        state: state,
                        isDarkMode: isDarkMode,
                      ),

                      SizedBox(height: 8.h),

                      // Price summary
                      _PriceSummary(
                        state: state,
                        isDarkMode: isDarkMode,
                        formatPrice: _formatPrice,
                      ),

                      SizedBox(height: 70.h), // Space for button
                    ],
                  ),
                ),
              ),
            ),

            // Checkout button
            _CheckoutButton(
              state: state,
              onCheckout: () => _proceedToCheckout(context, state),
            ),
          ],
        );
      },
    );
  }

  void _openPickupPointsScreen(BuildContext context) {
    context.router.push(const PickupPointsRoute());
  }

  void _proceedToCheckout(BuildContext context, CartState state) {
    // Validate pickup point for pickup delivery
    if (state.deliveryType == DeliveryType.pickup &&
        state.selectedPickupPoint == null) {
      _openPickupPointsScreen(context);
      return;
    }

    // Create pending order and navigate to checkout
    context.read<CartBloc>().add(const CartCheckoutEvent());

    context.router.push(const CheckoutRoute());
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

class _EmptyCartView extends StatelessWidget {
  final bool isDarkMode;

  const _EmptyCartView({required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 80.sp,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16.h),
          Text(
            'Корзина пуста',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Добавьте товары, чтобы оформить заказ',
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

class _PickupPointSection extends StatelessWidget {
  final CartState state;
  final bool isDarkMode;
  final VoidCallback onPickupTap;

  const _PickupPointSection({
    required this.state,
    required this.isDarkMode,
    required this.onPickupTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xff0e1e33) : Colors.white,
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Row(
        children: [
          Icon(Icons.location_on, color: Colors.blue, size: 18.sp),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  state.selectedPickupPoint?.name ?? 'Пункт выдачи',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                if (state.selectedPickupPoint != null)
                  Text(
                    state.selectedPickupPoint!.address,
                    style: TextStyle(fontSize: 11.sp, color: Colors.grey[500]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 8.w),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: onPickupTap,
            child: Text(
              state.selectedPickupPoint != null ? 'Изменить' : 'Выбрать',
              style: TextStyle(fontSize: 12.sp, color: const Color(0xffFFA800)),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeliverySection extends StatelessWidget {
  final CartState state;
  final bool isDarkMode;

  const _DeliverySection({
    required this.state,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xff0e1e33) : Colors.white,
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: DeliverySelector(
        selectedType: state.deliveryType,
        onChanged: (type) {
          context.read<CartBloc>().add(CartSelectDeliveryEvent(deliveryType: type));
        },
      ),
    );
  }
}

class _PriceSummary extends StatelessWidget {
  final CartState state;
  final bool isDarkMode;
  final String Function(double) formatPrice;

  const _PriceSummary({
    required this.state,
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
            value: formatPrice(state.subtotal),
            isDarkMode: isDarkMode,
          ),
          SizedBox(height: 4.h),
          PriceRow(
            label: 'Доставка',
            value: state.deliveryCost == 0
                ? 'Бесплатно'
                : formatPrice(state.deliveryCost),
            isDarkMode: isDarkMode,
            isGreen: state.deliveryCost == 0,
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 6.h),
            child: Divider(color: Colors.grey[300], height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Итого',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              Text(
                formatPrice(state.total),
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

class _CheckoutButton extends StatelessWidget {
  final CartState state;
  final VoidCallback onCheckout;

  const _CheckoutButton({
    required this.state,
    required this.onCheckout,
  });

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
            onPressed: state.isEmpty ? null : onCheckout,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xffFFA800),
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey[300],
              disabledForegroundColor: Colors.grey[500],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
              elevation: 0,
            ),
            child: Text(
              'Оформить ${CartTab._formatPrice(state.total)}',
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }
}
