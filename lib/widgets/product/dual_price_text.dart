import 'package:optombai/core/import_links.dart';
import 'package:optombai/features/pricing/dual_price_calculator.dart';
import 'package:optombai/utils/extensions/number_grouping_extension.dart';
import 'package:optombai/widgets/translation/text_translated.dart';

/// Renders "<kgs> сом | <usd> $" using live FX rates from [CurrencyBloc], or
/// "Договорная" when the product has no price. Reused by every price
/// display (feed card, product detail) so they always agree on the same
/// converted numbers — see [DualPriceCalculator].
class DualPriceText extends StatelessWidget {
  const DualPriceText({
    super.key,
    required this.price,
    required this.currency,
    this.style,
  });

  final double? price;
  final String currency;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final rates = context.select((CurrencyBloc b) => b.state.currency);
    final dual = DualPriceCalculator(rates)
        .calculate(price: price, currency: currency);

    if (dual.kgs == null && dual.usd == null) {
      return TextTranslated('Договорная', style: style);
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (dual.kgs != null)
          Text('${dual.kgs!.groupedByThousands} сом', style: style),
        if (dual.kgs != null && dual.usd != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text('|', style: style),
          ),
        if (dual.usd != null)
          Text('${dual.usd!.groupedByThousands} \$', style: style),
      ],
    );
  }
}
