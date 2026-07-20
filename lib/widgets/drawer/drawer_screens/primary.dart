import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:optombai/core/import_links.dart';
import 'package:auto_route/auto_route.dart';
import 'package:optombai/widgets/translation/text_translated.dart';

@RoutePage()
class PrimaryScreen extends StatefulWidget {
  const PrimaryScreen({super.key});

  @override
  State<PrimaryScreen> createState() => _PrimaryScreenState();
}

class _PrimaryScreenState extends State<PrimaryScreen> {
  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      title: 'Пользовательское соглашение',
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const TextTranslated(
                'Пользовательское соглашение приложения ',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 5.h),
              const TextTranslated(
                'ИП Элдияр Орманбаев, именуемый в дальнейшем "Администрация", предлагает пользователю (далее — "Пользователь") воспользоваться услугами приложения  (далее — "Приложение") на условиях настоящего Пользовательского соглашения (далее — "Соглашение"). Регистрация и использование Приложения означают полное согласие Пользователя с условиями Соглашения.',
                style: TextStyle(fontSize: 15),
              ),
              SizedBox(height: 20.h),
              const Divider(),
              SizedBox(height: 20.h),
              const TextTranslated(
                '1. Термины и определения',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 5.h),
              const RichTextFor(
                text1: '1. Приложение ',
                text2:
                    '- мобильная или веб-платформа , предоставляющая Пользователям доступ к каталогу производителей, поставщиков и заказчиков одежды.',
              ),
              SizedBox(height: 5.h),
              const RichTextFor(
                text1: '2. Пользователь',
                text2:
                    '– любое физическое или юридическое лицо, зарегистрированное на Приложении.',
              ),
              SizedBox(height: 5.h),
              const RichTextFor(
                text1: '3. Контакты заказов',
                text2:
                    '– информация о производителях, поставщиках и заказчиках, доступна активированным пользователям.',
              ),
              SizedBox(height: 5.h),
              const RichTextFor(
                text1: '4. Администрация ',
                text2:
                    '- ИП Элдияр Орманбаев, осуществляющий управление и поддержку работы Приложения.',
              ),
              SizedBox(
                height: 10.h,
              ),
              const Divider(),
              SizedBox(height: 20.h),
              const TextTranslated(
                '2. Предмет соглашения',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 5.h),
              const TextTranslated(
                '1. Настоящее Соглашение регулирует порядок использования Приложения, права и обязанности Пользователей и Администрации, а также условия предоставления услуг.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 5.h),
              const TextTranslated(
                '2. Все условия Соглашения являются обязательными для Пользователя.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 10.h),
              const Divider(),
              SizedBox(height: 20.h),
              const TextTranslated(
                '3. Регистрация на Приложении',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 5.h),
              const TextTranslated(
                '1. Для получения доступа к функционалу Приложения Пользователь должен пройти процедуру регистрации, указав достоверные данные.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 5.h),
              const TextTranslated(
                '2. Пользователь несет ответственность за точность предоставленной информации.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 5.h),
              const TextTranslated(
                '3. Администрация вправе отказать в регистрации или удалить учетную запись при нарушении Пользователем условий Соглашения.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 10.h),
              const Divider(),
              SizedBox(height: 20.h),
              const TextTranslated(
                '4.  Условия использования Приложения',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 5.h),
              const TextTranslated(
                '1. Пользователь обязуется использовать Приложение исключительно в законных целях и не предпринимать действий, которые могут нарушить его работу.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 5.h),
              const TextTranslated(
                '2. Запрещается:',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 5.h),
              const TextTranslated(
                '● Использовать Приложение для мошенничества, спама или других незаконных действий;',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 5.h),
              const TextTranslated(
                '● Распространять вирусы или вредоносное ПО;',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 5.h),
              const TextTranslated(
                '● Передавать свои учетные данные третьим лицам.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 10.h),
              const Divider(),
              SizedBox(height: 20.h),
              const TextTranslated(
                '5. Расширенные возможности',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 5.h),
              const TextTranslated(
                '1. Расширенные функции, включая открытие контактов заказов без ограничений, могут предоставляться при соблюдении внутренних условий использования.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 5.h),
              const TextTranslated(
                '2. Стоимость и условия расширенных возможностей указаны в Приложении и могут быть изменены Администрацией с уведомлением Пользователя.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 5.h),
              const TextTranslated(
                '3. Активация расширенного доступа означает полное согласие Пользователя с условиями данного Соглашения',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 10.h),
              const Divider(),
              SizedBox(height: 20.h),
              const TextTranslated(
                '6. Права и обязанности сторон',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 5.h),
              const TextTranslated(
                '1. Права Пользователя:',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 5.h),
              const TextTranslated(
                '● Использовать Приложение в соответствии с его функциональными возможностями и условиями активации доступа;',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 5.h),
              const TextTranslated(
                '● Требовать от Администрации обеспечения доступа к Приложению при выполнении условий Соглашения;',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 5.h),
              const TextTranslated(
                '● Удалить свою учетную запись и запросить удаление данных.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 10.h),
              const TextTranslated(
                '2. Обязанности Пользователя:',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 5.h),
              const TextTranslated(
                '● Предоставлять достоверные данные при регистрации;',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 5.h),
              const TextTranslated(
                '● Своевременно активировать доступ к дополнительным возможностям;',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 5.h),
              const TextTranslated(
                '● Не нарушать условия Соглашения и законодательство Кыргызской Республики.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 5.h),
              const TextTranslated(
                '3. Права Администрации:',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 5.h),
              const TextTranslated(
                '● Вносить изменения в функционал Приложения, планы активации и условия Соглашения;',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 5.h),
              const TextTranslated(
                '● Блокировать учетные записи Пользователей при нарушении условий Соглашения;',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 5.h),
              const TextTranslated(
                '● Приостанавливать работу Приложения для проведения технических работ',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 10.h),
              const TextTranslated(
                '4. Обязанности Администрации:',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 5.h),
              const TextTranslated(
                '● Обеспечивать доступ Пользователей к Приложению при выполнении условий Соглашения;',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 5.h),
              const TextTranslated(
                '● Защищать персональные данные Пользователей в соответствии с Политикой конфиденциальности.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 10.h),
              const Divider(),
              SizedBox(height: 20.h),
              const TextTranslated(
                '7. Ограничение ответственности',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 5.h),
              const TextTranslated(
                '1. Администрация не несет ответственности за',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 5.h),
              const TextTranslated(
                '● Ошибки или неточности, допущенные Пользователем при использовании Приложения;',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 5.h),
              const TextTranslated(
                '● Прерывания в работе Приложения, вызванные техническими неполадками или действиями третьих лиц;',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 5.h),
              const TextTranslated(
                '● Ущерб, причиненный Пользователю в результате использования Приложения.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 5.h),
              const TextTranslated(
                '2. Пользователь несет полную ответственность за свои действия в Приложении и возможные последствия.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 10.h),
              const Divider(),
              SizedBox(height: 20.h),
              const TextTranslated(
                '8. Конфиденциальность',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 5.h),
              const TextTranslated(
                '1. Персональные данные Пользователей обрабатываются в соответствии с Политикой конфиденциальности, опубликованной в Приложении.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 5.h),
              const TextTranslated(
                '2. Пользователь соглашается на обработку персональных данных для целей, предусмотренных Соглашением.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 10.h),
              const Divider(),
              SizedBox(height: 20.h),
              const TextTranslated(
                '9. Изменения и прекращение действия Соглашения',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 5.h),
              const TextTranslated(
                '1. Персональные данные Пользователей обрабатываются в соответствии с Политикой конфиденциальности, опубликованной в Приложении.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 5.h),
              const TextTranslated(
                '2. Пользователь соглашается на обработку персональных данных для целей, предусмотренных Соглашением.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 5.h),
              const TextTranslated(
                '3. Пользователь вправе прекратить использование Приложения и удалить свою учетную запись в любое время.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 10.h),
              const Divider(),
              SizedBox(height: 20.h),
              const TextTranslated(
                '10. Заключительные положения',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 5.h),
              const TextTranslated(
                '1. Настоящее Соглашение регулируется законодательством Кыргызской Республики.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 5.h),
              const TextTranslated(
                '2. Все споры и разногласия, возникающие в рамках исполнения Соглашения, разрешаются путем переговоров. При невозможности достижения соглашения спор передается на рассмотрение суда по месту регистрации Администрации.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 5.h),
              const TextTranslated(
                '3. Если любое из положений Соглашения будет признано недействительным, остальные положения сохраняют свою силу',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 10.h),
            ],
          ),
        ),
      ),
    );
  }
}

class RichTextFor extends StatelessWidget {
  const RichTextFor({super.key, required this.text1, required this.text2});

  final String text1;
  final String text2;

  @override
  Widget build(BuildContext context) {
    bool stateSwitch = context.select((ThemeNotifier n) => n.isDarkMode);

    return RichText(
      text: TextSpan(
          text: text1,
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: stateSwitch ? Colors.white : Colors.black),
          children: <TextSpan>[
            TextSpan(
              text: text2,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w300,
                  color: stateSwitch ? Colors.white : Colors.black),
            )
          ]),
    );
  }
}
