import 'package:flutter/material.dart';
import 'package:optombai/data/domain_set.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:auto_route/auto_route.dart';
import 'package:optombai/app/router/app_router.dart';
import 'package:optombai/bloc/pit_bloc/pit_bloc.dart';
import 'package:optombai/bloc/pit_bloc/pit_event.dart';
import 'package:optombai/paybox/paybox_client.dart';

class PitPaymentService {
  final BuildContext context;
  PayboxClient? _payboxClient;

  PitPaymentService(this.context);

  PayboxClient get payboxClient {
    _payboxClient ??= PayboxClient();
    return _payboxClient!;
  }

  String generateOrderId() {
    int timestamp = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
    return 'TOPUP_$timestamp';
  }

  /// Initialize top-up pmt via POST /pay/up/
  /// provider: "finik" or "freedompay"
  Future<String?> initPit({
    required double amount,
    required String provider,
  }) async {
    final adWalletBloc = context.read<PitBloc>();

    adWalletBloc.add(InitPitEvent(
      amount: amount,
      provider: provider,
    ));

    try {
      final state = await adWalletBloc.stream
          .firstWhere((s) => s.isSuccess || s.errors.isNotEmpty)
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () => adWalletBloc.state,
          );

      debugPrint(
          '[TOPUP-DEBUG] initPit result isSuccess=${state.isSuccess} paymentId=${state.pitResponse?.paymentId} errors=${state.errors}');
      if (state.isSuccess && state.pitResponse != null) {
        return state.pitResponse!.paymentId;
      }
      return null;
    } catch (e) {
      debugPrint('initPit error: $e');
      return null;
    }
  }

  Future<bool> processFinikPayment({
    required String orderId,
    required double amount,
    required String userName,
    required String userPhone,
    required String userCountry,
    String? userEmail,
    VoidCallback? onCancel,
  }) async {
    final beforeBalance = context.read<PitBloc>().state.balance;
    debugPrint(
        '[TOPUP-DEBUG] processFinikPayment orderId=$orderId amount=$amount beforeBalance=$beforeBalance');

    final parts = <String>[
      'Пополнение баланса',
      if (userName.isNotEmpty) userName,
      if (userPhone.isNotEmpty) userPhone,
      if (userCountry.isNotEmpty) userCountry,
      '${amount.toStringAsFixed(0)} сом',
    ];
    final description = parts.join(' | ');

    final result = await context.router.push<bool>(
      FinikPaymentRoute(
        orderId: orderId,
        amount: amount,
        description: description,
        phone: userPhone,
        userName: userName,
        email: userEmail,
        onCancel: onCancel ?? () {},
        checkPaymentStatus: () async {
          final bloc = context.read<PitBloc>();
          bloc.add(const LoadPitEvent());

          final state = await bloc.stream.firstWhere((s) => !s.isLoading);

          debugPrint(
            'Wallet Finik check: before=$beforeBalance, current=${state.balance}, expectedIncrease=$amount',
          );

          return state.balance >= beforeBalance + amount - 0.01;
        },
      ),
    );

    return result == true;
  }

  static String get _freedomPayWebhookUrl => ApiEndpoints.freedomPayWebhook;

  Future<bool?> processPayboxPayment({
    required String orderId,
    required double amount,
    required String userId,
    required String userEmail,
    required String userPhone,
    required String userName,
    required String userCountry,
    String? customWebhookUrl,
  }) async {
    String? redirectUrl;
    final parts = <String>[
      'Пополнение баланса',
      if (userName.isNotEmpty) userName,
      if (userPhone.isNotEmpty) userPhone,
      if (userCountry.isNotEmpty) userCountry,
      '${amount.toStringAsFixed(0)} сом',
    ];
    final description = parts.join(' | ');

    // Use custom webhook URL or default
    final webhookUrl = customWebhookUrl ?? _freedomPayWebhookUrl;
    debugPrint('processPayboxPayment: using webhook URL: $webhookUrl');

    try {
      final pmt = await payboxClient.createPayment(
        orderId: orderId,
        userId: userId,
        userEmail: userEmail.isNotEmpty ? userEmail : null,
        userPhone: userPhone.isNotEmpty ? userPhone : null,
        amount: amount,
        currencyCode: 'KGS',
        description: description,
        resultUrl: webhookUrl,
      );
      redirectUrl = pmt?.redirectUrl;
    } catch (e, stackTrace) {
      debugPrint('createPayment error: $e\n$stackTrace');
      return null;
    }

    if (redirectUrl == null || redirectUrl.isEmpty) {
      return null;
    }

    try {
      if (!context.mounted) return null;
      return await context.router.push<bool>(WebViewRoute(
        url: redirectUrl,
        onPmtSuccess: () {},
      ));
    } catch (e) {
      debugPrint('WebView error: $e');
      return null;
    }
  }

  /// Reloads the wallet and reports whether the balance ACTUALLY increased by
  /// [amount]. The credit is applied server-side by the provider webhook
  /// (/finik/webhook/, /freedompay/result/), which can lag a few seconds up to
  /// ~1 minute behind a successful charge. We therefore poll the wallet several
  /// times before giving up, so a real (but delayed) credit is reported as
  /// success instead of a misleading "pending". Returns as soon as the balance
  /// grows, or false once the retry window elapses.
  Future<bool> confirmBalanceCredited({
    required double beforeBalance,
    required double amount,
  }) async {
    // Capture the bloc once: the loop awaits across many frames, so we must not
    // touch `context` again (the widget may unmount mid-poll).
    final bloc = context.read<PitBloc>();
    const retryDelays = <Duration>[
      Duration(seconds: 2),
      Duration(seconds: 3),
      Duration(seconds: 5),
      Duration(seconds: 7),
      Duration(seconds: 10),
    ];

    for (var attempt = 0; attempt <= retryDelays.length; attempt++) {
      bloc.add(const LoadPitEvent());

      try {
        final state = await bloc.stream.firstWhere((s) => !s.isLoading).timeout(
              const Duration(seconds: 8),
              onTimeout: () => bloc.state,
            );
        if (state.balance >= beforeBalance + amount - 0.01) return true;
      } catch (_) {
        // Ignore a single failed poll; keep retrying until the window elapses.
      }

      if (attempt < retryDelays.length) {
        await Future<void>.delayed(retryDelays[attempt]);
      }
    }

    return false;
  }

  /// Refresh wallet balance from backend
  void refreshWalletBalance() {
    context.read<PitBloc>().add(const LoadPitEvent());
  }

  void showSuccessMessage(double amount) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Баланс успешно пополнен на ${amount.toStringAsFixed(0)} сом!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  /// Charge succeeded but the wallet has not been credited yet — the provider
  /// webhook credits server-side and may lag (or fail). Do not claim success.
  void showPendingMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Оплата принята. Баланс обновится после подтверждения платежа системой.',
        ),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 4),
      ),
    );
  }

  void showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
}
