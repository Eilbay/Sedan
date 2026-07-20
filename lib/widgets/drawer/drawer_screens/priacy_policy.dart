import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:optombai/core/import_links.dart';
import 'package:auto_route/auto_route.dart';
import 'package:optombai/widgets/translation/text_translated.dart';

@RoutePage()
class PoliticsScreen extends StatefulWidget {
  const PoliticsScreen({super.key});

  @override
  State<PoliticsScreen> createState() => _PoliticsScreenState();
}

class _PoliticsScreenState extends State<PoliticsScreen> {
  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      title: 'Политика конфиденциальности',
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 15.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const TextTranslated(
              'Политика конфиденциальности мобильного приложения ',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 20.h),
            _sectionTitle('1. Общие положения'),
            _sectionText(
                '1.1. Настоящая Политика конфиденциальности (далее — «Политика») регулирует сбор, обработку и защиту персональных данных пользователей мобильного приложения  (далее — «Приложение»).'),
            _sectionText(
                '1.2. Обработка персональных данных осуществляется ИП Элдияр Орманбаев (далее — «Компания») в соответствии с законодательством Кыргызской Республики.'),
            _sectionText(
                '1.3. Устанавливая и используя Приложение, пользователь подтверждает, что ознакомился с Политикой и даёт согласие на обработку своих персональных данных.'),
            _sectionTitle('2. Сбор и обработка персональных данных'),
            _sectionText(
                '2.1. Компания собирает следующие категории персональных данных:'),
            _sectionBullet('Полное имя'),
            _sectionBullet('Контактный номер телефона'),
            _sectionBullet('Адрес электронной почты'),
            _sectionBullet(
                'Данные, указанные при регистрации и использовании Приложения'),
            _sectionBullet(
                'Иные данные, предоставленные пользователем при использовании Приложения'),
            _sectionText(
                '2.2. Информация, размещённая пользователем в каталоге (например, контактные данные, описание компании или товаров), становится публичной и доступной для всех пользователей Приложения. Пользователь несёт ответственность за содержание и достоверность этой информации.'),
            _sectionTitle('3. Цели обработки персональных данных'),
            _sectionText('3.1. Персональные данные используются для:'),
            _sectionBullet(
                'Регистрации и авторизации пользователя в Приложении'),
            _sectionBullet(
                'Предоставления доступа к функциям и сервисам Приложения'),
            _sectionBullet('Связи с пользователем для обслуживания'),
            _sectionBullet('Отображения подходящих заказов и поставщиков'),
            _sectionBullet('Проведения аналитики и улучшения сервиса'),
            _sectionText(
                '3.2. Данные из каталога используются для отображения и распространения среди других пользователей.'),
            _sectionTitle('4. Передача данных третьим лицам'),
            _sectionText(
                '4.1. Персональные данные передаются третьим лицам только в следующих случаях:'),
            _sectionBullet(
                'Для выполнения обязательств Компании перед пользователем (например, предоставление информации о заказах или поставщиках)'),
            _sectionBullet(
                'По требованию уполномоченных государственных органов в рамках законодательства Кыргызской Республики'),
            _sectionText(
                '4.2. При использовании функции “Связаться в WhatsApp” на странице “Фулфилмент” ваш номер телефона и данные заказа (например, описание товара) передаются фулфилмент-сервису (например, “ Fulfilment”) для личной проверки и координации доставки. История сообщений в WhatsApp не сохраняется. Обработка данных в WhatsApp регулируется Политикой конфиденциальности WhatsApp: https://www.whatsapp.com/privacy.'),
            _sectionTitle('5. Безопасность и хранение данных'),
            _sectionText(
                '5.1. Компания применяет современные технические и организационные меры для защиты персональных данных от утраты, несанкционированного доступа, изменения или раскрытия.'),
            _sectionText(
                '5.2. Данные хранятся только на период, необходимый для достижения целей, указанных в Политике, после чего удаляются.'),
            _sectionTitle('6. Права пользователей'),
            _sectionText('6.1. Пользователь имеет право:'),
            _sectionBullet('Запросить информацию о своих персональных данных'),
            _sectionBullet(
                'Требовать исправления, обновления или удаления данных'),
            _sectionBullet(
                'Отозвать согласие на обработку (это может ограничить доступ к функциям Приложения)'),
            _sectionTitle('7. Изменения в Политике'),
            _sectionText(
                '7.1. Компания вправе вносить изменения в Политику. Актуальная версия публикуется в Приложении и/или на сайте Optombai.com. О значимых изменениях пользователи будут уведомлены.'),
            SizedBox(height: 30.h),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: EdgeInsets.only(top: 15.h, bottom: 5.h),
      child: TextTranslated(
        text,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _sectionText(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: TextTranslated(
        text,
        style: const TextStyle(fontSize: 16),
      ),
    );
  }

  Widget _sectionBullet(String text) {
    return Padding(
      padding: EdgeInsets.only(left: 10.w, bottom: 4.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TextTranslated('• ', style: TextStyle(fontSize: 16)),
          Expanded(
            child: TextTranslated(text, style: const TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }
}
