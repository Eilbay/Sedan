import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:optombai/bloc/button_visible_bloc/button_visible_bloc.dart';
import 'package:optombai/core/form_status.dart';
import 'package:optombai/pages/pmt/payment_availability.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:optombai/bloc/pit_bloc/pit_bloc.dart';
import 'package:optombai/bloc/pit_bloc/pit_event.dart';
import 'package:optombai/bloc/pit_bloc/pit_state.dart';
import 'package:optombai/bloc/user_bloc/user_bloc.dart';

import 'package:optombai/pages/pit/widgets/amount_selector.dart';
import 'package:optombai/pages/pit/widgets/pit_balance_card.dart';
import 'package:optombai/pages/pit/widgets/pit_method_selector.dart';
import 'package:optombai/services/iap_service.dart';
import 'package:optombai/services/pit_payment_service.dart';
import 'package:optombai/widgets/translation/text_translated.dart';
import 'package:optombai/core/theme_notifier.dart';
import 'package:auto_route/auto_route.dart';
import 'package:optombai/app/router/app_router.dart';

@RoutePage()
class PitScreen extends StatefulWidget {
  const PitScreen({super.key});

  @override
  State<PitScreen> createState() => _PitScreenState();
}

class _PitScreenState extends State<PitScreen> {
  late final Set<PitPaymentMethod> _availableMethods;
  final TextEditingController _customAmountController = TextEditingController();

  double _selectedAmount = 100;
  PitPaymentMethod _selectedMethod = PitPaymentMethod.finik;
  bool _processing = false;
  bool _useCustomAmount = false;

  static const List<double> _presetAmounts = [50, 100, 200, 500, 1000];
  // TEMPORARY (testing): lowered to 1 so top-ups from 1 som can be tested.
  // Revert before release.
  static const double _minAmount = 1;

  PitPaymentService? _paymentService;
  final IAPService _iapService = IAPService();
  final GlobalKey _managerInfoKey = GlobalKey();

  PitPaymentService get paymentService {
    _paymentService ??= PitPaymentService(context);
    return _paymentService!;
  }

  @override
  void initState() {
    super.initState();
    context.read<PitBloc>().add(const LoadPitEvent());
    _setupIAPCallbacks();

    final user = context.read<UserBloc>().state.user;
    final region = PaymentAvailability.regionOf(
      countryIso: user.country?.iso2,
      phoneE164: user.phone_number,
    );

    _availableMethods = PaymentAvailability.topUpMethods(region);

    if (!_availableMethods.contains(_selectedMethod) && _availableMethods.isNotEmpty) {
      _selectedMethod = _availableMethods.first;
    }
  }

  void _setupIAPCallbacks() {
    _iapService.onPurchaseSuccess = _onIAPPurchaseSuccess;
    _iapService.onPurchaseError = _onIAPPurchaseError;
    _iapService.onPurchasePending = _onIAPPurchasePending;
  }

  void _onIAPPurchaseSuccess(PurchaseDetails purchase) async {
    debugPrint('PitScreen: IAP purchase success: ${purchase.productID}');

    if (!IAPService.isPitProduct(purchase.productID)) {
      debugPrint('PitScreen: Not a wallet product, ignoring');
      // Still finish the transaction to clear the queue.
      await _iapService.finishPurchase(purchase);
      return;
    }

    // Finish the transaction with the store after receiving success.
    // The backend will independently validate the receipt via IAPPitEvent.
    await _iapService.finishPurchase(purchase);

    final platform = Platform.isIOS ? 'ios' : 'android';
    final receiptData = purchase.verificationData.serverVerificationData;

    if (!mounted) return;
    context.read<PitBloc>().add(IAPPitEvent(
          receiptData: receiptData,
          productId: purchase.productID,
          platform: platform,
          transactionId: purchase.purchaseID ?? '',
        ));
  }

  void _onIAPPurchaseError(String error) {
    debugPrint('PitScreen: IAP purchase error: $error');
    if (mounted) {
      setState(() => _processing = false);
      paymentService.showErrorMessage(error);
    }
  }

  void _onIAPPurchasePending() {
    debugPrint('PitScreen: IAP purchase pending');
  }

  @override
  void dispose() {
    _customAmountController.dispose();
    _iapService.onPurchaseSuccess = null;
    _iapService.onPurchaseError = null;
    _iapService.onPurchasePending = null;
    super.dispose();
  }

  double get _effectiveAmount {
    if (_useCustomAmount) {
      return double.tryParse(_customAmountController.text) ?? 0;
    }
    return _selectedAmount;
  }

  Future<void> _processPayment() async {
    if (_processing) return;

    final amount = _effectiveAmount;
    if (amount < _minAmount) {
      paymentService.showErrorMessage(
          'Минимальная сумма пополнения: ${_minAmount.toStringAsFixed(0)} сом');
      return;
    }

    if (_selectedMethod == PitPaymentMethod.manager) {
      _navigateToManagerContact(amount);
      return;
    }

    if (_selectedMethod == PitPaymentMethod.iap) {
      await _processIAPPayment(amount);
      return;
    }

    setState(() => _processing = true);

    final user = context.read<UserBloc>().state.user;
    final beforeBalance = context.read<PitBloc>().state.balance;

    final provider = _selectedMethod == PitPaymentMethod.finik ? 'finik' : 'freedompay';

    final paymentId = await paymentService.initPit(
      amount: amount,
      provider: provider,
    );

    if (paymentId == null && mounted) {
      paymentService.showErrorMessage('Не удалось инициализировать платеж');
      setState(() => _processing = false);
      return;
    }

    final orderId = paymentId ?? paymentService.generateOrderId();
    bool paymentSuccessful = false;

    final userName = user.username;
    final userPhone = user.phone_number;
    final userCountry = user.country?.name ?? user.userCountry?.name ?? '';
    final userEmail = user.email;

    if (_selectedMethod == PitPaymentMethod.finik) {
      paymentSuccessful = await paymentService.processFinikPayment(
        orderId: orderId,
        amount: amount,
        userName: userName,
        userPhone: userPhone,
        userCountry: userCountry,
        userEmail: userEmail,
      );
    } else {
      paymentSuccessful = await _processPayboxPayment(
        orderId,
        amount,
        user.id,
        userEmail,
        userPhone,
        userName,
        userCountry,
      );
    }

    if (paymentSuccessful && mounted) {
      final credited = await paymentService.confirmBalanceCredited(
        beforeBalance: beforeBalance,
        amount: amount,
      );

      if (mounted) {
        // Only claim success if the wallet balance actually grew. Otherwise the
        // charge went through but the server-side webhook hasn't credited yet.
        if (credited) {
          paymentService.showSuccessMessage(amount);
        } else {
          paymentService.showPendingMessage();
        }
        context.router.maybePop();
      }
    }

    if (mounted) setState(() => _processing = false);
  }

  Future<bool> _processPayboxPayment(
    String orderId,
    double amount,
    String userId,
    String userEmail,
    String userPhone,
    String userName,
    String userCountry,
  ) async {
    final result = await paymentService.processPayboxPayment(
      orderId: orderId,
      amount: amount,
      userId: userId,
      userEmail: userEmail,
      userPhone: userPhone,
      userName: userName,
      userCountry: userCountry,
    );

    if (result == null) {
      paymentService.showErrorMessage('Не удалось открыть окно оплаты');
      return false;
    }

    return result == true;
  }

  Future<void> _processIAPPayment(double amount) async {
    debugPrint('PitScreen: _processIAPPayment called with amount=$amount');
    debugPrint('PitScreen: IAP available=${_iapService.isAvailable}');
    debugPrint('PitScreen: All products=${_iapService.products.map((p) => p.id).toList()}');
    debugPrint('PitScreen: Wallet products=${_iapService.getPitProducts().map((p) => p.id).toList()}');

    if (!_iapService.isAvailable) {
      paymentService.showErrorMessage('In-App Purchase недоступен. Проверьте подключение к App Store.');
      return;
    }

    final walletProducts = _iapService.getPitProducts();
    if (walletProducts.isEmpty) {
      paymentService.showErrorMessage(
        'IAP продукты не загружены. Возможные причины:\n'
        '• Продукты ещё на проверке Apple\n'
        '• Нет подключения к App Store\n'
        '• Используйте TestFlight или dev-сборку',
      );
      return;
    }

    final product = _iapService.getPitProductByAmount(amount);
    if (product == null) {
      final availableAmounts =
          walletProducts.map((p) => IAPService.getPitAmount(p.id)?.toStringAsFixed(0) ?? p.id).join(', ');
      paymentService.showErrorMessage(
        'Продукт на сумму ${amount.toStringAsFixed(0)} не найден.\nДоступные: $availableAmounts',
      );
      return;
    }

    setState(() => _processing = true);

    debugPrint('PitScreen: Starting IAP purchase for ${product.id}');
    final success = await _iapService.buyConsumable(product);

    if (!success && mounted) {
      setState(() => _processing = false);
    }
  }

  void _navigateToManagerContact(double amount) {
    context.router.push(ManagerContactRoute(amount: amount));
  }

  Future<void> _scrollToManagerInfo() async {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ctx = _managerInfoKey.currentContext;
      if (ctx == null) return;
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
        alignment: 0.05,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.select((ThemeNotifier n) => n.isDarkMode);
    final adWalletState = context.select((PitBloc b) => b.state);
    final bvState = context.watch<ButtonVisibleBloc>().state;
    final isHiddenMode = bvState.status == FormStatus.submissionSuccess &&
        !bvState.isVisible;

    return _PitBlocListener(
      onIAPSuccess: (addedAmount) {
        setState(() => _processing = false);
        paymentService.showSuccessMessage(addedAmount);
        context.read<PitBloc>().add(const LoadPitEvent());
        context.read<PitBloc>().add(const ResetPitStateEvent());
        context.router.maybePop();
      },
      onError: (error) {
        setState(() => _processing = false);
        paymentService.showErrorMessage(error);
        context.read<PitBloc>().add(const ResetPitStateEvent());
      },
      child: _PitScaffold(
        balance: adWalletState.balance,
        presetAmounts: _presetAmounts,
        minAmount: _minAmount,
        selectedAmount: _selectedAmount,
        useCustomAmount: _useCustomAmount,
        customAmountController: _customAmountController,
        hideMethodSelector: false,
        isHiddenMode: isHiddenMode,
        onPresetSelected: (amount) {
          setState(() {
            _selectedAmount = amount;
            _useCustomAmount = false;
          });
        },
        onCustomToggled: (useCustom) {
          setState(() => _useCustomAmount = useCustom);
        },
        selectedMethod: _selectedMethod,
        availableMethods: _availableMethods,
        onMethodSelected: (m) async {
          if (m == PitPaymentMethod.manager) {
            setState(() => _selectedMethod = m);
            await _scrollToManagerInfo();
            return;
          }

          // TEMPORARY (testing): don't surface the "функционал недоступен"
          // prompt when an unavailable method is tapped — just ignore the tap
          // silently so nothing is shown to the user. Revert before release.
          if (!_availableMethods.contains(m)) return;
          setState(() => _selectedMethod = m);
        },
        isDarkMode: isDarkMode,
        isManager: _selectedMethod == PitPaymentMethod.manager,
        isProcessing: _processing,
        onTopUpPressed: _processPayment,
        managerInfoKey: _managerInfoKey,
      ),
    );
  }
}

class _PitBlocListener extends StatelessWidget {
  const _PitBlocListener({
    required this.onIAPSuccess,
    required this.onError,
    required this.child,
  });

  final void Function(double addedAmount) onIAPSuccess;
  final void Function(String error) onError;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocListener<PitBloc, PitState>(
      listenWhen: (previous, current) =>
          previous.isIAPSuccess != current.isIAPSuccess || previous.errors != current.errors,
      listener: (context, state) {
        if (state.isIAPSuccess && state.iapPitResponse != null) {
          final addedAmount = state.iapPitResponse!.addedAmount ?? 0;
          onIAPSuccess(addedAmount);
        } else if (state.errors.isNotEmpty && !state.isProcessing) {
          onError(state.errors.first);
        }
      },
      child: child,
    );
  }
}

class _PitScaffold extends StatelessWidget {
  const _PitScaffold({
    required this.balance,
    required this.presetAmounts,
    required this.minAmount,
    required this.selectedAmount,
    required this.useCustomAmount,
    required this.customAmountController,
    required this.onPresetSelected,
    required this.onCustomToggled,
    required this.selectedMethod,
    required this.availableMethods,
    required this.onMethodSelected,
    required this.isDarkMode,
    required this.isManager,
    required this.isProcessing,
    required this.onTopUpPressed,
    required this.hideMethodSelector,
    required this.managerInfoKey,
    required this.isHiddenMode,
  });

  final double balance;
  final List<double> presetAmounts;
  final double minAmount;
  final double selectedAmount;
  final bool useCustomAmount;
  final TextEditingController customAmountController;
  final ValueChanged<double> onPresetSelected;
  final ValueChanged<bool> onCustomToggled;

  final PitPaymentMethod selectedMethod;
  final Set<PitPaymentMethod> availableMethods;
  final ValueChanged<PitPaymentMethod> onMethodSelected;

  final bool isDarkMode;
  final bool isManager;
  final bool isProcessing;
  final VoidCallback onTopUpPressed;

  final bool hideMethodSelector;
  final GlobalKey managerInfoKey;
  final bool isHiddenMode;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const TextTranslated('Пополнить баланс'),
        centerTitle: true,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          final bloc = context.read<PitBloc>();
          bloc.add(const LoadPitEvent());
          await bloc.stream
              .firstWhere((s) => !s.isLoading)
              .timeout(
                const Duration(seconds: 4),
                onTimeout: () => bloc.state,
              );
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BalanceCard(balance: balance),
              SizedBox(height: 18.h),
              AmountSelector(
                presetAmounts: presetAmounts,
                minAmount: minAmount,
                selectedAmount: selectedAmount,
                useCustomAmount: useCustomAmount,
                customAmountController: customAmountController,
                onPresetSelected: onPresetSelected,
                onCustomToggled: onCustomToggled,
              ),
              SizedBox(height: 18.h),
              if (!hideMethodSelector) ...[
                SizedBox(height: 18.h),
                PitMethodSelector(
                  selectedMethod: selectedMethod,
                  isDarkMode: isDarkMode,
                  available: availableMethods,
                  onMethodSelected: onMethodSelected,
                  isHiddenMode: isHiddenMode,
                ),
              ],
              if (!isManager) ...[
                SizedBox(height: 14.h),
                _RefundDisclaimer(isDarkMode: isDarkMode),
              ],
              SizedBox(height: 20.h),
              _PitButton(
                useCustomAmount: useCustomAmount,
                selectedAmount: selectedAmount,
                customAmountController: customAmountController,
                isManager: isManager,
                isProcessing: isProcessing,
                onPressed: onTopUpPressed,
              ),
              if (!isHiddenMode) ...[
                SizedBox(height: 18.h),
                _RussiaInfoBanner(
                  key: managerInfoKey,
                  isDark: isDarkMode,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _RefundDisclaimer extends StatelessWidget {
  const _RefundDisclaimer({required this.isDarkMode});

  final bool isDarkMode;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            size: 16,
            color: isDarkMode ? Colors.white70 : Colors.black54,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: TextTranslated(
              'Средства не подлежат возврату. Используются только для оплаты рекламных кампаний внутри Китайдан.',
              style: TextStyle(
                fontSize: 12,
                color: isDarkMode ? Colors.white70 : Colors.black54,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PitButton extends StatelessWidget {
  const _PitButton({
    required this.useCustomAmount,
    required this.selectedAmount,
    required this.customAmountController,
    required this.isManager,
    required this.isProcessing,
    required this.onPressed,
  });

  final bool useCustomAmount;
  final double selectedAmount;
  final TextEditingController customAmountController;
  final bool isManager;
  final bool isProcessing;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    if (isManager) return const SizedBox.shrink();

    return SizedBox(
      width: double.infinity,
      height: 48.h,
      // Rebuild the label live as the user types a custom amount — the
      // controller is a ValueListenable, so no parent setState is needed.
      child: ListenableBuilder(
        listenable: customAmountController,
        builder: (context, _) {
          final amount = useCustomAmount
              ? (double.tryParse(customAmountController.text) ?? 0)
              : selectedAmount;

          return ElevatedButton(
            onPressed: isProcessing ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff0095D5),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 2,
            ),
            child: isProcessing
                ? const _ButtonLoadingIndicator()
                : Text(
                    'Пополнить на ${amount.toStringAsFixed(0)} сом',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          );
        },
      ),
    );
  }
}

class _ButtonLoadingIndicator extends StatelessWidget {
  const _ButtonLoadingIndicator();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 22,
      height: 22,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
      ),
    );
  }
}

class _RussiaInfoBanner extends StatelessWidget {
  const _RussiaInfoBanner({super.key, required this.isDark});

  final bool isDark;

  static const String _phoneNumber = '+7 967 129 40 68';
  static const String _cardNumber = '2202 2084 1166 0096';
  static const String _recipient = 'Артур Азаматович А.';
  static const String _whatsappUrl = 'https://wa.me/996551947777';
  static const String _telegramUrl = 'https://t.me/eldiiar';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xff1C1C1E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _RussiaInfoHeader(),
          SizedBox(height: 12.h),
          const _RussiaInfoDescription(),
          SizedBox(height: 16.h),
          const _RussiaInfoSectionTitle(
            icon: '\u{1F4B0}',
            title: 'Пополнение',
            color: Color(0xffFFD700),
          ),
          SizedBox(height: 4.h),
          const _RussiaInfoBody(
            text: '• Сумма произвольная\n'
                '• Вы переводите любую удобную сумму, необходимую для рекламы',
          ),
          SizedBox(height: 16.h),
          const _RussiaInfoSectionTitle(
            icon: '\u{1F4F1}',
            title: 'Оплата по номеру (Сбербанк)',
            color: Color(0xffFFD700),
          ),
          SizedBox(height: 8.h),
          const _CopyableField(value: _phoneNumber, icon: '\u{1F4DE}'),
          SizedBox(height: 4.h),
          const _RecipientLabel(name: _recipient),
          SizedBox(height: 16.h),
          const _RussiaInfoSectionTitle(
            icon: '\u{1F4B3}',
            title: 'Перевод по карте',
            color: Color(0xffFFD700),
          ),
          SizedBox(height: 8.h),
          const _CopyableField(value: _cardNumber, icon: '\u{1F4B3}'),
          SizedBox(height: 4.h),
          const _RecipientLabel(name: _recipient),
          SizedBox(height: 16.h),
          const _RussiaInfoSectionTitle(
            icon: '\u{2705}',
            title: 'После оплаты отправьте:',
            color: Color(0xff4CAF50),
          ),
          SizedBox(height: 4.h),
          const _RussiaInfoBody(
            text: '• Чек / скрин оплаты\n• Ваш логин или номер телефона',
          ),
          SizedBox(height: 16.h),
          const _ContactButtonsRow(
            whatsappUrl: _whatsappUrl,
            telegramUrl: _telegramUrl,
          ),
        ],
      ),
    );
  }
}

class _RussiaInfoHeader extends StatelessWidget {
  const _RussiaInfoHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Пополнение рекламного кошелька для граждан России',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
        SizedBox(width: 8.w),
        const Text('\u{1F1F7}\u{1F1FA}', style: TextStyle(fontSize: 20)),
      ],
    );
  }
}

class _RussiaInfoDescription extends StatelessWidget {
  const _RussiaInfoDescription();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'В связи с санкциями автоматические платежи из России временно недоступны.\n'
      'Для пополнения рекламного кошелька используйте безопасный способ перевода через Сбербанк.',
      style: TextStyle(fontSize: 13, color: Colors.white70),
    );
  }
}

class _RussiaInfoSectionTitle extends StatelessWidget {
  const _RussiaInfoSectionTitle({
    required this.icon,
    required this.title,
    required this.color,
  });

  final String icon;
  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      '$icon $title',
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: color,
      ),
    );
  }
}

class _RussiaInfoBody extends StatelessWidget {
  const _RussiaInfoBody({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 13, color: Colors.white70),
    );
  }
}

class _RecipientLabel extends StatelessWidget {
  const _RecipientLabel({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Text(
      'Получатель: $name',
      style: const TextStyle(fontSize: 13, color: Colors.white70),
    );
  }
}

class _ContactButtonsRow extends StatelessWidget {
  const _ContactButtonsRow({
    required this.whatsappUrl,
    required this.telegramUrl,
  });

  final String whatsappUrl;
  final String telegramUrl;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ContactButton(
            label: 'WhatsApp',
            color: const Color(0xff25D366),
            icon: Icons.chat,
            url: whatsappUrl,
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: _ContactButton(
            label: 'Telegram',
            color: const Color(0xff0088CC),
            icon: Icons.send,
            url: telegramUrl,
          ),
        ),
      ],
    );
  }
}

class _CopyableField extends StatelessWidget {
  const _CopyableField({required this.value, required this.icon});

  final String value;
  final String icon;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Clipboard.setData(ClipboardData(text: value.replaceAll(' ', '')));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Скопировано'),
            duration: Duration(seconds: 1),
          ),
        );
      },
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 14)),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Icon(Icons.copy, size: 18, color: Colors.white38),
        ],
      ),
    );
  }
}

class _ContactButton extends StatelessWidget {
  const _ContactButton({
    required this.label,
    required this.color,
    required this.icon,
    required this.url,
  });

  final String label;
  final Color color;
  final IconData icon;
  final String url;

  Future<void> _launch() async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: _launch,
      icon: Icon(icon, size: 18),
      label: Text(
        label,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
