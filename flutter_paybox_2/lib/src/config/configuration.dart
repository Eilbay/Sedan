import 'package:flutter_paybox_2/src/api/constants.dart';

import 'configs.dart';

class Configuration {
  int? merchantId;
  String? userPhone;
  String? userEmail;
  bool testMode;
  PaymentSystem? paymentSystem;
  RequestMethod? requestMethod;
  Language? language;
  bool autoClearing;
  String? encoding;
  int? paymentLifetime;
  int? recurringLifetime;
  bool recurringMode;
  String? checkUrl;
  String? resultUrl;
  String? refundUrl;
  String? captureUrl;
  String? currencyCode;
  String? successUrl;
  String? failureUrl;
  bool isFrameRequired;

  Configuration({
    this.merchantId,
    this.userPhone,
    this.userEmail,
    this.testMode = true,
    this.paymentSystem = PaymentSystem.EPAYWEBKGS,
    this.requestMethod = RequestMethod.POST,
    this.language = Language.ru,
    this.autoClearing = true,
    this.encoding = "UTF-8",
    this.paymentLifetime = 300,
    this.recurringLifetime = 0,
    this.recurringMode = false,
    this.checkUrl,
    this.resultUrl = "https://paybox.kz",
    this.captureUrl,
    this.currencyCode = "KGS",
    this.successUrl = "${BASE_URL}success",
    this.failureUrl = "${BASE_URL}failure",
    this.isFrameRequired = false,
  }) : assert(merchantId != null && merchantId != 0);

  Map<String, dynamic> getParams({
    Map<String, dynamic>? extraParams = const {},
  }) {
    Map<String, dynamic> params = {};
    if (extraParams != null && extraParams.isNotEmpty) {
      params.addAll(extraParams);
    }

    params[MERCHANT_ID] = merchantId;
    params[TEST_MODE] = testMode ? 1 : 0;
    params[RECURRING_START] = recurringMode ? 1 : 0;
    params[AUTOCLEARING] = autoClearing ? 1 : 0;
    params[REQUEST_METHOD] = requestMethod?.toSortString();
    params[CURRENCY] = currencyCode;
    params[LIFETIME] = paymentLifetime;
    params[ENCODING] = encoding;
    params[RECURRING_LIFETIME] = recurringLifetime;
    params[PAYMENT_SYSTEM] = paymentSystem?.toSortString();
    params[SUCCESS_METHOD] = "GET";
    params[FAILURE_METHOD] = "GET";
    params[SUCCESS_URL] = successUrl;
    params[FAILURE_URL] = failureUrl;
    params[BACK_LINK] = successUrl;
    params[POST_LINK] = successUrl;
    params[LANGUAGE] = language?.toSortString();

    if (isFrameRequired) {
      params[PAYMENT_ROUTE] = "frame";
    }

    notNullNotEmpty(userPhone, () {
      params[USER_PHONE] = userPhone;
    });

    notNullNotEmpty(userEmail, () {
      params[USER_CONTACT_EMAIL] = userEmail;
      params[USER_EMAIL] = userEmail;
    });
    notNullNotEmpty(captureUrl, () {
      params[CAPTURE_URL] = captureUrl;
    });

    notNullNotEmpty(refundUrl, () {
      params[REFUND_URL] = refundUrl;
    });

    notNullNotEmpty(resultUrl, () {
      params[RESULT_URL] = resultUrl;
    });

    notNullNotEmpty(checkUrl, () {
      params[CHECK_URL] = checkUrl;
    });

    return params;
  }


}

void notNullNotEmpty(String? value, Function() function) {
  if (value != null && value.isNotEmpty) function.call();
}
