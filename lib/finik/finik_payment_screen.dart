import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:finik_sdk/finik_sdk.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:optombai/core/appColors.dart';
import 'package:optombai/data/domain_set.dart';

@RoutePage()
class FinikPaymentScreen extends StatefulWidget {
  final String orderId;
  final double amount;
  final String description;

  final String? phone;
  final String? userName;
  final String? email;
  final String? callbackUrl;

  final VoidCallback? onCancel;
  final Future<bool> Function()? checkPaymentStatus;
  final Future<void> Function()? onPaymentConfirmed;

  static String get defaultCallbackUrl => ApiEndpoints.finikWebhook;

  const FinikPaymentScreen({
    super.key,
    required this.orderId,
    required this.amount,
    required this.description,
    this.phone,
    this.userName,
    this.email,
    this.callbackUrl,
    this.onCancel,
    this.checkPaymentStatus,
    this.onPaymentConfirmed,
  });

  @override
  State<FinikPaymentScreen> createState() => _FinikPaymentScreenState();
}

class _FinikPaymentScreenState extends State<FinikPaymentScreen>
    with WidgetsBindingObserver {
  bool _completed = false;
  bool _returnedFromBank = false;
  bool _wentToBackground = false;
  bool _checkingStatus = false;
  bool _canRetryStatusCheck = false;
  String _statusMessage = 'Проверяем статус платежа';

  Timer? _retryEnableTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _retryEnableTimer?.cancel();
    super.dispose();
  }

  List<RequiredField> _buildRequiredFields() {
    return [
      if (widget.userName?.isNotEmpty ?? false)
        RequiredField(
          fieldId: 'name',
          label: 'Имя',
          isHidden: true,
          value: widget.userName!,
        ),
      if (widget.phone?.isNotEmpty ?? false)
        RequiredField(
          fieldId: 'phone',
          label: 'Телефон',
          isHidden: true,
          value: widget.phone!,
        ),
      if (widget.email?.isNotEmpty ?? false)
        RequiredField(
          fieldId: 'email',
          label: 'Email',
          isHidden: true,
          value: widget.email!,
        ),
    ];
  }

  void _closeWithCancel() {
    if (!mounted || _completed) return;
    _retryEnableTimer?.cancel();
    // Imperative pop bypasses PopScope(canPop: false); maybePop would be
    // blocked by it and the screen would never close (dead back button).
    context.router.pop(false);
    widget.onCancel?.call();
  }

  bool _isSuccessStatus(String status) {
    final s = status.trim().toLowerCase();
    return s == 'success' || s == 'succeeded' || s == 'succeed' || s == 'paid';
  }

  Future<void> _finishSuccess() async {
    if (_completed || !mounted) return;

    _completed = true;
    _retryEnableTimer?.cancel();

    try {
      await widget.onPaymentConfirmed?.call();
    } catch (_) {
      if (!mounted) return;

      _completed = false;
      setState(() {
        _returnedFromBank = true;
        _checkingStatus = false;
        _canRetryStatusCheck = true;
        _statusMessage =
            'Оплата найдена, но завершить операцию не удалось. Повторите проверку.';
      });
      return;
    }

    if (!mounted) return;
    // Imperative pop bypasses PopScope(canPop: false) so the screen actually
    // closes on success and the caller resumes (refreshes wallet balance).
    context.router.pop(true);
  }

  void _onReturnedFromBank() {
    if (_completed || !mounted) return;

    debugPrint(
        '[TOPUP-DEBUG] returned from bank, starting status check orderId=${widget.orderId}');

    _retryEnableTimer?.cancel();

    setState(() {
      _returnedFromBank = true;
      _checkingStatus = false;
      _canRetryStatusCheck = false;
      _statusMessage = 'Проверяем статус платежа';
    });

    _startAutoStatusCheck();
  }

  Future<void> _startAutoStatusCheck() async {
    if (_completed || !mounted) return;

    final checkPaymentStatus = widget.checkPaymentStatus;
    if (checkPaymentStatus == null) {
      setState(() {
        _checkingStatus = false;
        _canRetryStatusCheck = true;
        _statusMessage = 'Не удалось проверить статус платежа';
      });
      return;
    }

    setState(() {
      _checkingStatus = true;
      _canRetryStatusCheck = false;
      _statusMessage = 'Проверяем статус платежа';
    });

    try {
      final paid = await checkPaymentStatus();
      debugPrint('[TOPUP-DEBUG] checkPaymentStatus returned paid=$paid');

      if (!mounted) return;

      if (paid) {
        await _finishSuccess();
        return;
      }

      setState(() {
        _checkingStatus = false;
        _statusMessage = 'Подтверждение оплаты пока не получено';
      });

      _enableRetryLater();
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _checkingStatus = false;
        _statusMessage = 'Ошибка при проверке статуса платежа';
      });

      _enableRetryLater();
    }
  }

  void _enableRetryLater() {
    _retryEnableTimer?.cancel();

    setState(() {
      _canRetryStatusCheck = false;
    });

    _retryEnableTimer = Timer(const Duration(seconds: 4), () {
      if (!mounted || _completed) return;
      setState(() {
        _canRetryStatusCheck = true;
      });
    });
  }

  Future<void> _onRetryStatusTap() async {
    if (_checkingStatus || !_canRetryStatusCheck || _completed) return;
    await _startAutoStatusCheck();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_completed) return;

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused) {
      _wentToBackground = true;
    }

    if (state == AppLifecycleState.resumed && _wentToBackground) {
      _wentToBackground = false;
      _onReturnedFromBank();
    }
  }

  Widget _buildFinikScreen() {
    final apiKey = (dotenv.env['FINIK_API_KEY'] ?? '').trim();
    final accountId = (dotenv.env['FINIK_ACCOUNT_ID'] ?? '').trim();

    if (apiKey.isEmpty || accountId.isEmpty) {
      return const Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Не настроены FINIK_API_KEY или FINIK_ACCOUNT_ID',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          FinikProvider(
            apiKey: apiKey,
            isBeta: false,
            locale: FinikSdkLocale.RU,
            textScenario: TextScenario.PAYMENT,
            paymentMethods: const [
              PaymentMethod.APP,
              PaymentMethod.QR,
            ],
            enableShimmer: true,
            enableShare: true,
            enableSupportButtons: true,
            tapableSupportButtons: true,
            onBackPressed: _closeWithCancel,
            onPayment: (data) async {
              final status = (data?['status'] ?? '').toString().toLowerCase();
              debugPrint(
                  '[TOPUP-DEBUG] Finik onPayment orderId=${widget.orderId} raw=$data status=$status isSuccess=${_isSuccessStatus(status)} completed=$_completed');

              if (_completed || !mounted) return;

              if (_isSuccessStatus(status)) {
                await _finishSuccess();
              }
            },
            widget: CreateItemHandlerWidget(
              accountId: accountId,
              requestId: widget.orderId,
              nameEn: widget.description.isNotEmpty
                  ? widget.description
                  : 'Payment ${widget.orderId}',
              amount: FixedAmount(widget.amount),
              description: widget.description,
              maxAvailableQuantity: 1,
              callbackUrl:
                  widget.callbackUrl ?? FinikPaymentScreen.defaultCallbackUrl,
              requiredFields: _buildRequiredFields(),
            ),
          ),
          _buildStatusOverlay(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          _closeWithCancel();
        },
        child: _buildFinikScreen(),
      ),
    );
  }

  Widget _buildPrimaryButton({
    required String text,
    required VoidCallback? onTap,
    bool loading = false,
  }) {
    final bool enabled = onTap != null && !loading;

    return SizedBox(
      width: double.infinity,
      height: 52.h,
      child: ElevatedButton(
        onPressed: enabled ? onTap : null,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor:
              enabled ? const Color(0xff1967FF) : const Color(0xffCFDEFB),
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xffCFDEFB),
          disabledForegroundColor: Colors.white70,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          padding: EdgeInsets.symmetric(horizontal: 16.w),
        ),
        child: loading
            ? SizedBox(
                width: 20.w,
                height: 20.w,
                child: const CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                text,
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                  height: 1.1,
                ),
              ),
      ),
    );
  }

  Widget _buildSecondaryButton({
    required String text,
    required VoidCallback? onTap,
  }) {
    final bool enabled = onTap != null;

    return SizedBox(
      width: double.infinity,
      height: 52.h,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          elevation: 0,
          backgroundColor: enabled ? Colors.white : const Color(0xffF5F7FB),
          foregroundColor:
              enabled ? const Color(0xff1967FF) : const Color(0xff9FB6E9),
          side: BorderSide(
            color: enabled ? const Color(0xffCFDEFB) : const Color(0xffE6ECF8),
            width: 1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          padding: EdgeInsets.symmetric(horizontal: 16.w),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 15.sp,
            fontWeight: FontWeight.w600,
            height: 1.1,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusOverlay() {
    if (!_returnedFromBank) return const SizedBox.shrink();

    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.35),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: double.infinity,
                  constraints: BoxConstraints(maxWidth: 380.w),
                  padding: EdgeInsets.all(20.w),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(24.r),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x14000000),
                        blurRadius: 22,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 56.w,
                        height: 56.w,
                        decoration: BoxDecoration(
                          color: const Color(0xffEEF4FF),
                          borderRadius: BorderRadius.circular(18.r),
                        ),
                        alignment: Alignment.center,
                        child: _checkingStatus
                            ? SizedBox(
                                width: 24.w,
                                height: 24.w,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Color(0xff1967FF),
                                  ),
                                ),
                              )
                            : Icon(
                                Icons.receipt_long_rounded,
                                color: const Color(0xff1967FF),
                                size: 26.sp,
                              ),
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        'Статус платежа',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.black,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        _statusMessage,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xff6B7280),
                          height: 1.35,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'Доступ откроется только после подтверждения оплаты системой.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xff9AA3B2),
                          height: 1.35,
                        ),
                      ),
                      SizedBox(height: 20.h),
                      _buildPrimaryButton(
                        text: _canRetryStatusCheck
                            ? 'Проверить статус'
                            : 'Подождите...',
                        onTap: _canRetryStatusCheck && !_checkingStatus
                            ? _onRetryStatusTap
                            : null,
                        loading: _checkingStatus,
                      ),
                      SizedBox(height: 10.h),
                      _buildSecondaryButton(
                        text: 'Назад к оплате',
                        onTap: _checkingStatus
                            ? null
                            : () {
                                setState(() {
                                  _returnedFromBank = false;
                                  _canRetryStatusCheck = false;
                                  _statusMessage = 'Проверяем статус платежа';
                                });
                              },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
