import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:optombai/bloc/auth_bloc/auth_cubit.dart';
import 'package:optombai/bloc/button_visible_bloc/button_visible_bloc.dart';
import 'package:optombai/bloc/pmt_bloc/pmt_bloc.dart';
import 'package:optombai/bloc/pmt_bloc/pmt_event.dart';
import 'package:optombai/bloc/user_bloc/user_bloc.dart';
import 'package:optombai/app/router/app_router.dart';
import 'package:optombai/core/form_status.dart';
import 'package:optombai/pages/pmt/payment_region_resolver.dart';
import 'package:optombai/pages/pmt/pmt_option_tile.dart';
import 'package:optombai/paybox/paybox_client.dart';
import 'package:optombai/services/iap_service.dart';
import 'package:optombai/widgets/drawer/drawer_screens/subscription_card.dart';
import 'package:optombai/widgets/drawer/pmt_info_screen.dart';
import 'package:optombai/widgets/drawer/premium_tariff.dart';
import 'package:auto_route/auto_route.dart';

@RoutePage()
class PmtScreen extends StatefulWidget {
  final String orderId;
  final String userId;
  final String userEmail;
  final String userPhone;
  final String description;
  final BusinessTariff tariff;

  final bool skipChooser;

  final double amount;
  final String currencyCode;

  final String premiumId;
  final PaymentMethod? initialMethod;
  final bool autoStart;

  const PmtScreen({
    super.key,
    required this.orderId,
    required this.userId,
    required this.userEmail,
    required this.userPhone,
    required this.tariff,
    required this.amount,
    required this.currencyCode,
    required this.description,
    required this.premiumId,
    this.autoStart = false,
    this.initialMethod,
    this.skipChooser = false,
  });

  @override
  State<PmtScreen> createState() => _PmtScreenState();
}

enum PaymentMethod { iap, finik, freedom, sber }

class AutoPayConfig {
  final String currencyCode;
  final PaymentMethod method;
  const AutoPayConfig(this.currencyCode, this.method);
}

const autoPayMap = <UserRegion, AutoPayConfig>{
  UserRegion.kg: AutoPayConfig('KGS', PaymentMethod.finik),
  UserRegion.ru: AutoPayConfig('RUB', PaymentMethod.sber),
  UserRegion.uz: AutoPayConfig('UZS', PaymentMethod.freedom),
  UserRegion.kz: AutoPayConfig('KZT', PaymentMethod.freedom),
  UserRegion.cn: AutoPayConfig('CNY', PaymentMethod.freedom),
  UserRegion.other: AutoPayConfig('USD', PaymentMethod.freedom),
};

enum PmtResult { scrollToRussia, none }

class _PmtScreenState extends State<PmtScreen> {
  final PayboxClient payboxClient = PayboxClient();
  final IAPService _iapService = IAPService();
  bool _completed = false;
  bool _processing = false;
  late PaymentMethod _selected;

  bool get _showIAP => _iapService.isAvailable;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialMethod ?? PaymentMethod.finik;
  }

  Future<void> _onConfirmPressed() async {
    if (_processing || _completed) return;
    setState(() => _processing = true);

    if (_selected == PaymentMethod.iap) {
      await _processIAP();
      return;
    } else if (_selected == PaymentMethod.finik) {
      await _openFinik();
    } else if (_selected == PaymentMethod.sber) {
      await _openSber();
    } else {
      await _openPaybox();
    }

    if (mounted) setState(() => _processing = false);
  }

  void _selectMethod(PaymentMethod method) {
    setState(() => _selected = method);
  }

  @override
  Widget build(BuildContext context) {
    final bvState = context.watch<ButtonVisibleBloc>().state;
    final isHiddenMode = bvState.status == FormStatus.submissionSuccess &&
        !bvState.isVisible;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Stack(
          children: [
            _DismissBackground(
              onTap: _processing ? null : () => context.router.maybePop(),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: _PaymentSheet(
                    showIAP: _showIAP,
                    isHiddenMode: isHiddenMode,
                    selected: _selected,
                    processing: _processing,
                    onSelectMethod: _selectMethod,
                    onConfirm: _processing ? null : _onConfirmPressed,
                    onClose:
                        _processing ? null : () => context.router.maybePop(),
                    onRussiaTap: () => _openSber(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openFinik() async {
    if (!mounted || _completed) return;

    if (widget.currencyCode != 'KGS') {
      return _failAndExitOnce(
          'Finik доступен только для оплаты в сомах (KGS).');
    }

    final userName = context.read<UserBloc>().state.user.username;

    final result = await context.router.push<bool>(
      FinikPaymentRoute(
        orderId: widget.orderId,
        amount: widget.amount,
        description: widget.description,
        phone: widget.userPhone,
        userName: userName,
        email: widget.userEmail,
        onPaymentConfirmed: () async {
          await _handlePmtSuccessSafe(pmtMethod: 'mbank');
        },
        onCancel: () {},
      ),
    );

    if (!mounted) return;

    if (result == false) {
      setState(() => _processing = false);
    }
  }

  Future<void> _openSber() async {
    if (!mounted || _completed) return;

    await context.router.push(PmtInfoRoute(
      initialSection: PmtInfoInitialSection.russia,
      premiumId: widget.premiumId,
      initialTariff: widget.tariff == BusinessTariff.monthly
          ? PremiumTariff.monthly
          : PremiumTariff.weekly,
    ));

    if (mounted) setState(() => _processing = false);
  }

  Future<void> _openPaybox() async {
    if (_completed || !mounted) return;

    String? redirectUrl;
    try {
      final pmt = await payboxClient.createPayment(
        orderId: widget.orderId,
        userId: widget.userId,
        userEmail: widget.userEmail,
        userPhone: widget.userPhone,
        amount: widget.amount,
        currencyCode: widget.currencyCode,
        description: widget.description,
      );
      redirectUrl = pmt?.redirectUrl;
    } catch (e, st) {
      debugPrint('createPayment error: $e\n$st');
      return _failAndExitOnce('Не удалось инициализировать оплату. (CP)');
    }

    if (redirectUrl == null || redirectUrl.isEmpty) {
      return _failAndExitOnce('Не удалось получить ссылку для оплаты. (URL)');
    }

    bool? success;
    try {
      if (!mounted) return;
      success = await context.router.push<bool>(WebViewRoute(
        url: redirectUrl,
        onPmtSuccess: () {},
      ));
    } catch (e, st) {
      debugPrint('Navigator/WebView error: $e\n$st');
      return _failAndExitOnce('Не удалось открыть окно оплаты. (WV)');
    }

    if (success == true) {
      await _handlePmtSuccessSafe(pmtMethod: 'card_bank');
    } else if (success == false) {
      _failAndExitOnce('Оплата отменена.');
    } else {
      _failAndExitOnce('Окно оплаты закрыто.');
    }
  }

  Future<void> _handlePmtSuccessSafe({required String pmtMethod}) async {
    if (_completed) return;

    final pmtBloc = context.read<PmtBloc>();

    try {
      pmtBloc.add(PmtStatusUpdateEvent(
        pmtId: widget.orderId,
        amount: widget.amount.toStringAsFixed(2),
        pmtMethod: pmtMethod,
        premiumId: widget.premiumId,
      ));

      await pmtBloc.stream.firstWhere((s) => s.isSuccess == true);

      if (!mounted) return;

      await context
          .read<AuthCubit>()
          .updatePremiumStatus(widget.orderId, widget.premiumId, context);

      if (!mounted) return;

      _completed = true;

      BlocProvider.of<UserBloc>(context).add(UserOwnerEvent());

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Тариф «Бизнес» активирован! Переход на главную через 3 сек'),
          duration: Duration(seconds: 4),
        ),
      );

      Future.delayed(const Duration(seconds: 3), () {
        if (!mounted) return;

        context.router.replaceAll([BottomNavRoute(currentIndexOverride: 0)]);
      });
    } catch (e, st) {
      debugPrint('handlePmtSuccess error: $e\n$st');
      _failAndExitOnce(
          'Оплата проведена, но возникла ошибка подтверждения. (HS)');
    }
  }

  void _failAndExitOnce(String message) {
    if (_completed || !mounted) return;
    _completed = true;
    debugPrint('PmtScreen: _failAndExitOnce called with: $message');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        duration: const Duration(milliseconds: 500),
      ),
    );
    context.router.maybePop();
  }

  Future<void> _processIAP() async {
    if (_completed || !mounted) return;

    final product = widget.tariff == BusinessTariff.weekly
        ? _iapService.getWeeklyProduct()
        : _iapService.getMonthlyProduct();

    if (product == null) {
      final storeName = Platform.isIOS ? 'App Store' : 'Google Play';
      setState(() => _processing = false);
      _failAndExitOnce('Продукт недоступен в $storeName');
      return;
    }

    _iapService.onPurchaseSuccess = (purchase) async {
      if (!mounted || _completed) return;

      final token = context.read<PmtBloc>().getToken();

      final validation = await _iapService.validatePurchase(
        purchase: purchase,
        token: token,
      );

      // Always finish the transaction to clear it from the queue.
      await _iapService.finishPurchase(purchase);

      if (!validation.isValid) {
        _failAndExitOnce(validation.error ?? 'Ошибка валидации покупки');
        return;
      }

      final pmtMethod = Platform.isIOS ? 'apple_pay' : 'google_pay';
      await _handlePmtSuccessSafe(pmtMethod: pmtMethod);
    };

    _iapService.onPurchaseError = (error) {
      if (!mounted) return;
      setState(() => _processing = false);
      _failAndExitOnce(error);
    };

    _iapService.onPurchasePending = () {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Обработка платежа...')),
      );
    };

    final success = await _iapService.buyProduct(product);
    if (!success && mounted) {
      setState(() => _processing = false);
    }
  }
}

// ---------------------------------------------------------------------------
// Extracted widgets
// ---------------------------------------------------------------------------

class _DismissBackground extends StatelessWidget {
  final VoidCallback? onTap;

  const _DismissBackground({this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: Colors.black.withValues(alpha: 0.35),
      ),
    );
  }
}

class _PaymentSheet extends StatelessWidget {
  final bool showIAP;
  final bool isHiddenMode;
  final PaymentMethod selected;
  final bool processing;
  final ValueChanged<PaymentMethod> onSelectMethod;
  final VoidCallback? onConfirm;
  final VoidCallback? onClose;
  final VoidCallback onRussiaTap;

  const _PaymentSheet({
    required this.showIAP,
    required this.isHiddenMode,
    required this.selected,
    required this.processing,
    required this.onSelectMethod,
    required this.onRussiaTap,
    this.onConfirm,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(24),
      color: Colors.white,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SheetHeader(onClose: onClose),
            const SizedBox(height: 20),
            if (!isHiddenMode) ...[
              _FinikOptionTile(
                selected: selected == PaymentMethod.finik,
                onTap: () => onSelectMethod(PaymentMethod.finik),
              ),
              const SizedBox(height: 12),
              _FreedomOptionTile(
                selected: selected == PaymentMethod.freedom,
                onTap: () => onSelectMethod(PaymentMethod.freedom),
              ),
              const SizedBox(height: 12),
            ],
            if (showIAP) ...[
              _IapOptionTile(
                selected: selected == PaymentMethod.iap,
                onTap: () => onSelectMethod(PaymentMethod.iap),
              ),
              const SizedBox(height: 12),
            ],
            const SizedBox(height: 8),
            _ConfirmPayButton(
              processing: processing,
              onPressed: onConfirm,
            ),
            if (!isHiddenMode) ...[
              const SizedBox(height: 12),
              _RussiaInfoButton(onTap: onRussiaTap),
            ],
          ],
        ),
      ),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  final VoidCallback? onClose;

  const _SheetHeader({this.onClose});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
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
              onPressed: onClose,
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
      ],
    );
  }
}

class _IapOptionTile extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;

  const _IapOptionTile({
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PmtOptionTile(
      title: Platform.isIOS ? 'Apple Pay' : 'Google Play',
      subtitle: Platform.isIOS
          ? 'Быстрая оплата через Apple'
          : 'Быстрая оплата через Google',
      icons: const [],
      selected: selected,
      onTap: onTap,
      leadingIcon: Platform.isIOS
          ? const _ApplePayBadge()
          : const _GooglePlayBadge(),
    );
  }
}

class _FinikOptionTile extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;

  const _FinikOptionTile({
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PmtOptionTile(
      title: 'QR или моб. приложение для\nКыргызстана 🇰🇬',
      subtitle: 'MBank, Optima, Мой О! и другие',
      icons: const [
        'assets/cards/mbank.png',
        'assets/cards/optimabank.png',
        'assets/cards/obank.png',
        'assets/cards/aiylbanklogo.png',
      ],
      selected: selected,
      onTap: onTap,
    );
  }
}

class _FreedomOptionTile extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;

  const _FreedomOptionTile({
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PmtOptionTile(
      title: 'Банковская карта для всех\nстран 🌎',
      subtitle: 'Visa, Mastercard, Элкарт и другие',
      icons: const [
        'assets/cards/visa.png',
        'assets/cards/maestro.png',
        'assets/cards/mastercard2.png',
        'assets/cards/elcart.png',
      ],
      selected: selected,
      onTap: onTap,
    );
  }
}

class _ConfirmPayButton extends StatelessWidget {
  final bool processing;
  final VoidCallback? onPressed;

  const _ConfirmPayButton({
    required this.processing,
    this.onPressed,
  });

  static const _gradient = LinearGradient(
    colors: [
      Color.fromARGB(255, 80, 104, 129),
      Color.fromRGBO(0, 4, 8, 1),
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const _shadow = [
    BoxShadow(
      color: Color(0x33007AFF),
      blurRadius: 8,
      offset: Offset(0, 3),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: _gradient,
          boxShadow: _shadow,
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
          onPressed: onPressed,
          child: processing ? const _ButtonSpinner() : const _ButtonLabel(),
        ),
      ),
    );
  }
}

class _ButtonSpinner extends StatelessWidget {
  const _ButtonSpinner();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 20,
      height: 20,
      child: CircularProgressIndicator(
        strokeWidth: 2.4,
        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
      ),
    );
  }
}

class _ButtonLabel extends StatelessWidget {
  const _ButtonLabel();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'Оплатить',
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.white,
        letterSpacing: 0.3,
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
