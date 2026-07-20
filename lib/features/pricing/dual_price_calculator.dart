import 'package:optombai/data/models/currency/currency_model.dart';

/// A product's price converted into KGS and USD. A leg is null when its FX
/// rate hasn't loaded yet, rather than guessing a value.
class DualPrice {
  const DualPrice({this.kgs, this.usd});

  final double? kgs;
  final double? usd;
}

/// Converts a product's native price into KGS and USD using live FX rates
/// (each rate is "how many KGS for 1 unit of that currency"). Single source
/// of truth so every price display (feed card, product detail, ...) agrees
/// on the same converted numbers.
class DualPriceCalculator {
  const DualPriceCalculator(this.rates);

  final List<CurrencyModel> rates;

  DualPrice calculate({required double? price, required String currency}) {
    if (price == null || price == 0) return const DualPrice();

    final usdRate = _rateFor('USD');

    if (currency == 'KGS') {
      final usd = (usdRate != null && usdRate > 0) ? price / usdRate : null;
      return DualPrice(kgs: price, usd: usd);
    }

    if (currency == 'USD') {
      final kgs = usdRate != null ? price * usdRate : null;
      return DualPrice(kgs: kgs, usd: price);
    }

    // Any other native currency (EUR/CNY/...): convert through its own rate.
    final ownRate = _rateFor(currency);
    if (ownRate == null) return const DualPrice();
    final kgs = price * ownRate;
    final usd = (usdRate != null && usdRate > 0) ? kgs / usdRate : null;
    return DualPrice(kgs: kgs, usd: usd);
  }

  double? _rateFor(String code) {
    for (final rate in rates) {
      if (rate.name == code) return double.tryParse(rate.price ?? '');
    }
    return null;
  }
}
