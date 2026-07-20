import 'package:auto_route/auto_route.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:optombai/app/router/app_router.dart';
import 'package:optombai/core/import_links.dart';
import 'package:optombai/data/models/subscription/subscription_plan_model.dart';
import 'package:optombai/widgets/drawer/drawer_screens/pricing_decision.dart';
import 'package:optombai/widgets/translation/text_translated.dart';

enum BusinessTariff { weekly, monthly }

class SubscriptionCard extends StatefulWidget {
  final SubscriptionPlan plan;
  final bool isRegister;
  final User user;

  final void Function({required BusinessTariff tariff}) onSubscribe;

  const SubscriptionCard({
    super.key,
    required this.user,
    required this.plan,
    required this.onSubscribe,
    required this.isRegister,
  });

  @override
  State<SubscriptionCard> createState() => _SubscriptionCardState();
}

class _SubscriptionCardState extends State<SubscriptionCard> {
  BusinessTariff _selectedTariff = BusinessTariff.monthly;

  String _symbol(String code) => switch (code) {
        'USD' => r'$',
        'EUR' => '€',
        'RUB' => '₽',
        'KZT' => '₸',
        'UZS' => 'сум',
        'KGS' => 'сом',
        'CNY' => '¥',
        _ => code,
      };

  String _formatNum(num v) => v.toStringAsFixed(0);

  double _baseRubFor(BusinessTariff t) => switch (t) {
        BusinessTariff.weekly => 922.0,
        BusinessTariff.monthly => 3600.0,
        //BusinessTariff.weekly => 1.0,
        //BusinessTariff.monthly => 1.0,
      };

  String _tariffPeriod(BusinessTariff tariff) => switch (tariff) {
        BusinessTariff.weekly => 'неделю',
        BusinessTariff.monthly => 'месяц',
      };

  @override
  Widget build(BuildContext context) {
    final plan = widget.plan;
    final user = widget.user;
    final isStandard = plan.isFree;

    final bool isPremiumUser = user.userStatus?.isPremium ?? false;
    final bool isThisPlanActive = isPremiumUser && !plan.isFree;
    final bool isLoggedIn = widget.isRegister;

    final currencyState = context.select((CurrencyBloc b) => b.state);
    final currencies = currencyState.currency;

    PricingDecision? d;
    if (!isStandard && currencies.isNotEmpty) {
      d = decidePricing(
        phoneE164: user.phone_number,
        countryIso: null,
        baseRub: _baseRubFor(_selectedTariff),
        currencies: currencies,
      );
    }

    final backgroundColor = isStandard ? const Color(0xFF3A97E0) : const Color.fromARGB(255, 0, 0, 0);

    final priceText = (isStandard || d == null)
        ? null
        : '${_formatNum(d.amount)} ${_symbol(d.currencyCode)}/${_tariffPeriod(_selectedTariff)}';

    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Stack(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image(
                    image: AssetImage(!isStandard ? 'assets/plan_businnes2.png' : 'assets/user.png'),
                    height: 140,
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextTranslated(
                        !isStandard ? 'БИЗНЕС' : 'СТАНДАРТ',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: isStandard ? Colors.white : const Color(0xFFD4AF37),
                        ),
                      ),
                      if (!isStandard) const SizedBox(width: 3),
                      if (!isStandard)
                        Image.asset(
                          'assets/izumrud.png',
                          width: 42,
                          height: 42,
                        ),
                    ],
                  ),
                  if (!isStandard && (!isLoggedIn || isThisPlanActive)) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white, width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle, color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          TextTranslated(
                            isLoggedIn ? 'Вы уже подключены!' : 'Необходимо авторизоваться',
                            style: const TextStyle(
                              color: Color(0xFFD4AF37),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (!isStandard) ...[
                    _buildCheckRow("Безлимитный доступ к заказам", const Color(0xFFD4AF37), true),
                    _buildCheckRow("Безлимитный доступ к покупателям", const Color(0xFFD4AF37), true),
                    _buildCheckRow("Безлимитный доступ к производителям", const Color(0xFFD4AF37), true),
                    _buildCheckRow("Безлимитный доступ к поставщикам", const Color(0xFFD4AF37), true),
                    _buildCheckRow(
                      "Безлимитный доступ к товарам поставщиков и производителей",
                      const Color(0xFFD4AF37),
                      true,
                    ),
                    _buildCheckRow(
                      "Продвижение предприятий в топ-списке среди поставщиков и производителей",
                      const Color(0xFFD4AF37),
                      true,
                    ),
                  ] else ...[
                    _buildCheckRow("Безлимитный доступ к поставщикам", Colors.white, false),
                    _buildCheckRow("Безлимитный доступ к производителям", Colors.white, false),
                    _buildCheckRow(
                      "Безлимитный доступ к товарам поставщиков и производителей",
                      Colors.white,
                      false,
                    ),
                    _buildCheckRowNotIncluded("Безлимитный доступ к заказам", Colors.white),
                    _buildCheckRowNotIncluded("Безлимитный доступ к покупателям", Colors.white),
                    _buildCheckRowNotIncluded(
                      "Продвижение предприятий в топ-списке среди поставщиков или производителей",
                      Colors.white,
                    ),
                  ],
                  const SizedBox(height: 5),
                  if (isStandard)
                    const TextTranslated(
                      'БЕСПЛАТНО',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: Colors.white,
                      ),
                    )
                  else ...[
                    const SizedBox(height: 12),
                    Center(
                      child: TextTranslated(
                        priceText ?? '${_formatNum(_baseRubFor(_selectedTariff))} ₽/${_tariffPeriod(_selectedTariff)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Color(0xFFD4AF37),
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: (isLoggedIn && isThisPlanActive)
                            ? null
                            : () {
                                if (!isLoggedIn) {
                                  context.router.push(const SignInRoute());
                                } else {
                                  widget.onSubscribe(tariff: _selectedTariff);
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF307FDC),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          disabledBackgroundColor: const Color(0xFFD4AF37).withValues(alpha: 0.5),
                        ),
                        child: TextTranslated(
                          !isLoggedIn ? 'Авторизироваться' : (isThisPlanActive ? 'Активна' : 'Оформить подписку'),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  static Widget _buildCheckRow(String text, Color color, bool gold) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          gold
              ? const Icon(Icons.check_circle, color: Color(0xFFD4AF37), size: 30)
              : Image.asset('assets/okay.png', width: 30, height: 30, fit: BoxFit.contain),
          SizedBox(width: 8.w),
          Expanded(
            child: TextTranslated(
              text,
              style: TextStyle(
                fontSize: 14,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildCheckRowNotIncluded(String text, Color color, {bool gold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          gold
              ? const Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(Icons.circle, color: Color.fromARGB(255, 217, 76, 76), size: 30),
                    Icon(Icons.close, color: Colors.black, size: 20),
                  ],
                )
              : Image.asset('assets/crest.png', width: 30, height: 30, fit: BoxFit.contain),
          SizedBox(width: 8.w),
          Expanded(
            child: TextTranslated(
              text,
              style: TextStyle(fontSize: 14, color: color),
            ),
          ),
        ],
      ),
    );
  }
}
