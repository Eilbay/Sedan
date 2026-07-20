import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_paybox_2/paybox.dart';

import 'dart:developer' as developer;

class PayboxClient {
  late final int _merchantId;
  late final String _secretKey;
  late final String _merchantCurrency;
  late final bool _testMode;

  PayboxClient() {
    _merchantId = int.parse(dotenv.env['MERCHANT_ID']!);
    _secretKey = dotenv.env['SECRET_KEY']!;
    _merchantCurrency = dotenv.env['MERCHANT_CURRENCY'] ?? 'KGS';
    _testMode =
        (dotenv.env['PAYBOX_TEST_MODE'] ?? 'false').toLowerCase() == 'true';
  }

  String? normalizePhoneToDigits(String? phone) {
    if (phone == null) return null;
    return phone.replaceAll(RegExp(r'[^0-9]'), '');
  }

  Future<Payment?> createPayment({
    required String orderId,
    required String userId,
    String? userEmail,
    String? userPhone,
    required double amount,
    required String currencyCode,
    required String description,
    String? resultUrl,
  }) async {
    final paybox = Paybox(
      merchantId: _merchantId,
      secretKey: _secretKey,
    );
    final normalizedPhone = normalizePhoneToDigits(userPhone);

    paybox.configuration
      ..testMode = _testMode
      ..currencyCode = _merchantCurrency
      ..userPhone = normalizedPhone
      ..userEmail = userEmail
      ..recurringLifetime = 1;

    // Set result URL for webhook callback
    if (resultUrl != null && resultUrl.isNotEmpty) {
      paybox.configuration.resultUrl = resultUrl;
      developer.log('createPayment -> resultUrl=$resultUrl',
          name: 'PayboxClient');
    }

    if (userPhone != null && userPhone.isNotEmpty) {
      paybox.configuration.userPhone = userPhone;
    }
    if (userEmail != null && userEmail.isNotEmpty) {
      paybox.configuration.userEmail = userEmail;
    }

    developer.log(
      'createPayment -> amount=$amount $_merchantCurrency, email=$userEmail, phone=$userPhone',
      name: 'PayboxClient',
    );

    final extraParams = <String, dynamic>{};
    if (userEmail != null && userEmail.isNotEmpty) {
      extraParams['email'] = userEmail;
    }
    if (userPhone != null && userPhone.isNotEmpty) {
      extraParams['phone'] = userPhone;
    }

    final pmt = await paybox.createPayment(
      amount: amount,
      description: description,
      orderId: orderId,
      userId: userId,
      extraParams: extraParams.isNotEmpty ? extraParams : null,
    );

    return pmt;
  }
}
