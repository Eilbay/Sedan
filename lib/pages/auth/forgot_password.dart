import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:optombai/bloc/auth_bloc/auth_cubit.dart';
import 'package:optombai/bloc/auth_bloc/auth_state.dart';
import 'package:optombai/configs/app_style.dart';
import 'package:optombai/utils/extensions/string_validation_extension.dart';
import 'package:optombai/widgets/bottom_nav.dart';
import 'package:optombai/app/router/app_router.dart';
import 'package:optombai/widgets/translation/text_translated.dart';
import 'package:optombai/widgets/utils/buttons/custom_button.dart';
import 'package:optombai/widgets/utils/fields/custom_text_field.dart';
import 'package:optombai/widgets/utils/message_show.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:optombai/widgets/auth/otp_code_field.dart';

import 'package:optombai/core/theme_notifier.dart';
import 'package:auto_route/auto_route.dart';

@RoutePage(name: 'ForgotPasswordRoute')
class ForgotPassword extends StatefulWidget {
  const ForgotPassword({super.key});

  @override
  State<ForgotPassword> createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  final TextEditingController loginController = TextEditingController();
  final TextEditingController passController = TextEditingController();
  final TextEditingController passController2 = TextEditingController();
  late String token = "";

  int _currentIndex = 1;
  bool _isEmailSelected = false;
  bool passanable = true;
  bool passanable2 = true;
  var password = "";
  bool _isValid = false;

  var email = "";
  var phone = "";
  String userId = "";

  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    loginController.dispose();
    passController.dispose();
    passController2.dispose();
    super.dispose();
  }

  bool _validateCode(String code) {
    return code.length == 6;
  }

  Future<void> _sendResetRequest() async {
    var value = phone.sanitizedPhone;
    if (!value.startsWith('+')) value = '+$value';

    const String key = "phone_number";
    const String endpoint = 'reset_password_by_pn/';

    try {
      await context
          .read<AuthCubit>()
          .sendResetPasswordRequest(value, endpoint, key);
      setState(() {
        _currentIndex = 3;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _currentIndex = 2;
      });
      showMessage(context, ['Не удалось отправить код. Повторите попытку.'],
          EnumStatusMessage.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool stateSwitch = context.select((ThemeNotifier n) => n.isDarkMode);
    return Scaffold(
      bottomNavigationBar: const BottomNav(
        currentIndexOverride: -1,
        passive: true,
      ),
      appBar: AppBar(
        excludeHeaderSemantics: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          onPressed: () {
            if (_currentIndex == 1) {
              context.router.maybePop();
            }
            setState(() {
              _currentIndex--;
            });
          },
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.only(right: 20, left: 30, top: 30),
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
                      SizedBox(
                        width: 3.w,
                      ),
                      const Text(
                        "Китайдан",
                        style: TextStyle(
                            fontFamily: 'Marmelad',
                            fontWeight: FontWeight.w400,
                            fontSize: 22),
                      )
                    ],
                  ),
                  SizedBox(
                    height: 20.h,
                  ),
                  const TextTranslated(
                    "Восстановление пароля",
                    style: AppTextStyle.welcomeTextStyle,
                  ),
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xff737373),
                      textStyle: const TextStyle(
                          color: Color(0xff737373),
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ),
                    onPressed: () {},
                    child: TextTranslated("Шаг $_currentIndex/4"),
                  ),
                  SizedBox(
                    height: 20.h,
                  ),
                  Builder(builder: (context) {
                    if (_currentIndex == 1) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const TextTranslated(
                            "Выберите способ восстановления пароля",
                            style: AppTextStyle.textAuthStyle,
                          ),
                          SizedBox(height: 20.h),
                          CustomButton(
                            title: "По номеру телефона",
                            onPressed: () {
                              setState(() {
                                _isEmailSelected = false;
                                _currentIndex++;
                              });
                            },
                          ),
                        ],
                      );
                    } else if (_currentIndex == 2) {
                      return Column(
                        children: [
                          const Center(
                            child: TextTranslated(
                              'Введите ваш номер телефона для восстановления',
                              style: AppTextStyle.verifyCodeStyle,
                            ),
                          ),
                          CustomTextField(
                            title: _isEmailSelected
                                ? "Введите ваш e-mail"
                                : "Введите ваш номер телефона",
                            controller: loginController,
                            fixedPlus: !_isEmailSelected,
                            onChanged: (value) {
                              setState(() {
                                if (_isEmailSelected) {
                                  email = value;
                                } else {
                                  phone = value;
                                }
                              });
                            },
                          ),
                          SizedBox(
                            height: 25.h,
                          ),
                          BlocConsumer<AuthCubit, AuthState>(
                            listener: (context, state) {
                              if (state is AuthStateSuccess) {
                                setState(() {
                                  _currentIndex = 3;
                                });
                              } else if (state is AuthStateError) {
                                setState(() {
                                  _currentIndex = 2;
                                });
                                showMessage(
                                  context,
                                  ["Email или номер телефона не найден"],
                                  EnumStatusMessage.error,
                                );
                              }
                            },
                            builder: (context, state) {
                              return CustomButton(
                                borderRadius: 20,
                                isLoading: state is AuthLoading,
                                title: "Подтвердить",
                                onPressed: () {
                                  if (!loginController.text.isValidContact(
                                      isEmail: _isEmailSelected)) {
                                    showMessage(
                                      context,
                                      [
                                        _isEmailSelected
                                            ? "Введите корректный email"
                                            : "Введите корректный номер телефона"
                                      ],
                                      EnumStatusMessage.error,
                                    );
                                    return;
                                  }

                                  _sendResetRequest();
                                },
                              );
                            },
                          ),
                        ],
                      );
                    } else if (_currentIndex == 3) {
                      return Column(
                        children: [
                          const Center(
                            child: TextTranslated(
                              'Введите код, отправленный на ваш телефон',
                              style: AppTextStyle.verifyCodeStyle,
                            ),
                          ),
                          OtpCodeField(
                            isDarkMode: stateSwitch,
                            onCompleted: (value) async {
                              setState(() {
                                token = value;
                                _isValid = _validateCode(value);
                              });

                              if (!_isValid) return;

                              try {
                                final id = await context
                                    .read<AuthCubit>()
                                    .getUserByToken(token);
                                if (!context.mounted) return;
                                if (id.isNotEmpty) {
                                  setState(() {
                                    userId = id;
                                    _currentIndex = 4;
                                  });
                                } else {
                                  showMessage(
                                      context,
                                      ["Код неверный, попробуйте ещё раз"],
                                      EnumStatusMessage.error);
                                }
                              } catch (_) {
                                if (!context.mounted) return;
                                showMessage(
                                    context,
                                    ["Код неверный, попробуйте ещё раз"],
                                    EnumStatusMessage.error);
                              }
                            },
                            onEditing: (bool value) {
                              if (!value) {
                                setState(() {
                                  _isValid = _validateCode(token);
                                });
                              }
                            },
                          ),
                          SizedBox(height: 25.h),
                          BlocConsumer<AuthCubit, AuthState>(
                            listener: (context, state) async {
                              if (state is AuthStateError) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: TextTranslated(
                                        "Код неверный. Введите корректный код"),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              }
                            },
                            builder: (context, state) {
                              return CustomButton(
                                borderRadius: 20,
                                isLoading: state is AuthLoading,
                                title: "Подтвердить",
                                onPressed: () async {
                                  if (token.isEmpty || !_isValid) {
                                    showMessage(
                                        context,
                                        [
                                          "Введите код, отправленный на ваш телефон"
                                        ],
                                        EnumStatusMessage.error);
                                    return;
                                  }

                                  try {
                                    final id = await context
                                        .read<AuthCubit>()
                                        .getUserByToken(token);
                                    if (!context.mounted) return;
                                    if (id.isNotEmpty) {
                                      setState(() {
                                        userId = id;
                                        _currentIndex = 4;
                                      });
                                    } else {
                                      showMessage(
                                          context,
                                          ["Код неверный, попробуйте ещё раз"],
                                          EnumStatusMessage.error);
                                    }
                                  } catch (_) {
                                    if (!context.mounted) return;
                                    showMessage(
                                        context,
                                        ["Код неверный, попробуйте ещё раз"],
                                        EnumStatusMessage.error);
                                  }
                                },
                              );
                            },
                          ),
                        ],
                      );
                    } else {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const TextTranslated(
                            "Новый пароль",
                            style: AppTextStyle.textAuthStyle,
                          ),
                          SizedBox(
                            height: 5.h,
                          ),
                          CustomTextField(
                            isPassword: true,
                            inputFormatters: 30,
                            errorText: "Пароль",
                            maxLines: 1,
                            obscureText: passanable,
                            controller: passController,
                            onChanged: (value) {
                              password = value;
                            },
                            textInputType: TextInputType.visiblePassword,
                            title: "Введите ваш пароль",
                            icon: passanable
                                ? Icons.visibility
                                : Icons.visibility_off,
                            onPressed: () {
                              setState(() {
                                passanable = !passanable;
                              });
                            },
                          ),
                          SizedBox(
                            height: 20.h,
                          ),
                          const TextTranslated(
                            "Повторите ваш пароль",
                            style: AppTextStyle.textAuthStyle,
                          ),
                          SizedBox(
                            height: 5.h,
                          ),
                          CustomTextField(
                            isPassword: true,
                            inputFormatters: 30,
                            errorText: "Повторите ваш пароль",
                            maxLines: 1,
                            obscureText: passanable2,
                            controller: passController2,
                            onChanged: (value) {
                              password = value;
                            },
                            textInputType: TextInputType.visiblePassword,
                            title: "Введите ваш пароль",
                            icon: passanable2
                                ? Icons.visibility
                                : Icons.visibility_off,
                            onPressed: () {
                              setState(() {
                                passanable2 = !passanable2;
                              });
                            },
                          ),
                          SizedBox(
                            height: 40.h,
                          ),
                          BlocConsumer<AuthCubit, AuthState>(
                            listener: (context, state) {
                              if (state is AuthStateSuccess) {
                                showMessage(
                                    context,
                                    ["Ваш пароль успешно обновлён"],
                                    EnumStatusMessage.success);
                                context.router
                                    .replaceAll([const SignInRoute()]);
                              } else if (state is AuthStateError) {
                                showMessage(context, state.list,
                                    EnumStatusMessage.error);
                              }
                            },
                            builder: (context, state) {
                              return CustomButton(
                                borderRadius: 20,
                                title: "Подтвердить",
                                isLoading: state is AuthLoading,
                                onPressed: () {
                                  if (!_formKey.currentState!.validate()) {
                                    return;
                                  }
                                  final password = passController.text;

                                  if (passController.text !=
                                      passController2.text) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: TextTranslated(
                                              'Пароли должны совпадать'),
                                          duration: Duration(seconds: 2)),
                                    );
                                    return;
                                  }
                                  context
                                      .read<AuthCubit>()
                                      .updatePassword(password, userId);
                                },
                              );
                            },
                          ),
                        ],
                      );
                    }
                  }),
                ]),
          ),
        ),
      ),
    );
  }
}
