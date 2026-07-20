import 'dart:io';

import 'package:optombai/pages/pmt/payment_region_resolver.dart';
import 'package:optombai/pages/pit/widgets/pit_method_selector.dart'
    show PitPaymentMethod;
import 'package:optombai/pages/pmt/pmt_screen.dart' show PaymentMethod;

class PaymentAvailability {
  const PaymentAvailability._();

  static Set<PitPaymentMethod> topUpMethods(UserRegion r) {
    // KG mobile-app payments (finik) and the universal bank-card flow
    // (freedom) are available to every user in every region — the cards
    // form accepts foreign Visa/Mastercard as well, so there is no
    // reason to gate it by country.
    final methods = <PitPaymentMethod>{
      PitPaymentMethod.finik,
      PitPaymentMethod.freedom,
    };

    // Manager-assisted transfer is still RU-only (Sber + manual confirmation).
    if (r == UserRegion.ru) {
      methods.add(PitPaymentMethod.manager);
    }

    // IAP available on iOS for all regions (App Store guideline 3.1.1)
    if (Platform.isIOS) {
      methods.add(PitPaymentMethod.iap);
    }

    return methods;
  }

  static Set<PaymentMethod> subscriptionMethods(UserRegion r) {
    final methods = <PaymentMethod>{};

    switch (r) {
      case UserRegion.ru:
        methods.add(PaymentMethod.freedom);

      case UserRegion.kg:
      case UserRegion.kz:
      case UserRegion.uz:
        methods.addAll({PaymentMethod.finik, PaymentMethod.freedom});

      case UserRegion.cn:
      case UserRegion.other:
        break;
    }

    // IAP available on iOS for all regions (App Store guideline 3.1.1)
    if (Platform.isIOS) {
      methods.add(PaymentMethod.iap);
    }

    return methods;
  }

  static UserRegion regionOf({String? countryIso, required String phoneE164}) {
    return resolveRegion(countryIso: countryIso, phoneE164: phoneE164);
  }
}
