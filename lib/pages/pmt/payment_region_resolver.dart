enum UserRegion { kg, ru, uz, kz, cn, other }

UserRegion resolveRegion({String? countryIso, required String phoneE164}) {
  final iso = (countryIso ?? '').toUpperCase().trim();
  if (iso == 'KG') return UserRegion.kg;
  if (iso == 'RU') return UserRegion.ru;
  if (iso == 'UZ') return UserRegion.uz;
  if (iso == 'KZ') return UserRegion.kz;
  if (iso == 'CN') return UserRegion.cn;

  final p = normalizeE164(phoneE164);

  if (p.startsWith('+996')) return UserRegion.kg;
  if (p.startsWith('+998')) return UserRegion.uz;
  if (p.startsWith('+997')) return UserRegion.kz;
  if (p.startsWith('+86')) return UserRegion.cn;

  if (p.startsWith('+7')) {
    final d = firstNationalDigitAfterCountryCode(p);
    if (d == null) return UserRegion.other;

    if (d == '0' || d == '6' || d == '7') return UserRegion.kz;
    if (d == '2' || d == '3' || d == '4' || d == '5' || d == '9') {
      return UserRegion.ru;
    }

    return UserRegion.ru;
  }

  return UserRegion.other;
}

String normalizeE164(String phone) {
  final digits = phone.replaceAll(RegExp(r'[^0-9+]'), '');
  final cleaned = digits.startsWith('+') ? digits : '+$digits';

  if (cleaned.startsWith('+7') && cleaned.length >= 12) return cleaned;
  return cleaned;
}

String? firstNationalDigitAfterCountryCode(String e164) {
  if (!e164.startsWith('+7') || e164.length < 3) return null;
  final ch = e164[2];
  return RegExp(r'\d').hasMatch(ch) ? ch : null;
}

double rubToCurrency({
  required double rub,
  required String currencyPriceStr,
}) {
  final rate = double.parse(currencyPriceStr);
  return rub / rate;
}
