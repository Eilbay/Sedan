import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:optombai/bloc/cart_bloc/cart_bloc.dart';
import 'package:optombai/bloc/order_bloc/order_bloc.dart';
import 'package:optombai/core/theme_notifier.dart';
import 'package:optombai/pages/cart/cart_tab.dart';
import 'package:optombai/pages/cart/orders_tab.dart';

/// TODO: This screen will replace FavoriteScreen when cart API is implemented
class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Load cart and orders on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CartBloc>().add(const CartLoadEvent());
      context.read<OrderBloc>().add(const OrderLoadEvent());
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.select((ThemeNotifier n) => n.isDarkMode);

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF0A1C2C) : Colors.grey[50],
      appBar: AppBar(
        backgroundColor: isDarkMode ? const Color(0xFF0A1C2C) : Colors.white,
        elevation: 0,
        title: Text(
          'Корзина',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(48.h),
          child: Container(
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xff0e1e33) : Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey[200]!,
                  width: 1,
                ),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: const Color(0xffFFA800),
              unselectedLabelColor: isDarkMode ? Colors.white70 : Colors.grey,
              indicatorColor: const Color(0xffFFA800),
              indicatorWeight: 3,
              labelStyle: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
              ),
              tabs: [
                Tab(
                  child: BlocBuilder<CartBloc, CartState>(
                    buildWhen: (previous, current) =>
                        previous.items != current.items,
                    builder: (context, state) {
                      final count = state.itemCount;
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Корзина'),
                          if (count > 0) ...[
                            SizedBox(width: 6.w),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 6.w,
                                vertical: 2.h,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xffFFA800),
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                              child: Text(
                                count.toString(),
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ),
                const Tab(text: 'Мои заказы'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          CartTab(),
          OrdersTab(),
        ],
      ),
    );
  }
}
