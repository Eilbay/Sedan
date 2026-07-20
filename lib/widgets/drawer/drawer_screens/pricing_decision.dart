import 'package:optombai/data/models/currency/currency_model.dart';
import 'package:optombai/pages/pmt/payment_region_resolver.dart';
import 'package:optombai/pages/pmt/pmt_screen.dart';

class PricingDecision {
  final UserRegion region;
  final String currencyCode;
  final PaymentMethod method;
  final double amount;
  const PricingDecision({
    required this.region,
    required this.currencyCode,
    required this.method,
    required this.amount,
  });
}

PricingDecision decidePricing({
  required String phoneE164,
  required String? countryIso,
  required double baseRub,
  required List<CurrencyModel> currencies,
}) {
  final region = resolveRegion(countryIso: countryIso, phoneE164: phoneE164);
  final cfg = autoPayMap[region]!;

  final cur = currencies.firstWhere(
    (c) => c.name == cfg.currencyCode,
    orElse: () => currencies.firstWhere((c) => c.name == 'USD'),
  );

  final rawAmount = rubToCurrency(
    rub: baseRub,
    currencyPriceStr: cur.price ?? '1',
  );

  final amount = rawAmount.roundToDouble();

  return PricingDecision(
    region: region,
    currencyCode: cur.name,
    method: cfg.method,
    amount: amount,
  );
}
