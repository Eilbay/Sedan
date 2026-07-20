import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:optombai/bloc/auth_bloc/auth_cubit.dart';
import 'package:optombai/widgets/auth/otp_code_field.dart';
import 'package:optombai/bloc/auth_bloc/auth_state.dart';
import 'package:optombai/core/theme_notifier.dart';
import 'package:optombai/widgets/translation/text_translated.dart';
import 'package:optombai/widgets/translation/textspan_translated.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:optombai/configs/app_color.dart';
import 'package:optombai/configs/app_style.dart';
import 'package:optombai/configs/constrants.dart';
import 'package:optombai/app/router/app_router.dart';
import 'package:optombai/core/di/injection.dart';
import 'package:optombai/widgets/utils/buttons/custom_button.dart';
import 'package:optombai/widgets/utils/fields/custom_text_field.dart';
import 'package:optombai/widgets/utils/message_show.dart';
import 'package:optombai/widgets/utils/fields/custom_phone_number_field.dart';
import 'package:optombai/data/models/region/kg_region.dart';
import 'package:optombai/widgets/region/region_picker_sheet.dart';
import 'package:auto_route/auto_route.dart';
import 'package:shared_preferences/shared_preferences.dart';

@RoutePage(name: 'SignUpRoute')
class SignUp extends StatefulWidget {
  const SignUp({super.key});
  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController passwordControllerSecond =
      TextEditingController();
  final TextEditingController phoneNumberController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    passwordController.dispose();
    passwordControllerSecond.dispose();
    phoneNumberController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  final _formKey = GlobalKey<FormState>();
  final ScrollController _scrollController = ScrollController();

  int _currentIndex = 1;
  String token = '';
  String username = '';
  String password = '';
  String number = '';
  KgRegion? region;
  bool showRegionError = false;
  bool _onEditing = false;

  bool passenable = true;
  bool passenable2 = true;
  bool checkBox = false;
  bool showCheckboxError = false;

  bool isPasswordValid(String password) =>
      RegExp(r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]{8,}$').hasMatch(password);

  void scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final stateSwitch = context.select((ThemeNotifier n) => n.isDarkMode);

    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: BorderSide.strokeAlignCenter,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            context.router.push(const SignInRoute());
          },
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (ctx, state) {
          if (state is RegistrationPendingCode) {
            setState(() => _currentIndex = 3);
          } else if (state is LoginStateSuccess) {
            ctx.read<AuthCubit>().preferences.remove('referral_code');

            ctx.read<ThemeNotifier>().setRegistrationStatus(true);
            if (ctx.router.canPop()) {
              debugPrint('[AUTH] SignUp pop back to previous route');
              ctx.router.pop();
            } else {
              final prefs = getIt<SharedPreferences>();
              final lastTab = prefs.getInt(LAST_BOTTOM_TAB_KEY) ?? 0;
              debugPrint(
                '[AUTH] SignUp fallback replaceAll -> '
                'BottomNavRoute(initialIndex=$lastTab)',
              );
              ctx.router.replaceAll([
                BottomNavRoute(initialIndex: lastTab),
              ]);
            }
          } else if (state is AuthStateInvalidCode) {
            setState(() {
              token = '';
            });
            showMessage(context, ["Код неверный, попробуйте ещё раз"],
                EnumStatusMessage.error);
          } else if (state is AuthStateError) {
            final msg = state.list.isNotEmpty ? state.list.first : 'Ошибка';

            final lower = msg.toLowerCase();
            final isCodeError = lower.contains('код') ||
                lower.contains('otp') ||
                lower.contains('invalid') ||
                lower.contains('неверн') ||
                lower.contains('неправил');
            if (isCodeError) {
              setState(() {
                token = '';
              });
            }
            //showMessage(ctx, state.list, EnumStatusMessage.error);
          }
        },
        builder: (ctx, state) {
          final isLoading = state is AuthLoading;

          return Form(
            key: _formKey,
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Padding(
                padding: const EdgeInsets.only(
                  right: 20,
                  left: 30,
                  top: 30,
                  bottom: 30,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image(
                          image: AssetImage(stateSwitch
                              ? 'assets/logo_mini_dark.png'
                              : 'assets/logo_mini.png'),
                          width: 32.w,
                          height: 32.h,
                        ),
                        SizedBox(width: 3.w),
                        const Text(
                          "Китайдан",
                          style: TextStyle(
                            fontFamily: 'Marmelad',
                            fontWeight: FontWeight.w400,
                            fontSize: 22,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 15.h),
                    const TextTranslated(
                      "Добро пожаловать!",
                      style: AppTextStyle.welcomeTextStyle,
                    ),
                    Builder(
                      builder: (_) {
                        if (_currentIndex != 1) return const SizedBox.shrink();

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const TextTranslated(
                              "Логин",
                              style: AppTextStyle.textAuthStyle,
                            ),
                            SizedBox(height: 5.h),
                            CustomTextField(
                              errorText: 'Логин',
                              maxLines: 1,
                              isAuthName: true,
                              inputFormatters: 30,
                              obscureText: false,
                              controller: nameController,
                              textInputType: TextInputType.text,
                              title: "Латинские буквы, цифры и _",
                              onChanged: (value) =>
                                  setState(() => username = value),
                            ),
                            SizedBox(height: 15.h),
                            const TextTranslated(
                              "Пароль",
                              style: AppTextStyle.textAuthStyle,
                            ),
                            SizedBox(height: 5.h),
                            CustomTextField(
                              isPassword: true,
                              errorText: 'Пароль',
                              inputFormatters: 30,
                              maxLines: 1,
                              obscureText: passenable,
                              controller: passwordController,
                              onChanged: (_) {},
                              textInputType: TextInputType.visiblePassword,
                              title: "Введите ваш пароль",
                              icon: passenable
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              onPressed: () =>
                                  setState(() => passenable = !passenable),
                            ),
                            SizedBox(height: 15.h),
                            const TextTranslated(
                              "Повторите ваш пароль",
                              style: AppTextStyle.textAuthStyle,
                            ),
                            SizedBox(height: 5.h),
                            CustomTextField(
                              isPassword: true,
                              errorText: 'Повторите ваш пароль',
                              maxLines: 1,
                              obscureText: passenable2,
                              inputFormatters: 30,
                              controller: passwordControllerSecond,
                              onChanged: (_) {},
                              textInputType: TextInputType.visiblePassword,
                              title: "Введите ваш пароль",
                              icon: passenable2
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              onPressed: () =>
                                  setState(() => passenable2 = !passenable2),
                            ),
                            SizedBox(height: 15.h),
                            const TextTranslated(
                              "Номер телефона",
                              style: TextStyle(
                                  fontSize: 17, fontWeight: FontWeight.w700),
                            ),
                            SizedBox(height: 5.h),
                            PhoneNumberInput(
                              onChanged: (completePhoneNumber) =>
                                  setState(() => number = completePhoneNumber),
                              controller: phoneNumberController,
                            ),
                            SizedBox(height: 15.h),
                            const TextTranslated(
                              "Регион",
                              style: TextStyle(
                                  fontSize: 17, fontWeight: FontWeight.w700),
                            ),
                            SizedBox(height: 5.h),
                            InkWell(
                              onTap: () async {
                                final picked = await RegionPickerSheet.show(
                                  context,
                                  current: region,
                                );
                                if (picked != null) {
                                  setState(() {
                                    region = picked;
                                    showRegionError = false;
                                  });
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 14),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: showRegionError
                                        ? Colors.red
                                        : (stateSwitch
                                            ? Colors.white24
                                            : Colors.black26),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: TextTranslated(
                                        region?.title ?? 'Выберите регион',
                                        style: TextStyle(
                                          fontSize: 15,
                                          color: region == null
                                              ? (stateSwitch
                                                  ? Colors.white54
                                                  : Colors.black45)
                                              : (stateSwitch
                                                  ? Colors.white
                                                  : Colors.black),
                                        ),
                                      ),
                                    ),
                                    Icon(Icons.keyboard_arrow_down,
                                        color: stateSwitch
                                            ? Colors.white54
                                            : Colors.black45),
                                  ],
                                ),
                              ),
                            ),
                            if (showRegionError)
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: TextTranslated(
                                  'Выберите регион',
                                  style: TextStyle(
                                      color: Colors.red, fontSize: 12.sp),
                                ),
                              ),
                            SizedBox(height: 40.h),
                            CustomButton(
                              borderRadius: 20,
                              title: "Зарегистрироваться",
                              onPressed: () {
                                if (!_formKey.currentState!.validate()) return;

                                if (region == null) {
                                  setState(() => showRegionError = true);
                                  scrollToBottom();
                                  return;
                                }

                                if (passwordController.text !=
                                    passwordControllerSecond.text) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content:
                                          TextTranslated('Пароли не совпадают'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                  return;
                                }

                                if (!checkBox) {
                                  setState(() => showCheckboxError = true);
                                  scrollToBottom();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Пожалуйста, примите условия пользовательского соглашения'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                  return;
                                }

                                context
                                    .read<AuthCubit>()
                                    .registerForVerification(
                                      password: passwordController.text,
                                      username: username.trim(),
                                      phoneNumber: number.trim(),
                                      regionId: region!.id,
                                    );
                              },
                            ),
                          ],
                        );
                      },
                    ),
                    if (_currentIndex == 3) ...[
                      SizedBox(height: 67.h),
                      const Center(
                        child: TextTranslated(
                          'Введите код, отправленный на ваш номер телефона',
                          style: AppTextStyle.verifyCodeStyle,
                        ),
                      ),
                      SizedBox(height: 20.h),
                      OtpCodeField(
                        isDarkMode: stateSwitch,
                        onEditing: (bool value) {
                          setState(() => _onEditing = value);
                          if (!_onEditing) FocusScope.of(context).unfocus();
                        },
                        onCompleted: (String value) {
                          setState(() => token = value);
                        },
                      ),
                      SizedBox(height: 25.h),
                      CustomButton(
                        borderRadius: 20,
                        title: isLoading ? "Проверяем…" : "Подтвердить телефон",
                        onPressed: () {
                          if (token.trim().length < 4) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Введите корректный код')),
                            );
                            return;
                          }
                          context.read<AuthCubit>().verifyCodeAndLogin(token);
                        },
                      ),
                    ],
                    SizedBox(height: 10.h),
                    if (_currentIndex == 1)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          const TextTranslated('Уже есть аккаунт?',
                              style: AppTextStyle.textAuthStyle),
                          SizedBox(width: 4.w),
                          InkWell(
                            onTap: () {
                              context.router.push(const SignInRoute());
                            },
                            child: const TextTranslated(
                              "Войти",
                              style: TextStyle(
                                color: Color(0xff197FBD),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    SizedBox(height: 10.h),
                    if (_currentIndex == 1)
                      Row(
                        children: [
                          IconButton(
                            onPressed: () {
                              setState(() {
                                checkBox = !checkBox;
                                if (checkBox) showCheckboxError = false;
                              });
                            },
                            icon: Icon(
                              checkBox
                                  ? Icons.check_box
                                  : Icons.check_box_outline_blank,
                              size: 30,
                              color:
                                  showCheckboxError ? Colors.red : activeColor,
                            ),
                          ),
                          TranslatedRichText(
                            defaultStyle: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: stateSwitch ? Colors.white : Colors.black,
                            ),
                            spans: [
                              TranslatedTextSpanData(
                                text:
                                    'Нажимая кнопку "Зарегистрироваться" я при-\nнимаю условия пользовательского соглашения \nи даю  свое согласие на',
                              ),
                              TranslatedTextSpanData(
                                text: ' обработку моих \nперсональных данных',
                                style: const TextStyle(
                                  color: Color(0xff197FBD),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    showDialog(
                                      context: context,
                                      builder: (_) => const Confirm(),
                                    );
                                  },
                              ),
                            ],
                          ),
                        ],
                      ),
                    SizedBox(height: 20.h),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class Confirm extends StatefulWidget {
  const Confirm({super.key});
  @override
  State<Confirm> createState() => _ConfirmState();
}

class _ConfirmState extends State<Confirm> {
  bool checkBox1 = false;
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      elevation: 0,
      title: const TextTranslated('Пользовательское соглашение',
          style: AppTextStyle.verifyCodeStyle),
      content: Container(
        decoration: BoxDecoration(border: Border.all()),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: TextTranslated(
            'Добро пожаловать в приложение ! Пожалуйста, внимательно прочтите следующее пользовательское соглашение, прежде чем использовать наше приложение.'
            'Мы уважаем вашу конфиденциальность и стремимся защитить вашу личную информацию. Пожалуйста, ознакомьтесь с нашей политикой конфиденциальности, чтобы узнать, как мы собираем, используем и защищаем вашу информацию.'
            'При использовании нашего приложения, вы соглашаетесь, что мы можем собирать и использовать определенные данные, включая, но не ограничиваясь, данные о вашем устройстве, местоположении и использовании приложения. '
            'ы оставляем за собой право вносить изменения в это пользовательское соглашение по своему усмотрению'
            'Продолжая использовать наше приложение, вы выражаете свое согласие с этими условиями. Благодарим вас за использование нашего приложения!',
            style: AppTextStyle.textAuthStyle,
          ),
        ),
      ),
      actions: [
        Row(
          children: [
            IconButton(
              onPressed: () => setState(() => checkBox1 = !checkBox1),
              icon: Icon(
                  checkBox1 ? Icons.check_box : Icons.check_box_outline_blank,
                  size: 30,
                  color: activeColor),
            ),
            const TextTranslated("Прочтено",
                style: AppTextStyle.verifyCodeStyle),
          ],
        ),
        SizedBox(height: 20.h),
      ],
    );
  }
}
