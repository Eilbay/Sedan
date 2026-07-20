import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:optombai/widgets/translation/text_translated.dart';

import 'package:optombai/core/import_links.dart';
import 'package:optombai/widgets/bottom_nav.dart';

import 'package:auto_route/auto_route.dart';
import 'package:optombai/widgets/drawer/drawer_screens/fulfilment_screen.dart';

@RoutePage(name: 'AboutUsRoute')
class AboutUs extends StatefulWidget {
  const AboutUs({super.key});

  @override
  State<AboutUs> createState() => _AboutUsState();
}

class _AboutUsState extends State<AboutUs> {
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

  @override
  Widget build(BuildContext context) {
    bool stateSwitch = context.select((ThemeNotifier n) => n.isDarkMode);

    return CustomScaffold(
      bottomNavigationBar: const BottomNav(
        currentIndexOverride: -1,
        passive: true,
      ),
      title: 'О платформе ',
      child: SingleChildScrollView(
        child: Container(
            decoration: BoxDecoration(
              color: stateSwitch ? const Color(0xff061324) : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(
                  height: 10.h,
                ),
                const CustomContainer(
                  text1: 'O нас',
                  text3: 'Социально-Торговая сеть',
                ),
                SizedBox(
                  height: 20.h,
                ),
                FulfillmentContainer(
                  right: 10,
                  bottom: 20,
                  child1: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const TextTranslated(
                        'Добро пожаловать \n в Социально-Торговая сеть',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                      const TextWithFrame(
                        text: 'OPTOMBAI',
                        fontSize: 28,
                      ),
                      SizedBox(
                        height: 20.h,
                      ),
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Transform(
                              transform: Matrix4.skewX(3.0),
                              child: Image.asset(
                                  'assets/icons/drawer_icons/circle2.png',
                                  color: stateSwitch
                                      ? Colors.white
                                      : Colors.black87)),
                          Center(
                              child: Image.asset(
                                  'assets/icons/drawer_icons/circle1.png',
                                  color: stateSwitch
                                      ? Colors.white
                                      : Colors.black87)),
                        ],
                      ),
                      SizedBox(
                        height: 30.h,
                      ),
                      const TextTranslated(
                        'Новая эра торговли начинается с  - платформой, где смелость инноваций и мудрость традиции сливаются воедино.',
                        style: TextStyle(
                            fontWeight: FontWeight.w500, fontSize: 16),
                      )
                    ],
                  ),
                ),
                SizedBox(
                  height: 10.h,
                ),
                FulfillmentContainer(
                  right: 0,
                  bottom: 0,
                  child1: Column(
                    children: [
                      SizedBox(
                        height: 30.h,
                      ),
                      Image.asset('assets/icons/drawer_icons/frame.png'),
                      SizedBox(height: 50.h),
                      const TextTranslated(
                        'Здесь каждый клик открывает дверь в мир возможностей.',
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.w700),
                      ),
                      SizedBox(
                        height: 20.h,
                      )
                    ],
                  ),
                ),
                SizedBox(
                  height: 40.h,
                ),
                const PaddingWidget(
                    child: TextTranslated(
                  'С чего все началось?',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 28),
                )),
                SizedBox(
                  height: 30.h,
                ),
                FulfillmentContainer(
                  right: 10,
                  bottom: 10,
                  child1: Column(
                    children: [
                      const TextTranslated(
                        'Мы начали с одежды,но наша амбиция не знает границ..',
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.w600),
                      ),
                      SizedBox(
                        height: 25.h,
                      ),
                      Image.asset('assets/icons/drawer_icons/ambition.png'),
                    ],
                  ),
                ),
                SizedBox(
                  height: 10.h,
                ),
                FulfillmentContainer(
                  right: 0,
                  bottom: 0,
                  child1: Stack(alignment: Alignment.bottomRight, children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                          bottomRight: Radius.circular(30)),
                      child: Image.asset(
                        'assets/icons/drawer_icons/globus.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const TextTranslated(
                          'Мы не следуем за трендами',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                        const TextWithFrame(
                          text: 'мы их задаем.',
                          fontSize: 28,
                        ),
                        SizedBox(
                          height: 60.h,
                        ),
                        const TextTranslated(
                          'В итоге мы переплели культуры оптовых рынков СНГ с элегантностью Европы, создавая уникальную платформу, где бизнес встречает стиль. ',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                        SizedBox(
                          height: 20.h,
                        ),
                        const TextTranslated(
                          'Постепенно мы будем охватывать весь мир! ',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                        SizedBox(
                          height: 100.h,
                        )
                      ],
                    ),
                  ]),
                ),
                SizedBox(
                  height: 10.h,
                ),
                FulfillmentContainer(
                  right: 0,
                  bottom: 0,
                  child1: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const BorderText(text: 'Путь к успеху'),
                      SizedBox(
                        height: 30.h,
                      ),
                      const Text(
                        '🎩',
                        style: TextStyle(fontSize: 50),
                      ),
                      SizedBox(
                        height: 15.h,
                      ),
                      const TextTranslated(
                        'На  вы найдете не просто поставщиков и производителей - вы найдете своих оптовых покупателейи партнеров в успехе.',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      SizedBox(
                        height: 20.h,
                      ),
                      const TextTranslated(
                        'В разделе "Заказы" каждый день ждут вас новые возможности для роста и развития.',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      SizedBox(
                        height: 25.h,
                      ),
                      Container(
                        padding: const EdgeInsets.only(
                            top: 20, bottom: 20, right: 90, left: 20),
                        decoration: BoxDecoration(
                            color: const Color(0xff333333),
                            borderRadius: BorderRadius.circular(30)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '😎',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 40),
                            ),
                            SizedBox(
                              height: 52.h,
                            ),
                            const TextTranslated(
                              'Добро пожаловать в мир,',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white),
                            ),
                            const TextTranslated('где крутость - ',
                                style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white)),
                            const TextWithFrame(
                              text: 'это стандарт.',
                              fontSize: 28,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 20.h,
                      )
                    ],
                  ),
                ),
                /*
                SizedBox(
                  height: 60.h,
                ),

                const ContainerWithoutPadding(
                  text:
                      'Мы бы хотели сделать сервис для вас полностью бесплатным, но, к сожалению, для вашего удобства и процветания вашего бизнеса, мы тратим средства на оплату серверов и прочих расходов, обеспечение команды, которая каждый день старается предоставить вам новые возможности, а также на масштабирование, чтобы привлечь больше единомышленников на нашу платформу и обеспечить новые возможности для вас.',
                ),*/
                SizedBox(
                  height: 60.h,
                ),
                FulfillmentContainer(
                  right: 20,
                  bottom: 20,
                  child1: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const TextTranslated(
                        'Не упускайте\nвозможности -',
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.w500),
                      ),
                      const TextTranslated(
                        'списки возможностей обновляются постоянно.',
                        style: TextStyle(
                            fontSize: 28, fontWeight: FontWeight.w700),
                      ),
                      SizedBox(
                        height: 30.h,
                      ),
                      Image.asset('assets/icons/drawer_icons/thanks.png'),
                      SizedBox(
                        height: 60.h,
                      ),
                      const TextTranslated(
                        'С уважением, команда  ❤️',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20.h),
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
