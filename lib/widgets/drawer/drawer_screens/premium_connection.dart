import 'package:collection/collection.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:optombai/bloc/pmt_bloc/pmt_bloc.dart';
import 'package:optombai/bloc/pmt_bloc/pmt_event.dart';
import 'package:optombai/bloc/pmt_bloc/pmt_state.dart';
import 'package:optombai/bloc/subscription_bloc/subscription_bloc.dart';
import 'package:optombai/bloc/subscription_bloc/subscription_event.dart';
import 'package:optombai/bloc/subscription_bloc/subscription_state.dart';

import 'package:optombai/data/models/pmt/pmt_model.dart';
import 'package:optombai/data/models/subscription/subscription_plan_model.dart';
import 'package:optombai/pages/pmt/pmt_screen.dart' show PaymentMethod;

import 'package:optombai/widgets/bottom_nav.dart';
import 'package:optombai/widgets/drawer/drawer_screens/pricing_decision.dart';
import 'package:optombai/widgets/drawer/drawer_screens/subscription_card.dart';
import 'package:optombai/widgets/translation/text_translated.dart';
// import 'package:flutter_web_browser/flutter_web_browser.dart';
import 'package:optombai/core/import_links.dart';
import 'package:auto_route/auto_route.dart';
import 'package:optombai/app/router/app_router.dart';

@RoutePage()
class ProAccountsScreen extends StatefulWidget {
  const ProAccountsScreen({super.key});

  @override
  State<ProAccountsScreen> createState() => _ProAccountsScreenState();
}

class _ProAccountsScreenState extends State<ProAccountsScreen> {
  bool? isChecked = true;
  bool? isChecked2 = true;
  bool isShow = true;
  late User _user;
  StreamSubscription? _pmtSubscription;

  @override
  void initState() {
    super.initState();
    _user = context.read<UserBloc>().state.user;
    _fetchPmtStatus();
    _fetchSubscriptionDetails();
  }

  @override
  void dispose() {
    _pmtSubscription?.cancel();
    super.dispose();
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

  void _fetchSubscriptionDetails() {
    context.read<SubscriptionBloc>().add(FetchSubscriptionEvent());
  }

  void _fetchPmtStatus() {
    context.read<PmtBloc>().add(const PmtStatusEvent());
  }

  String generatePgOrderId() {
    int timestamp = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
    return 'ORDER_$timestamp';
  }

  void _launchPmtProcess(BuildContext context, String orderId, String amount) {
    context.read<PmtBloc>().add(PmtCreateEvent(
        pmt: PmtModel(
            pmtId: orderId,
            amount: amount,
            status: 'pending',
            createdAt: DateTime.now().toUtc(),
            pmtMethod: 'card_bank')));
  }

  @override
  Widget build(BuildContext context) {
    bool stateSwitch = context.select((ThemeNotifier n) => n.isDarkMode);
    bool isRegister = context.select((ThemeNotifier n) => n.isRegister);

    return BlocListener<PmtBloc, PmtState>(
      listener: (context, state) {
        if (state.isSuccess) {}
      },
      child: CustomScaffold(
        bottomNavigationBar: const BottomNav(
          currentIndexOverride: -4,
          passive: true,
        ),
        title: 'Тарифы',
        child: Container(
          decoration: BoxDecoration(
            color: stateSwitch ? const Color(0xff061324) : null,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BlocBuilder<SubscriptionBloc, SubscriptionState>(
                      builder: (context, state) {
                    if (state is SubscriptionLoading) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (state is SubscriptionLoaded) {
                      final List<SubscriptionPlan> visible =
                          selectPlansToShow(state.plans);
                      if (visible.isEmpty) {
                        return const Center(
                            child: TextTranslated('Планы пока недоступны'));
                      }
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: visible.length,
                        itemBuilder: (context, index) {
                          final plan = visible[index];
                          return SubscriptionCard(
                            isRegister: isRegister,
                            plan: plan,
                            user: _user,
                            onSubscribe: ({required tariff}) {
                              if (!isRegister) {
                                context.router.push(const SignInRoute());
                                return;
                              }

                              final orderId = generatePgOrderId();

                              final currencyState =
                                  context.read<CurrencyBloc>().state;
                              final baseRub = switch (tariff) {
                                BusinessTariff.weekly => 922.0,
                                BusinessTariff.monthly => 3600.0,
                                //BusinessTariff.weekly => 1.0,
                                //BusinessTariff.monthly => 1.0,
                              };

                              final decision = decidePricing(
                                phoneE164: _user.phone_number,
                                countryIso: null,
                                baseRub: baseRub,
                                currencies: currencyState.currency,
                              );

                              _launchPmtProcess(
                                context,
                                orderId,
                                decision.amount.toStringAsFixed(0),
                              );

                              context.router.push(PmtRoute(
                                orderId: orderId,
                                userId: _user.id.toString(),
                                userEmail: _user.email,
                                userPhone: _user.phone_number,
                                tariff: tariff,
                                amount: decision.amount,
                                currencyCode: decision.currencyCode,
                                description: 'План ${plan.title} на ',
                                premiumId: plan.id.toString(),
                                initialMethod: decision.method,
                                autoStart:
                                    decision.method != PaymentMethod.sber,
                              ));
                            },
                          );
                        },
                      );
                    } else {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const TextTranslated('Ошибка загрузки тарифов'),
                            SizedBox(height: 12.h),
                            ElevatedButton(
                              onPressed: _fetchSubscriptionDetails,
                              child: const TextTranslated('Повторить'),
                            ),
                          ],
                        ),
                      );
                    }
                  }),
                  SizedBox(height: 8.h),
                  const TextTranslated(
                    'Возврат средств возможен в размере 50% от стоимости тарифа при обращении в течение 24 часов с момента покупки.',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 24.h),
                  const TextTranslated(
                    'Преимущества  "Безлимитный"',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
                  ),
                  SizedBox(height: 30.h),
                  const CustomPremiumContainer(
                    color: Color(0xff0095D5),
                    textNumber: '1',
                    textSecond: 'Преимущества',
                    image: 'assets/icons/drawer_icons/shopping.png',
                    text3: 'Безлимитный доступ к заказам',
                    text4:
                        'Получите неограниченный доступ к разделу заказов. Принимайте заказы напрямую от покупателей, общайтесь без посредников и расширяйте базу клиентов. Увеличивайте продажи, реагируя оперативно на новые запросы.',
                  ),
                  SizedBox(
                    height: 15.h,
                  ),
                  const CustomPremiumContainer(
                    color: Color.fromARGB(255, 87, 189, 85),
                    textNumber: '2',
                    textSecond: 'Преимущества',
                    image: 'assets/icons/drawer_icons/more.png',
                    text3: 'Безлимитный доступ к покупателям',
                    text4:
                        'Прямой доступ к широкой базе покупателей. Продавайте без ограничений. Выстраивайте долгосрочные отношения и находите постоянных клиентов без дополнительных комиссий.',
                  ),
                  SizedBox(
                    height: 15.h,
                  ),
                  const CustomPremiumContainer(
                    color: Color.fromARGB(255, 130, 155, 244),
                    textNumber: '3',
                    textSecond: 'Преимущества',
                    image: 'assets/icons/drawer_icons/vip-card.png',
                    text3: 'Продвижение',
                    text4:
                        'Ваше предприятие в приоритетном топ-списке среди поставщиков и производителей, что увеличивает видимость, привлекает больше заказчиков и ускоряет заключение сделок.',
                  ),
                  SizedBox(height: 30.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CustomPremiumText extends StatelessWidget {
  const CustomPremiumText({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return TextTranslated(
      title,
      maxLines: 9,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
    );
  }
}

class CustomPremiumContainer extends StatelessWidget {
  const CustomPremiumContainer(
      {super.key,
      required this.color,
      required this.textNumber,
      required this.textSecond,
      required this.image,
      required this.text3,
      required this.text4});

  final String textNumber;
  final String textSecond;
  final String text3;
  final String text4;
  final String image;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration:
          BoxDecoration(borderRadius: BorderRadius.circular(20), color: color),
      child: Stack(children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 1.w,
                    ),
                  ),
                  child: TextTranslated(
                    textNumber,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 17,
                        color: white),
                  ),
                ),
                SizedBox(
                  width: 10.w,
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(50),
                    color: Colors.transparent,
                    border: Border.all(
                      color: Colors.white,
                      width: 1.w,
                    ),
                  ),
                  child: TextTranslated(
                    textSecond,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: white),
                  ),
                )
              ],
            ),
            SizedBox(height: 50.h),
            TextTranslated(
              text3,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 17, color: white),
            ),
            SizedBox(
              height: 10.h,
            ),
            TextTranslated(
              text4,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 14, color: white),
            ),
            SizedBox(
              height: 10.h,
            ),
          ],
        ),
        Align(
            widthFactor: 34.4,
            heightFactor: 2.0,
            alignment: Alignment.centerRight,
            child: Image.asset(image)),
      ]),
    );
  }
}

class PremiumContainer extends StatelessWidget {
  const PremiumContainer(
      {super.key,
      required this.titlePro,
      required this.image,
      required this.text,
      this.child,
      required this.color1,
      required this.color2});

  final String titlePro;
  final String image;
  final String text;
  final Widget? child;
  final Color color1;
  final Color color2;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 35),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.topRight,
          colors: [
            color1,
            color2,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TextTranslated('План', style: AppTextStyle.premiumText2),
          SizedBox(
            height: 5.h,
          ),
          Row(
            children: [
              const TextTranslated('', style: AppTextStyle.premiumText),
              SizedBox(width: 10.w),
              Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.white),
                child: TextTranslated(
                  titlePro,
                  style: const TextStyle(
                      fontSize: 22,
                      color: activeColor,
                      fontWeight: FontWeight.w700),
                ),
              )
            ],
          ),
          SizedBox(
            height: 15.h,
          ),
          TextTranslated(text, maxLines: 8, style: AppTextStyle.premiumText2),
          SizedBox(
            height: 30.h,
          ),
          Center(
            child: Image.asset(image),
          ),
          SizedBox(
            height: 20.h,
          ),
          Container(
            child: child,
          ),
        ],
      ),
    );
  }
}
