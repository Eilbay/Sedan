import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:optombai/widgets/bottom_nav.dart';
import 'package:optombai/widgets/drawer/drawer_screens/about_us.dart';
import 'package:optombai/widgets/translation/text_translated.dart';
import 'package:auto_route/auto_route.dart';
import 'package:optombai/core/import_links.dart';

Future<void> _launchWeb(String urls) async {
  await launchUrl(Uri.parse(urls));
}

const _whatsAppUrl =
    "https://wa.me/996551947777?text=%D0%97%D0%B4%D1%80%D0%B0%D0%B2%D1%81%D1%82%D0%B2%D1%83%D0%B9%D1%82%D0%B5%2C%20%D0%BF%D0%B8%D1%88%D1%83%20%D0%B2%D0%B0%D0%BC%20%D0%B8%D0%B7%20%C2%AB%D0%9E%D0%BF%D1%82%D0%BE%D0%BC%D0%B1%D0%B0%D0%B9%C2%BB.%20%D0%98%D0%BD%D1%82%D0%B5%D1%80%D0%B5%D1%81%D1%83%D0%B5%D1%82%20%D1%84%D1%83%D0%BB%D1%84%D0%B8%D0%BB%D0%BC%D0%B5%D0%BD%D1%82%20";

@RoutePage()
class FulfilmentScreen extends StatefulWidget {
  const FulfilmentScreen({super.key});

  @override
  State<FulfilmentScreen> createState() => _FulfilmentScreenState();
}

class _FulfilmentScreenState extends State<FulfilmentScreen> {
  @override
  Widget build(BuildContext context) {
    final stateSwitch = context.select((ThemeNotifier n) => n.isDarkMode);

    return CustomScaffold(
      floatingActionButton: const _WhatsAppFab(),
      title: "Фулфилмент",
      bottomNavigationBar:
          const BottomNav(currentIndexOverride: -1, passive: true),
      child: SingleChildScrollView(
        child: Container(
          decoration: BoxDecoration(
            color: stateSwitch ? const Color(0xff061324) : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SizedBox(height: 10.h),
              const _HeroBanner(),
              SizedBox(height: 40.h),
              _SectionHeader(
                prefix: 'Что такое ',
                highlighted: 'фулфилмент',
                suffix: ' и зачем он нужен?',
                isDarkMode: stateSwitch,
              ),
              SizedBox(height: 30.h),
              const _ConvenienceCard(),
              SizedBox(height: 10.h),
              _SectionHeader(
                prefix: 'Наши услуги ',
                highlighted: 'включают',
                isDarkMode: stateSwitch,
              ),
              SizedBox(height: 30.h),
              const _ServiceCard(
                imageAsset: 'assets/frame_1.png',
                title: 'Юридическая проверка',
                description:
                    'Проверяем поставщиков и производителей на надежность и соблюдение стандартов качества. Это важный этап для предотвращения рисков и обеспечения безопасности сделок.',
              ),
              SizedBox(height: 30.h),
              const _ServiceCard(
                imageAsset: 'assets/frame_2.png',
                title: 'Пересчет товара',
                description:
                    'Ведем точный учет товаров на складе, предоставляем детализированные отчеты по остаткам и продажам. Это помогает вам принимать обоснованные бизнес-решения.',
              ),
              SizedBox(height: 30.h),
              const _ServiceCard(
                imageAsset: 'assets/frame_3.png',
                title: 'Проверка на брак',
                description:
                    'Проводим тщательный контроль качества продукции перед отправкой. Обнаруженные дефекты фиксируются, а бракованные товары отсеиваются.',
              ),
              SizedBox(height: 30.h),
              const _ServiceCard(
                imageAsset: 'assets/frame_4.png',
                title: 'Фото и видеоотчет',
                description:
                    'Фиксируем каждую партию товаров перед отправкой с помощью фото- и видеоматериалов, чтобы вы были уверены в качестве обработки заказов.',
              ),
              SizedBox(height: 30.h),
              const _ServiceCard(
                imageAsset: 'assets/frame_5.png',
                title: 'Маркировка и упаковка',
                description:
                    'Обеспечиваем профессиональную упаковку и маркировку товаров в соответствии с требованиями маркетплейсов и логистики.',
              ),
              SizedBox(height: 30.h),
              const _ServiceCard(
                imageAsset: 'assets/frame_6.png',
                title: 'Логистика по странам и складам Ozon и Wildberries',
                description:
                    'Организуем доставку ваших товаров на склады маркетплейсов и в другие города. Гарантируем оперативную обработку заказов и надежную транспортировку.',
              ),
              SizedBox(height: 30.h),
              _HighlightedSectionHeader(
                highlighted: 'Доставка',
                suffix: ' в рамках фулфилмента',
                isDarkMode: stateSwitch,
              ),
              SizedBox(height: 30.h),
              const _DeliveryCard(
                imageAsset: 'assets/wildberries.png',
                number: '1',
                name: 'WILDBERRIES',
                description:
                    'Доставка в любой склад \u201cWILDBERRIES\u201d в любом городе',
              ),
              SizedBox(height: 10.h),
              const _DeliveryCard(
                imageAsset: 'assets/ozon.png',
                number: '2',
                name: 'OZON',
                description:
                    'Доставка в любой склад \u201cOZON\u201d в любом городе',
              ),
              SizedBox(height: 10.h),
              const _DeliveryCard(
                imageAsset: 'assets/flags/flag_kz.png',
                imageWidth: 300,
                number: '3',
                name: 'OPTOMBAI KZ',
                description: 'Доставка в любой склад  в Казахстане',
              ),
              SizedBox(height: 10.h),
              const _DeliveryCard(
                imageAsset: 'assets/flags/flag_ru.png',
                imageWidth: 300,
                number: '4',
                name: 'OPTOMBAI RU',
                description: 'Доставка в любой склад  в России',
              ),
              const _DeliveryCard(
                imageAsset: 'assets/flags/flag_uz.png',
                imageWidth: 300,
                number: '5',
                name: 'OPTOMBAI UZ',
                description:
                    'Доставка в любой склад \u201cBazarlar\u201d в Узбекистана',
              ),
              SizedBox(height: 60.h),
              _SectionHeader(
                prefix: 'Как мы ',
                highlighted: 'работаем',
                isDarkMode: stateSwitch,
              ),
              SizedBox(height: 30.h),
              const _WorkStageCard(
                imageAsset: 'assets/fulfillment1.png',
                stageNumber: '1 этап',
                stageTitle: 'Приемка товара',
                description:
                    'Для оформления заказа свяжитесь с нами через мессенджеры или оставьте заявку на сайте. Мы заберем ваш товар от поставщика или швейного производства. При этом, вам необязательно находиться в Кыргызстане, Казахстане или Узбекистане!',
              ),
              SizedBox(height: 10.h),
              const _WorkStageCard(
                imageAsset: 'assets/fulfillment2.png',
                stageNumber: '2 этап',
                stageTitle: 'Проверка, упаковка и маркировка',
                description:
                    'По вашему техническому заданию и образцу мы проверяем товар на наличие брака и правильность упаковки. В случае обнаружения брака мы отправим фото- или видеоотчет. После этого товар маркируется, и наши сотрудники бережно упакуют его.',
              ),
              SizedBox(height: 10.h),
              const _WorkStageCard(
                imageAsset: 'assets/fulfillment.png',
                stageNumber: '3 этап',
                stageTitle: 'Готовность к отправке и доставка',
                description:
                    'После упаковки ваш товар готов к отправке. Финальный шаг — доставка! Мы подберем удобный для вас день отгрузки на склады маркетплейсов или в ваш город.',
                clipImage: true,
              ),
              SizedBox(height: 60.h),
            ],
          ),
        ),
      ),
    );
  }
}

class _WhatsAppFab extends StatelessWidget {
  const _WhatsAppFab();

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => _launchWeb(_whatsAppUrl),
      backgroundColor: Colors.green,
      label: const TextTranslated(
        "Связаться в WhatsApp",
        style: TextStyle(color: Colors.white),
      ),
      icon: Image.asset(
        "assets/icons/socials_dark/whatsapp_dark.png",
        width: 30.w,
      ),
    );
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
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
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const TextTranslated('', style: AppTextStyle.fulfillmentText2),
            const TextTranslated('Fulfillment',
                style: AppTextStyle.fulfillmentText),
            const TextTranslated(
              "Мы предлагаем полный цикл обработки ваших заказов, чтобы вы могли сосредоточиться на развитии бизнеса!",
              maxLines: 3,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset('assets/fulfillment.jpg'),
              ),
            ),
            const _HeroBannerButton(),
          ],
        ),
      ),
    );
  }
}

class _HeroBannerButton extends StatelessWidget {
  const _HeroBannerButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white, width: 2.w),
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        onPressed: () {},
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const TextTranslated(
              'Достаточно одного клика,\nчтобы начать!',
              style: TextStyle(color: Colors.white, fontSize: 15),
            ),
            Image.asset(
              'assets/fulfillment_icon.png',
              height: 24.0.h,
              width: 24.0.w,
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String? prefix;
  final String highlighted;
  final String? suffix;
  final bool isDarkMode;

  const _SectionHeader({
    this.prefix,
    required this.highlighted,
    this.suffix,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDarkMode ? Colors.white : Colors.black;

    return PaddingWidget(
      child: RichText(
        text: TextSpan(
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 28,
            color: textColor,
          ),
          children: [
            if (prefix != null) TextSpan(text: prefix),
            WidgetSpan(
              child: Transform(
                transform: Matrix4.skewY(-0.02),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4.0),
                  decoration: BoxDecoration(
                    color: const Color(0xffFFBF1B),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: TextTranslated(
                    highlighted,
                    style: AppTextStyle.fulfillmentMainText,
                  ),
                ),
              ),
            ),
            if (suffix != null) TextSpan(text: suffix),
          ],
        ),
      ),
    );
  }
}

class _HighlightedSectionHeader extends StatelessWidget {
  final String highlighted;
  final String suffix;
  final bool isDarkMode;

  const _HighlightedSectionHeader({
    required this.highlighted,
    required this.suffix,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDarkMode ? Colors.white : Colors.black;

    return PaddingWidget(
      child: RichText(
        text: TextSpan(
          style: AppTextStyle.fulfillmentMainText,
          children: [
            WidgetSpan(
              child: Transform(
                transform: Matrix4.skewY(-0.02),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4.0),
                  decoration: BoxDecoration(
                    color: const Color(0xffFFBF1B),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: TextTranslated(
                    highlighted,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 28,
                      color: textColor,
                    ),
                  ),
                ),
              ),
            ),
            TextSpan(
              text: suffix,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 28,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConvenienceCard extends StatelessWidget {
  const _ConvenienceCard();

  @override
  Widget build(BuildContext context) {
    return FulfillmentContainer(
      bottom: 20,
      right: 20,
      child1: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Image.asset(
                    'assets/icons/drawer_icons/icon_fulfillment1.png'),
              ),
              SizedBox(height: 30.h),
              const TextContainer(text: 'Удобство'),
              SizedBox(height: 5.h),
              const TextContainer(text: 'Безопасность сделок'),
            ],
          ),
          Transform(
            transform: Matrix4.skewY(0.2),
            child: const Center(
              child: Align(
                widthFactor: 3.4,
                heightFactor: 2.5,
                child: TextContainer(text: 'Качество товара'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final String imageAsset;
  final String title;
  final String description;

  const _ServiceCard({
    required this.imageAsset,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return FulfillmentContainer(
      bottom: 20,
      right: 20,
      child1: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ServiceCardImage(imageAsset: imageAsset),
          SizedBox(height: 25.h),
          TextTranslated(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 24),
          ),
          SizedBox(height: 10.h),
          TextTranslated(
            description,
            style: AppTextStyle.fulfillmentText3,
          ),
        ],
      ),
    );
  }
}

class _ServiceCardImage extends StatelessWidget {
  final String imageAsset;

  const _ServiceCardImage({required this.imageAsset});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 350.w,
      height: 165.h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            spreadRadius: 2,
            offset: Offset(2, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset(
          imageAsset,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

class _DeliveryCard extends StatelessWidget {
  final String imageAsset;
  final double? imageWidth;
  final String number;
  final String name;
  final String description;

  const _DeliveryCard({
    required this.imageAsset,
    this.imageWidth,
    required this.number,
    required this.name,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return FulfillmentContainer(
      bottom: 20,
      right: 20,
      child1: Column(
        children: [
          imageWidth != null
              ? Image.asset(imageAsset, width: imageWidth)
              : Image.asset(imageAsset),
          SizedBox(height: 15.h),
          TextWithNumber(textNumber: number, text: name),
          SizedBox(height: 15.h),
          TextTranslated(description, style: AppTextStyle.fulfillmentText3),
        ],
      ),
    );
  }
}

class _WorkStageCard extends StatelessWidget {
  final String imageAsset;
  final String stageNumber;
  final String stageTitle;
  final String description;
  final bool clipImage;

  const _WorkStageCard({
    required this.imageAsset,
    required this.stageNumber,
    required this.stageTitle,
    required this.description,
    this.clipImage = false,
  });

  @override
  Widget build(BuildContext context) {
    return FulfillmentContainer(
      bottom: 20,
      right: 20,
      child1: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          clipImage
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(imageAsset),
                )
              : Center(child: Image.asset(imageAsset)),
          TextWithNumber2(textNumber: stageNumber, text: stageTitle),
          SizedBox(height: 15.h),
          TextTranslated(description, style: AppTextStyle.fulfillmentText3),
        ],
      ),
    );
  }
}

class FulfillmentContainer extends StatelessWidget {
  const FulfillmentContainer({
    super.key,
    this.child1,
    this.image,
    required this.bottom,
    required this.right,
  });

  final Widget? child1;
  final String? image;
  final double bottom;
  final double right;

  @override
  Widget build(BuildContext context) {
    final stateSwitch = context.select((ThemeNotifier n) => n.isDarkMode);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: EdgeInsets.only(top: 20, bottom: bottom, right: right, left: 20),
      decoration: BoxDecoration(
          color:
              stateSwitch ? const Color(0xff293244) : const Color(0xffF5FAFF),
          borderRadius: BorderRadius.circular(30)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
            child: child1,
          ),
        ],
      ),
    );
  }
}

class TextContainer extends StatelessWidget {
  const TextContainer({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final stateSwitch = context.select((ThemeNotifier n) => n.isDarkMode);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(50),
        color: Colors.transparent,
        border: Border.all(
          color: stateSwitch ? Colors.white : Colors.black,
          width: 1.w,
        ),
      ),
      child: TextTranslated(
        text,
        style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: stateSwitch ? Colors.white : Colors.black),
      ),
    );
  }
}

class TextFulfilment extends StatelessWidget {
  const TextFulfilment({
    super.key,
    required this.image,
    required this.title,
    required this.subtitle,
  });

  final String image;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(15),
          decoration: const BoxDecoration(
            color: Color(0xffE9E9E9),
            shape: BoxShape.circle,
          ),
          child: Image.asset(image),
        ),
        SizedBox(width: 10.w),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextTranslated(
              title,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
            ),
            SizedBox(height: 3.h),
            TextTranslated(
              subtitle,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ],
    );
  }
}

class TextWithNumber extends StatelessWidget {
  const TextWithNumber({
    super.key,
    required this.textNumber,
    required this.text,
  });

  final String textNumber;
  final String text;

  @override
  Widget build(BuildContext context) {
    final stateSwitch = context.select((ThemeNotifier n) => n.isDarkMode);

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(
              color: stateSwitch ? Colors.white : Colors.black,
              width: 1.w,
            ),
          ),
          child: TextTranslated(
            textNumber,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
        ),
        SizedBox(width: 10.w),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(50),
            color: Colors.transparent,
            border: Border.all(
              color: stateSwitch ? Colors.white : Colors.black,
              width: 1.w,
            ),
          ),
          child: TextTranslated(
            text,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
        ),
      ],
    );
  }
}

class TextWithNumber2 extends StatelessWidget {
  const TextWithNumber2({
    super.key,
    required this.textNumber,
    required this.text,
  });

  final String textNumber;
  final String text;

  @override
  Widget build(BuildContext context) {
    final stateSwitch = context.select((ThemeNotifier n) => n.isDarkMode);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(40),
            color: Colors.transparent,
            border: Border.all(
              color: stateSwitch ? Colors.white : Colors.black,
              width: 1.w,
            ),
          ),
          child: TextTranslated(
            textNumber,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
        ),
        SizedBox(height: 10.h),
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(40),
            color: Colors.transparent,
            border: Border.all(
              color: stateSwitch ? Colors.white : Colors.black,
              width: 1.w,
            ),
          ),
          child: TextTranslated(
            text,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
        ),
      ],
    );
  }
}
