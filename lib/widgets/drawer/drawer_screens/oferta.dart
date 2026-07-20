import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:optombai/core/import_links.dart';
import 'package:auto_route/auto_route.dart';
import 'package:optombai/widgets/translation/text_translated.dart';

@RoutePage()
class OfertaScreen extends StatelessWidget {
  const OfertaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      title: "Публичная оферта",
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Divider(),
              SizedBox(height: 20.h),
              const TextTranslated(
                'Публичная оферта для мобильного приложения',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 20.h),
              const TextTranslated(
                '1. Общие положения',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 5.h),
              const TextTranslated(
                '1.1. Настоящая публичная оферта (далее — «Оферта») является официальным предложением ИП Элдияр Орманбаев (далее — «Компания») для физических и юридических лиц (далее — «Пользователь») заключить договор на условиях, изложенных в данном документе.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 5.h),
              const TextTranslated(
                '1.2. Регистрация в мобильном приложении и использование его функций является акцептом данной Оферты.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 10.h),
              const Divider(),
              SizedBox(height: 20.h),
              const TextTranslated(
                '2. Предмет договора',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 7.h),
              const TextTranslated(
                '2.1. Компания предоставляет Пользователю доступ к мобильному приложению, включающему:',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 5.h),
              const TextTranslated(
                '• Каталог производителей и поставщиков одежды;',
                style: TextStyle(fontSize: 16),
              ),
              const TextTranslated(
                '• Возможность размещения и поиска заказов.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 10.h),
              const Divider(),
              SizedBox(height: 20.h),
              const TextTranslated(
                '3. Условия использования',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 7.h),
              const TextTranslated(
                '3.1. Доступ к основным функциям мобильного приложения предоставляется бесплатно для всех пользователей.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 10.h),
              const Divider(),
              SizedBox(height: 20.h),
              const TextTranslated(
                '4. Обязанности сторон',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 7.h),
              const TextTranslated(
                '4.1. Обязанности Компании:',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 5.h),
              const TextTranslated(
                '• Обеспечить непрерывный доступ к мобильному приложению;',
                style: TextStyle(fontSize: 16),
              ),
              const TextTranslated(
                '• Предоставить достоверную информацию о доступных заказах.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 5.h),
              const TextTranslated(
                '4.2. Обязанности Пользователя:',
                style: TextStyle(fontSize: 16),
              ),
              const TextTranslated(
                '• Предоставить актуальные и достоверные данные при регистрации;',
                style: TextStyle(fontSize: 16),
              ),
              const TextTranslated(
                '• Использовать мобильное приложение исключительно в законных целях.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 10.h),
              const Divider(),
              SizedBox(height: 20.h),
              const TextTranslated(
                '5. Стоимость и порядок расчетов',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 7.h),
              const TextTranslated(
                '5.1. Мобильное приложение доступно бесплатно, и не требуется обязательная оплата для использования его основных функций.',
                style: TextStyle(fontSize: 16),
              ),
              const TextTranslated(
                '5.2. Доступ к дополнительным функциям может предоставляться на основе отдельных условий, которые будут определены в будущем.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 10.h),
              const Divider(),
              SizedBox(height: 20.h),
              const TextTranslated(
                '6. Ограничение ответственности',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 7.h),
              const TextTranslated(
                '6.1. Компания не несет ответственности за:',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 5.h),
              const TextTranslated(
                '• Ошибки или неточности в данных, предоставленных Пользователями;',
                style: TextStyle(fontSize: 16),
              ),
              const TextTranslated(
                '• Прерывания работы мобильного приложения, вызванные техническими неполадками.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 10.h),
              const Divider(),
              SizedBox(height: 20.h),
              const TextTranslated(
                '7. Заключительные положения',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 7.h),
              const TextTranslated(
                '7.1. Настоящая Оферта вступает в силу с момента ее публикации в мобильном приложении.',
                style: TextStyle(fontSize: 16),
              ),
              const TextTranslated(
                '7.2. Все споры, возникающие в рамках исполнения условий Оферты, решаются путем переговоров, а при невозможности достижения соглашения — в судебном порядке по месту регистрации ИП Элдияр Орманбаев.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 20.h),
              const Divider(),
              SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
    );
  }
}
