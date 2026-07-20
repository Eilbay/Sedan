import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:optombai/bloc/button_visible_bloc/button_visible_bloc.dart';
import 'package:optombai/bloc/cart_bloc/cart_bloc.dart';
import 'package:optombai/bloc/order_bloc/order_bloc.dart';
import 'package:optombai/bloc/user_bloc/user_bloc.dart';
import 'package:optombai/core/form_status.dart';
import 'package:optombai/data/models/cart/delivery_type.dart';
import 'package:optombai/data/models/cart/order_model.dart';
import 'package:optombai/data/models/cart/pickup_point_model.dart';
import 'package:optombai/app/router/app_router.dart';
import 'package:optombai/paybox/paybox_client.dart';
import 'package:optombai/services/iap_service.dart';
import 'package:auto_route/auto_route.dart';

/// Pmt method selection screen for cart orders
@RoutePage()
class CartPaymentScreen extends StatefulWidget {
  final Order order;

  const CartPaymentScreen({
    super.key,
    required this.order,
  });

  @override
  State<CartPaymentScreen> createState() => _CartPaymentScreenState();
}

enum CartPaymentMethod { finik, freedom, iap }

class _CartPaymentScreenState extends State<CartPaymentScreen> {
  final PayboxClient _payboxClient = PayboxClient();
  final IAPService _iapService = IAPService();
  bool _processing = false;
  CartPaymentMethod _selected = CartPaymentMethod.finik;

  bool get _showIAP => _iapService.isAvailable;

  String _generatePaymentOrderId() {
    final timestamp = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
    return 'CART_$timestamp';
  }

  String _buildOrderDescription() {
    final order = widget.order;
    final user = context.read<UserBloc>().state.user;
    final pickupPoint = PickupPoint.findById(order.pickupPointId);

    final buffer = StringBuffer();
    buffer.writeln('Заказ №${order.id}');
    buffer.writeln('Сумма: ${order.total} KGS');
    buffer.writeln('Покупатель: ${user.username}');
    buffer.writeln('Телефон: ${user.phone_number}');

    // Products with article numbers
    for (final item in order.items) {
      final artNum = (item.productNumber != null && item.productNumber! > 0)
          ? item.productNumber.toString()
          : item.productId;
      buffer.writeln('- ${item.productName} (арт. $artNum) x${item.quantity} — ${item.price.toStringAsFixed(0)} сом');
    }

    buffer.writeln('Доставка: ${order.deliveryType.displayName}');
    if (pickupPoint != null) {
      buffer
          .writeln('Пункт выдачи: ${pickupPoint.name}, ${pickupPoint.address}');
    }

    return buffer.toString();
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bvState = context.watch<ButtonVisibleBloc>().state;
    final isHiddenMode = bvState.status == FormStatus.submissionSuccess &&
        !bvState.isVisible;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Stack(
          children: [
            GestureDetector(
              onTap: () {
                if (!_processing) context.router.maybePop();
              },
              child: Container(
                color: Colors.black.withValues(alpha: 0.35),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Material(
                    borderRadius: BorderRadius.circular(24),
                    color: Colors.white,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Способ оплаты',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF201D2A),
                                ),
                              ),
                              IconButton(
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                icon: const Icon(Icons.close),
                                onPressed: () {
                                  if (!_processing) {
                                    context.router.maybePop();
                                  }
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Выберите удобный вам способ оплаты',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF88889A),
                            ),
                          ),
                          const SizedBox(height: 20),
                          if (!isHiddenMode) ...[
                            _PaymentOptionTile(
                              title:
                                  'QR или моб. приложение для\nКыргызстана 🇰🇬',
                              subtitle: 'MBank, Optima, Мой О! и другие',
                              icons: const [
                                'assets/cards/mbank.png',
                                'assets/cards/optimabank.png',
                                'assets/cards/obank.png',
                                'assets/cards/aiylbanklogo.png',
                              ],
                              selected: _selected == CartPaymentMethod.finik,
                              onTap: () {
                                setState(
                                    () => _selected = CartPaymentMethod.finik);
                              },
                            ),
                            const SizedBox(height: 12),
                            _PaymentOptionTile(
                              title: 'Банковская карта для всех\nстран 🌎',
                              subtitle: 'Visa, Mastercard, Элкарт и другие',
                              icons: const [
                                'assets/cards/visa.png',
                                'assets/cards/maestro.png',
                                'assets/cards/mastercard2.png',
                                'assets/cards/elcart.png',
                              ],
                              selected: _selected == CartPaymentMethod.freedom,
                              onTap: () {
                                setState(
                                    () => _selected = CartPaymentMethod.freedom);
                              },
                            ),
                            const SizedBox(height: 12),
                          ],
                          if (_showIAP)
                            _PaymentOptionTile(
                              title: Platform.isIOS ? 'Apple Pay' : 'Google Play',
                              subtitle: Platform.isIOS
                                  ? 'Быстрая оплата через Apple'
                                  : 'Быстрая оплата через Google',
                              icons: const [],
                              selected: _selected == CartPaymentMethod.iap,
                              onTap: () {
                                setState(
                                    () => _selected = CartPaymentMethod.iap);
                              },
                              leadingWidget: Platform.isIOS
                                  ? const _ApplePayBadge()
                                  : const _GooglePlayBadge(),
                            ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                gradient: const LinearGradient(
                                  colors: [
                                    Color.fromARGB(255, 80, 104, 129),
                                    Color.fromRGBO(0, 4, 8, 1),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x33007AFF),
                                    blurRadius: 8,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  elevation: 0,
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                onPressed: _processing ? null : _onPayPressed,
                                child: _processing
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.4,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Colors.white),
                                        ),
                                      )
                                    : Text(
                                        'Оплатить ${_formatPrice(widget.order.total)}',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                          if (!isHiddenMode) ...[
                            const SizedBox(height: 12),
                            _RussiaInfoButton(
                              onTap: () {
                                context.router.push(
                                  ManagerContactRoute(
                                      amount: widget.order.total),
                                );
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onPayPressed() async {
    if (_processing) return;

    if (widget.order.total <= 0) {
      _showError('Сумма заказа должна быть больше 0');
      return;
    }

    final user = context.read<UserBloc>().state.user;
    if (user.id.isEmpty) {
      _showError('Необходимо авторизоваться');
      return;
    }

    setState(() => _processing = true);

    try {
      if (_selected == CartPaymentMethod.iap) {
        await _processIAPPayment();
      } else if (_selected == CartPaymentMethod.finik) {
        await _processFinikPayment();
      } else {
        await _processCardPayment();
      }
    } catch (e) {
      debugPrint('Pmt error: $e');
      if (mounted) {
        _showError('Ошибка оплаты: ${e.toString()}');
      }
    }

    if (mounted) {
      setState(() => _processing = false);
    }
  }

  Future<void> _processIAPPayment() async {
    if (!_iapService.isAvailable) {
      _showError('In-App Purchase недоступен.');
      return;
    }

    // For cart we use consumable wallet products mapped by amount
    final product = _iapService.getPitProductByAmount(widget.order.total);
    if (product == null) {
      _showError('Продукт IAP для данной суммы не найден.');
      return;
    }

    _iapService.onPurchaseSuccess = (purchase) async {
      if (!mounted) return;
      await _iapService.finishPurchase(purchase);
      await _handlePaymentSuccess();
    };

    _iapService.onPurchaseError = (error) {
      if (!mounted) return;
      setState(() => _processing = false);
      _showError(error);
    };

    _iapService.onPurchasePending = () {};

    final success = await _iapService.buyConsumable(product);
    if (!success && mounted) {
      setState(() => _processing = false);
    }
  }

  Future<void> _processFinikPayment() async {
    final user = context.read<UserBloc>().state.user;
    final userPhone = user.phone_number;
    final userName = user.username;
    final userEmail = user.email;
    final paymentOrderId = _generatePaymentOrderId();
    final description = _buildOrderDescription();

    if (!mounted) return;

    final result = await context.router.push<bool>(
      FinikPaymentRoute(
        orderId: paymentOrderId,
        amount: widget.order.total,
        description: description,
        phone: userPhone,
        userName: userName,
        email: userEmail,
        onPaymentConfirmed: () async {
          await _handlePaymentSuccess();
        },
        onCancel: () {},
      ),
    );

    if (!mounted) return;

    if (result == false) {
      _showError('Оплата отменена');
    }
  }

  Future<void> _processCardPayment() async {
    final user = context.read<UserBloc>().state.user;
    final userId = user.id.toString();
    final userEmail = user.email;
    final userPhone = user.phone_number;
    final paymentOrderId = _generatePaymentOrderId();
    final description = _buildOrderDescription();

    String? redirectUrl;
    try {
      final pmt = await _payboxClient.createPayment(
        orderId: paymentOrderId,
        userId: userId,
        userEmail: userEmail,
        userPhone: userPhone,
        amount: widget.order.total,
        currencyCode: 'KGS',
        description: description,
      );
      redirectUrl = pmt?.redirectUrl;
    } catch (e) {
      debugPrint('createPayment error: $e');
      _showError('Не удалось инициализировать оплату');
      return;
    }

    if (redirectUrl == null || redirectUrl.isEmpty) {
      _showError('Не удалось получить ссылку для оплаты');
      return;
    }

    if (!mounted) return;

    final success = await context.router.push<bool>(WebViewRoute(
      url: redirectUrl,
      onPmtSuccess: () {},
    ));

    if (success == true) {
      await _handlePaymentSuccess();
    } else if (success == false) {
      _showError('Оплата отменена');
    }
  }

  Future<void> _handlePaymentSuccess() async {
    if (!mounted) return;

    context.read<OrderBloc>().add(
          OrderPaymentSuccessEvent(orderId: widget.order.id),
        );

    context.read<CartBloc>().add(const CartClearEvent());

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Оплата прошла успешно!'),
        backgroundColor: Colors.green,
      ),
    );

    context.router.replaceAll([BottomNavRoute(currentIndexOverride: 4)]);
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
      ),
    );
  }

  String _formatPrice(double price) {
    if (price == price.truncate()) {
      return '${price.truncate()} \u20BD';
    }
    return '${price.toStringAsFixed(2)} \u20BD';
  }
}

class _PaymentOptionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<String> icons;
  final bool selected;
  final VoidCallback onTap;
  final Widget? leadingWidget;

  const _PaymentOptionTile({
    required this.title,
    required this.subtitle,
    required this.icons,
    required this.selected,
    required this.onTap,
    this.leadingWidget,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? const Color(0xffFFA800) : const Color(0xFFE5E5EA),
            width: selected ? 2 : 1,
          ),
          color: selected
              ? const Color(0xffFFA800).withValues(alpha: 0.06)
              : Colors.white,
        ),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected
                      ? const Color(0xffFFA800)
                      : const Color(0xFFBBBBC4),
                  width: 2,
                ),
              ),
              child: selected
                  ? Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xffFFA800),
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF201D2A),
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF88889A),
                    ),
                  ),
                  if (icons.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: icons.take(4).map((icon) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.asset(
                              icon,
                              width: 32,
                              height: 22,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) =>
                                  const SizedBox.shrink(),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                  if (leadingWidget != null) ...[
                    const SizedBox(height: 8),
                    leadingWidget!,
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RussiaInfoButton extends StatelessWidget {
  final VoidCallback onTap;

  const _RussiaInfoButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: TextButton.icon(
        onPressed: onTap,
        icon: const Text(
          '\u{1F1F7}\u{1F1FA}',
          style: TextStyle(fontSize: 18),
        ),
        label: const Text(
          'Для пользователей РФ',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF555566),
          ),
        ),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFFE0E0E6)),
          ),
        ),
      ),
    );
  }
}

class _ApplePayBadge extends StatelessWidget {
  const _ApplePayBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.apple, color: Colors.white, size: 16),
          SizedBox(width: 3),
          Text(
            'Pay',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _GooglePlayBadge extends StatelessWidget {
  const _GooglePlayBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF4285F4),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.play_arrow, color: Colors.white, size: 16),
          SizedBox(width: 3),
          Text(
            'Play',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
