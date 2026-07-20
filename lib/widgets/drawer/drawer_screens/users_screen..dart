import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:optombai/bloc/question_bloc/question_bloc.dart';
import 'package:optombai/data/models/question/question_model.dart';
import 'package:optombai/widgets/bottom_nav.dart';

import 'package:optombai/core/import_links.dart';
import 'package:optombai/widgets/profile/verified_badge.dart';
import 'package:optombai/widgets/translation/text_translated.dart';
import 'package:optombai/widgets/utils/fields/custom_text_field.dart';

import 'package:optombai/widgets/drawer/drawer_screens/about_us.dart';
import 'package:optombai/widgets/drawer/drawer_screens/fulfilment_screen.dart';
import 'package:auto_route/auto_route.dart';

@RoutePage()
class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  late User _user;
  late QuestionBloc questionBloc;
  final TextEditingController adminQueryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    adminQueryController.addListener(_onQueryChanged);
    Future.microtask(() {
      if (mounted) {
        setState(() {
          questionBloc = context.read<QuestionBloc>();
          _user = context.read<UserBloc>().state.user;
        });
      }
    });
  }

  void _onQueryChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    adminQueryController.removeListener(_onQueryChanged);
    adminQueryController.dispose();
    super.dispose();
  }

  void _sendRequest() {
    if (adminQueryController.text.isNotEmpty) {
      final question = QuestionModel(
        question: adminQueryController.text,
        name: _user.username,
        email: _user.email,
        phoneNumber: _user.phone_number,
      );
      questionBloc.add(QuestionCreateEvent(question: question));
    } else {
      debugPrint('Text is empty');
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isRegister = context.select((ThemeNotifier n) => n.isRegister);
    bool stateSwitch = context.select((ThemeNotifier n) => n.isDarkMode);

    return CustomScaffold(
        bottomNavigationBar: const BottomNav(
          currentIndexOverride: -1,
          passive: true,
        ),
        title: 'Пользователям',
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
                      Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 24),
                        decoration: BoxDecoration(
                          color: stateSwitch
                              ? const Color(0xff061324)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextTranslated(
                              'Как получить статус «Проверен»',
                              textAlign: TextAlign.start,
                              style: TextStyle(
                                fontSize: 25,
                                fontWeight: FontWeight.w800,
                                height: 1.2,
                                color:
                                    !stateSwitch ? Colors.black : Colors.white,
                              ),
                            ),
                            SizedBox(height: 30.h),
                            Center(
                              child: Transform.scale(
                                scale: 2.2,
                                child: const VerifiedBadge(),
                              ),
                            ),
                            SizedBox(height: 34.h),
                            TextTranslated(
                              'Для подтверждения вашего аккаунта и повышения безопасности, '
                              'мы рекомендуем отправить фотографии ваших документов вашей компании на нашу почту:',
                              textAlign: TextAlign.start,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                height: 1.5,
                                color:
                                    !stateSwitch ? Colors.black : Colors.white,
                              ),
                            ),
                            SizedBox(height: 20.h),
                            Center(
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Image.asset(
                                      'assets/icons/drawer_icons/union.png'),
                                  const Align(
                                    alignment: Alignment.center,
                                    child: TextWithFrame(
                                      text: 'optombai.inc@gmail.com',
                                      fontSize: 22,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 20.h),
                            TextTranslated(
                              'с текстом "Подтверждение аккаунта". Это поможет нам подтвердить вашу личность '
                              'и обеспечить безопасность всех участников нашей платформы.\n\n'
                              'После подтверждения ваше предприятие получит статус "Проверено".',
                              textAlign: TextAlign.start,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                height: 1.5,
                                color:
                                    !stateSwitch ? Colors.black : Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 24),
                        decoration: BoxDecoration(
                          color: stateSwitch
                              ? const Color(0xff061324)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextTranslated(
                              'Как получить статус "Качество"',
                              style: TextStyle(
                                fontSize: 25,
                                fontWeight: FontWeight.w800,
                                height: 1.2,
                                color:
                                    !stateSwitch ? Colors.black : Colors.white,
                              ),
                            ),
                            SizedBox(height: 20.h),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(
                                  'assets/gold/gold.png',
                                  width: 77.w,
                                  height: 77.w,
                                ),
                                SizedBox(width: 10.w),
                                Image.asset(
                                  'assets/gold/silver.png',
                                  width: 77.w,
                                  height: 77.w,
                                ),
                                SizedBox(width: 10.w),
                                Image.asset(
                                  'assets/gold/bronze.png',
                                  width: 77.w,
                                  height: 77.w,
                                ),
                              ],
                            ),
                            SizedBox(height: 24.h),
                            TextTranslated(
                              'Если вы производитель, пригласите нашего специалиста технического отдела для подтверждения качества вашей продукции во время производственного процесса.\n\n'
                              'Если вы поставщик, чтобы получить статус качества, необходимо пригласить специалиста на ваше торговое место — будь то контейнер, базар, торговый центр или магазин.\n\n'
                              'После проверки и утверждения качества вашему предприятию будет присвоен соответствующий статус качества.',
                              textAlign: TextAlign.start,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                height: 1.5,
                                color:
                                    !stateSwitch ? Colors.black : Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20.h),
                      const CustomContainer(
                        text1: 'Пользователям',
                        text3:
                            'Добро пожаловать в мир безопасных и качественных сделок!',
                      ),
                      SizedBox(
                        height: 20.h,
                      ),
                      FulfillmentContainer(
                        right: 0,
                        bottom: 0,
                        child1:
                            Stack(alignment: Alignment.bottomRight, children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.only(
                                bottomRight: Radius.circular(30)),
                            child: Image.asset(
                              'assets/icons/drawer_icons/globus.png',
                              fit: BoxFit.fill,
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const TextTranslated(
                                'Уважаемые\nпользователи платформы',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.w600),
                              ),
                              const TextWithFrame(
                                text: 'OPTOMBAI',
                                fontSize: 28,
                              ),
                              SizedBox(
                                height: 60.h,
                              ),
                              const Padding(
                                padding: EdgeInsets.only(right: 20),
                                child: TextTranslated(
                                  'На нашей платформе мы постоянно обновляем список возможностей для вас. Не упускайте шанс развиваться вместе с нами, ведь здесь вы можете найти себе будущих партнеров для успеха, совершать сделки, находить качественных поставщиков и производителей, а также продвигать свои продукты на зарубежные рынки. ',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500),
                                ),
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
                        child1: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Image.asset(
                                'assets/icons/drawer_icons/user.png')),
                      ),
                      SizedBox(
                        height: 40.h,
                      ),
                      PaddingWidget(
                          child: Column(
                        children: [
                          const TextTranslated(
                            'Мы хотим подчеркнуть, что',
                            style: TextStyle(
                                fontSize: 24, fontWeight: FontWeight.w600),
                          ),
                          const TextWithFrame(
                            text: 'ваше доверие - это для нас приоритет. ',
                            fontSize: 28,
                          ),
                          SizedBox(
                            height: 30.h,
                          ),
                          const TextTranslated(
                            'Мы ценим каждого участника нашего сообщества и делаем все возможное, чтобы обеспечить вашу максимальную защиту от мошенников.',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        ],
                      )),
                      SizedBox(
                        height: 60.h,
                      ),
                      const ContainerWithoutPadding(
                        text:
                            'Чтобы обезопасить себя от мошенников и проводить качественные и безопасные сделки, мы рекомендуем воспользоваться нашим сервисом  Fulfillment. ',
                      ),
                      SizedBox(
                        height: 20.h,
                      ),
                      FulfillmentContainer(
                        right: 0,
                        bottom: 0,
                        child1: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const BorderText(text: 'Поддержка'),
                                SizedBox(width: 10.w),
                                const BorderText(text: 'Защита'),
                              ],
                            ),
                            SizedBox(
                              height: 30.h,
                            ),
                            const TextTranslated(
                              '🔐',
                              style: TextStyle(fontSize: 50),
                            ),
                            SizedBox(
                              height: 15.h,
                            ),
                            const TextTranslated(
                              'Наш сервис предоставляет полную поддержку и защиту при проведении торговых операций, обеспечивая вам комфорт и уверенность в каждой сделке.',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                            SizedBox(
                              height: 25.h,
                            ),
                            Center(
                                child: Image.asset(
                                    'assets/icons/drawer_icons/korobka.png'))
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 60.h,
                      ),
                      SizedBox(
                        height: 40.h,
                      ),
                      Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                            color: const Color(0xff63BDFF),
                            borderRadius: BorderRadius.circular(30)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 0, vertical: 0),
                              child: Column(
                                children: [
                                  const TextTranslated(
                                    'Присоединяйтесь к нам сегодня',
                                    style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white),
                                  ),
                                  const TextTranslated(
                                    'и наслаждайтесь безопасными \nи выгодными сделками на !',
                                    style: TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white),
                                  ),
                                  SizedBox(
                                    height: 30.h,
                                  ),
                                  Image.asset(
                                      'assets/icons/drawer_icons/plus.png'),
                                  SizedBox(
                                    height: 60.h,
                                  ),
                                  const TextTranslated(
                                    'С уважением, команда  ❤️',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white),
                                  ),
                                  SizedBox(
                                    height: 10.h,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 20.h,
                      ),
                      if (isRegister)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: CustomButton(
                            title: 'Сообщить о проблеме',
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return BlocConsumer<QuestionBloc,
                                      QuestionState>(
                                    listener: (context, state) {
                                      if (state.isSuccess) {
                                        Navigator.pop(context);
                                        adminQueryController.clear();
                                        showMessage(
                                          context,
                                          ["Обращение успешно отправлено"],
                                          EnumStatusMessage.success,
                                        );
                                      } else if (state.errors.isNotEmpty) {
                                        Navigator.pop(context);
                                        showMessage(
                                          context,
                                          state.errors,
                                          EnumStatusMessage.error,
                                        );
                                      }
                                    },
                                    builder: (context, state) {
                                      return Dialog(
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(20),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const TextTranslated(
                                                'Обращение к администратору',
                                                style: AppTextStyle
                                                    .alertDialogText,
                                              ),
                                              SizedBox(height: 12.h),
                                              CustomTextField(
                                                inputFormatters: 300,
                                                controller:
                                                    adminQueryController,
                                                onChanged: (val) =>
                                                    setState(() {}),
                                                title: 'Опишите вашу проблему',
                                              ),
                                              SizedBox(height: 12.h),
                                              CustomButton(
                                                title: 'Отправить',
                                                onPressed: _sendRequest,
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      SizedBox(height: 70.h),
                    ]))));
  }
}
