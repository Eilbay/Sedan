import 'package:collection/collection.dart';

import 'package:optombai/bloc/pmt_bloc/pmt_bloc.dart';
import 'package:optombai/bloc/pmt_bloc/pmt_event.dart';
import 'package:optombai/bloc/subscription_bloc/subscription_bloc.dart';
import 'package:optombai/bloc/subscription_bloc/subscription_event.dart';

import 'package:optombai/data/models/pmt/pmt_model.dart';
import 'package:optombai/data/models/subscription/subscription_plan_model.dart';
import 'package:optombai/pages/pmt/payment_region_resolver.dart';

import 'package:optombai/widgets/bottom_nav.dart';
import 'package:optombai/widgets/drawer/drawer_screens/pricing_decision.dart';
import 'package:optombai/widgets/drawer/drawer_screens/subscription_card.dart';
import 'package:optombai/widgets/drawer/drawer_screens/widgets/widgets/payment_methods_section.dart';
import 'package:optombai/widgets/drawer/premium_tariff.dart';

import 'package:optombai/core/import_links.dart';
import 'package:auto_route/auto_route.dart';
import 'package:optombai/app/router/app_router.dart';

enum PmtInfoInitialSection { none, global, russia, kg }

@RoutePage()
class PmtInfoScreen extends StatefulWidget {
  final PmtInfoInitialSection initialSection;
  final String premiumId;
  final PremiumTariff initialTariff;

  const PmtInfoScreen({
    super.key,
    this.initialSection = PmtInfoInitialSection.none,
    required this.premiumId,
    this.initialTariff = PremiumTariff.weekly,
  });

  @override
  State<PmtInfoScreen> createState() => _PmtInfoScreenState();
}

class _PmtInfoScreenState extends State<PmtInfoScreen> {
  final ScrollController _scrollController = ScrollController();

  final GlobalKey _globalCardKey = GlobalKey();
  final GlobalKey _russiaKey = GlobalKey();
  final GlobalKey _kgKey = GlobalKey();

  bool? isChecked = true;
  bool? isChecked2 = true;
  bool isShow = true;

  late User _user;
  late PremiumTariff _selectedTariff;

  @override
  void initState() {
    super.initState();
    _user = context.read<UserBloc>().state.user;
    _selectedTariff = widget.initialTariff;

    _fetchPmtStatus();
    _fetchSubscriptionDetails();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      switch (widget.initialSection) {
        case PmtInfoInitialSection.global:
          await _scrollTo(_globalCardKey);
          break;
        case PmtInfoInitialSection.russia:
          await _scrollTo(_russiaKey);
          break;
        case PmtInfoInitialSection.kg:
          await _scrollTo(_kgKey);
          break;
        case PmtInfoInitialSection.none:
          break;
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _scrollTo(GlobalKey key) async {
    final ctx = key.currentContext;
    if (ctx == null) return;

    await Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      alignment: 0.08,
    );
  }

  BusinessTariff _mapTariff(PremiumTariff t) {
    switch (t) {
      case PremiumTariff.weekly:
        return BusinessTariff.weekly;
      case PremiumTariff.monthly:
        return BusinessTariff.monthly;
    }
  }

  void _fetchSubscriptionDetails() {
    context.read<SubscriptionBloc>().add(FetchSubscriptionEvent());
  }

  void _fetchPmtStatus() {
    context.read<PmtBloc>().add(const PmtStatusEvent());
  }

  String generatePgOrderId() {
    final timestamp = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
    return 'ORDER_$timestamp';
  }

  Future<void> _launchWeb(String urls) async {
    await launchUrl(Uri.parse(urls));
  }

  void _openWhatsAppChat() async {
    const url =
        'https://wa.me/996551947777?text=%D0%97%D0%B4%D1%80%D0%B0%D0%B2%D1%81%D1%82%D0%B2%D1%83%D0%B9%D1%82%D0%B5%2C%20%D1%8F%20%D1%85%D0%BE%D1%87%D1%83%20%D0%BE%D1%84%D0%BE%D1%80%D0%BC%D0%B8%D1%82%D1%8C%20%D0%BF%D0%BE%D0%B4%D0%BF%D0%B8%D1%81%D0%BA%D1%83%20%D0%B2%20%D0%9Eptombai';
    final uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch $url';
    }
  }

  List<SubscriptionPlan> selectPlansToShow(List<SubscriptionPlan> plans) {
    final freePlan = plans.firstWhereOrNull((p) => p.isFree == true);

    SubscriptionPlan? businessPlan = plans
        .firstWhereOrNull((p) => (p.title.trim().toLowerCase() == 'бизнес'));

    businessPlan ??=
        plans.firstWhereOrNull((p) => p.title.toLowerCase().contains('бизнес'));

    final result = <SubscriptionPlan>[];
    if (freePlan != null) result.add(freePlan);
    if (businessPlan != null && businessPlan.id != freePlan?.id) {
      result.add(businessPlan);
    }
    return result;
  }

  void _launchPmtProcess(String orderId, String amount) {
    context.read<PmtBloc>().add(
          PmtCreateEvent(
            pmt: PmtModel(
              pmtId: orderId,
              amount: amount,
              status: 'pending',
              createdAt: DateTime.now().toUtc(),
              pmtMethod: 'card_bank',
            ),
          ),
        );
  }

  Future<void> _openPmt() async {
    final orderId = generatePgOrderId();
    final st = context.read<CurrencyBloc>().state;

    final d = decidePricing(
      phoneE164: _user.phone_number,
      countryIso: null,
      baseRub: _selectedTariff.priceRub.toDouble(),
      currencies: st.currency,
    );

    _launchPmtProcess(orderId, d.amount.toStringAsFixed(2));
    if (!mounted) return;

    await context.router.push(PmtRoute(
      orderId: orderId,
      userId: _user.id.toString(),
      userEmail: _user.email,
      userPhone: _user.phone_number,
      tariff: _mapTariff(_selectedTariff),
      amount: d.amount,
      currencyCode: d.currencyCode,
      description: 'Подписка «Бизнес» на  (${_selectedTariff.label})',
      premiumId: widget.premiumId,
      initialMethod: d.method,
      autoStart: false,
      skipChooser: false,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad =
        MediaQuery.paddingOf(context).bottom + kBottomNavigationBarHeight + 16;

    return CustomScaffold(
      bottomNavigationBar: const BottomNav(
        currentIndexOverride: -4,
        passive: true,
      ),
      title: 'Варианты оплаты',
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: EdgeInsets.fromLTRB(16, 0, 16, bottomPad),
          child: PaymentMethodsSection(
            selectedTariff: _selectedTariff,
            onTariffChanged: (tariff) =>
                setState(() => _selectedTariff = tariff),
            onWhatsappTap: _openWhatsAppChat,
            onTelegramTap: () => _launchWeb('https://t.me/optombai'),
            onOpenUrl: _launchWeb,
            globalCardKey: _globalCardKey,
            russiaKey: _russiaKey,
            kgKey: _kgKey,
            onPay: _openPmt,
            onPayRussia: () => _scrollTo(_russiaKey),

            /*regionUi: () {
              final st = context.read<CurrencyBloc>().state;
              final d = decidePricing(
                phoneE164: _user.phone_number,
                countryIso: null,
                baseRub: _selectedTariff.priceRub.toDouble(),
                currencies: st.currency,
              );

              
              if (d.region == UserRegion.ru) return UserRegionUi.ru;
              if (d.region == UserRegion.kg) return UserRegionUi.kg;
              return UserRegionUi.other;
            }(),*/

            regionUi: () {
              switch (widget.initialSection) {
                case PmtInfoInitialSection.russia:
                  return UserRegionUi.ru;
                case PmtInfoInitialSection.kg:
                  return UserRegionUi.kg;
                case PmtInfoInitialSection.global:
                  return UserRegionUi.other;
                case PmtInfoInitialSection.none:
                  break;
              }

              final st = context.read<CurrencyBloc>().state;
              final d = decidePricing(
                phoneE164: _user.phone_number,
                countryIso: null,
                baseRub: _selectedTariff.priceRub.toDouble(),
                currencies: st.currency,
              );

              if (d.region == UserRegion.ru) return UserRegionUi.ru;
              if (d.region == UserRegion.kg) return UserRegionUi.kg;
              return UserRegionUi.other;
            }(),
            priceLine: (tariff) {
              final st = context.read<CurrencyBloc>().state;
              final d = decidePricing(
                phoneE164: _user.phone_number,
                countryIso: null,
                baseRub: tariff.priceRub.toDouble(),
                currencies: st.currency,
              );

              final sym = switch (d.currencyCode) {
                'RUB' => '₽',
                'KGS' => 'сом',
                'KZT' => '₸',
                'UZS' => 'сум',
                'USD' => r'$',
                'EUR' => '€',
                'CNY' => '¥',
                _ => d.currencyCode,
              };

              return '${d.amount.toStringAsFixed(0)} $sym · ${tariff.label}';
            },
            amountLine: (tariff) {
              final st = context.read<CurrencyBloc>().state;
              final d = decidePricing(
                phoneE164: _user.phone_number,
                countryIso: null,
                baseRub: tariff.priceRub.toDouble(),
                currencies: st.currency,
              );

              final sym = switch (d.currencyCode) {
                'RUB' => '₽',
                'KGS' => 'сом',
                'KZT' => '₸',
                'UZS' => 'сум',
                'USD' => r'$',
                'EUR' => '€',
                'CNY' => '¥',
                _ => d.currencyCode,
              };

              return '${d.amount.toStringAsFixed(0)} $sym';
            },
          ),
        ),
      ),
    );
  }
}
