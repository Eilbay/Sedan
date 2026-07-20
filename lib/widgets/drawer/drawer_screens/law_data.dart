import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:optombai/widgets/translation/text_translated.dart';

import 'package:optombai/core/import_links.dart';
import 'package:optombai/widgets/drawer/drawer_widget.dart';
import 'package:auto_route/auto_route.dart';
import 'package:optombai/widgets/bottom_nav.dart';

@RoutePage(name: 'LawDataRoute')
class LawData extends StatefulWidget {
  const LawData({super.key});

  @override
  State<LawData> createState() => _LawDataState();
}

class _LawDataState extends State<LawData> {
  final String phoneNumber = "+996551947777";
  final String message = "Привет! Я бы хотела узнать?";

  Future<void> launchWhatsApp() async {
    final String url =
        "https://wa.me/${phoneNumber.replaceAll('+', '')}?text=${Uri.encodeComponent(message)}";
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      throw 'Could not launch WhatsApp';
    }
  }

  _launchWeb(String urls) async {
    await launchUrl(Uri.parse(urls));
  }

  @override
  Widget build(BuildContext context) {
    bool stateSwitch = context.select((ThemeNotifier n) => n.isDarkMode);

    return CustomScaffold(
      bottomNavigationBar: const BottomNav(
        currentIndexOverride: -1,
        passive: true,
      ),
      title: "О нас",
      child: SingleChildScrollView(
        child: Container(
            decoration: BoxDecoration(
              color: stateSwitch ? const Color(0xff061324) : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 20.h,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const TextTranslated(
                        "Наши контактные данные",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(
                        height: 10.h,
                      ),
                      InkWell(
                        onTap: () => _launchWeb(
                            "https://www.instagram.com/optombai?igsh=MXV2NHVmM3VtdnN4dQ=="),
                        child: const CustomDrawerList(
                          image: "assets/icons/socials_dark/ins_dark.png",
                          title: "@optombai",
                        ),
                      ),
                      InkWell(
                        onTap: () => _launchWeb("https://t.me/+996551947777"),
                        child: const CustomDrawerList(
                          image: "assets/icons/socials_dark/telegram_dark.png",
                          title: "+996551947777",
                        ),
                      ),
                      InkWell(
                        onTap: launchWhatsApp,
                        child: const CustomDrawerList(
                          image: "assets/icons/socials_dark/whatsapp_dark.png",
                          title: "+996551947777",
                        ),
                      ),
                      SizedBox(
                        height: 30.h,
                      ),
                      const TextTranslated(
                        "Юридические данные компании:",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(
                        height: 10.h,
                      ),
                      const TextTranslated(
                        'Индивидуальный предприниматель\nОрманбаев Элдияр Абдумажитович\nИНН: 21710200000906',
                        style: TextStyle(fontWeight: FontWeight.normal),
                      ),
                      /*
                      SizedBox(
                        height: 10.h,
                      ),
                      const TextTranslated(
                        'Банковские реквизиты:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(
                        height: 10.h,
                      ),
                      const TextTranslated(
                        'Расчетный счет: 1032120001008429',
                        style: TextStyle(fontWeight: FontWeight.normal),
                      ),
                      SizedBox(
                        height: 10.h,
                      ),
                      const TextTranslated(
                        'БИК банка: 103021',
                        style: TextStyle(fontWeight: FontWeight.normal),
                      ),
                      SizedBox(
                        height: 10.h,
                      ),
                      const TextTranslated(
                        'ИНН банка: 01010199010016',
                        style: TextStyle(fontWeight: FontWeight.normal),
                      ),
                      SizedBox(
                        height: 10.h,
                      ),
                      const TextTranslated(
                        'Наименование банка получателя:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(
                        height: 10.h,
                      ),
                      const TextTranslated(
                        'Главная Дирекция ОАО "Коммерческий банк Кыргызстан',
                        style: TextStyle(fontWeight: FontWeight.normal),
                      ),*/
                      SizedBox(
                        height: 30.h,
                      ),
                      const TextTranslated(
                        "© 2025 . Социально-Торговая сеть — Все права защищены.",
                        style: TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            )),
      ),
    );
  }
}

class CustomContainer extends StatelessWidget {
  const CustomContainer({
    super.key,
    required this.text1,
    required this.text3,
  });

  final String text1;
  final String text3;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.topRight,
          colors: [
            Color(0xff328AC0),
            Color(0xff7DC7FB),
          ],
        ),
        image: const DecorationImage(
          image: AssetImage('assets/icons/drawer_icons/world.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: 20, right: 15, left: 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(text1, style: AppTextStyle.fulfillmentText2),
            const Text("OPTOMBAI", style: AppTextStyle.fulfillmentText),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.topRight,
                  colors: [
                    Color(0xff328AC0),
                    Color(0xff7DC7FB),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white, width: 2.w),
              ),
              child: TextTranslated(
                text3,
                style: const TextStyle(color: Colors.white, fontSize: 15),
              ),
            ),
            SizedBox(
              height: 20.h,
            ),
            /*Image.asset(
              'assets/icons/drawer_icons/phone_drawer.png',
            ),*/
          ],
        ),
      ),
    );
  }
}

class TextWithFrame extends StatelessWidget {
  const TextWithFrame({super.key, required this.text, required this.fontSize});

  final String text;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    bool stateSwitch = context.select((ThemeNotifier n) => n.isDarkMode);

    return Transform(
      transform: Matrix4.skewY(-0.02),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4.0),
        decoration: BoxDecoration(
          color: const Color(0xffAEDFFF),
          borderRadius: BorderRadius.circular(15),
        ),
        child: TextTranslated(
          text,
          style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: fontSize,
              color: stateSwitch ? Colors.white : Colors.black),
        ),
      ),
    );
  }
}

class BorderText extends StatelessWidget {
  final String text;

  const BorderText({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    bool stateSwitch = context.select((ThemeNotifier n) => n.isDarkMode);

    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: stateSwitch ? Colors.white : Colors.black, width: 1.3.w),
        ),
        child: TextTranslated(
          text,
          style: TextStyle(
              color: stateSwitch ? Colors.white : Colors.black, fontSize: 15),
        ));
  }
}

class ContainerWithoutPadding extends StatelessWidget {
  const ContainerWithoutPadding({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: const BoxDecoration(color: Color(0xffFF9900)),
      child: Column(
        children: [
          SizedBox(
            height: 40.h,
          ),
          Center(child: Image.asset('assets/icons/drawer_icons/znak.png')),
          SizedBox(
            height: 40.h,
          ),
          TextTranslated(
            text,
            style: const TextStyle(
                fontWeight: FontWeight.w500, fontSize: 16, color: Colors.white),
          ),
          SizedBox(height: 20.h),
        ],
      ),
    );
  }
}

class PaddingWidget extends StatelessWidget {
  const PaddingWidget({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
        child: child);
  }
}
