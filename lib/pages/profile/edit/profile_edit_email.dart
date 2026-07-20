import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:optombai/configs/app_style.dart';
import 'package:optombai/core/theme_notifier.dart';
import 'package:optombai/widgets/translation/text_translated.dart';
import 'package:optombai/widgets/utils/buttons/custom_button.dart';
import 'package:optombai/widgets/utils/fields/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:optombai/widgets/auth/otp_code_field.dart';

import 'package:optombai/bloc/user_bloc/user_bloc.dart';
import 'package:auto_route/auto_route.dart';
import 'package:optombai/widgets/utils/message_show.dart';

@RoutePage(name: 'ProfileEditEmailRoute')
class ProfileEditEmail extends StatefulWidget {
  const ProfileEditEmail({super.key});

  @override
  State<ProfileEditEmail> createState() => _ProfileEditEmailState();
}

class _ProfileEditEmailState extends State<ProfileEditEmail> {
  int _currentIndex = 1;

  final TextEditingController loginController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  late String code;
  var email = "";
  bool _onEditing = true;
  String userId = "";

  @override
  void dispose() {
    loginController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool stateSwitch = context.select((ThemeNotifier n) => n.isDarkMode);
    return Scaffold(
        appBar: AppBar(
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
        body: BlocConsumer<UserBloc, UserState>(
          listener: (context, state) {
            if (state.errors.isNotEmpty) {
              showMessage(context, state.errors, EnumStatusMessage.error);
            } else if (!state.isLoadingEmail) {
              if (_currentIndex == 2) {
                context.router.maybePop();
                showMessage(
                    context, ["Профиль изменился"], EnumStatusMessage.success);
              }
              _currentIndex++;
            }
          },
          builder: (context, state) {
            return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                child: Form(
                    key: _formKey,
                    child: SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: Column(children: [
                          const TextTranslated(
                            "Изменение почты",
                            style: AppTextStyle.welcomeTextStyle,
                          ),
                          SizedBox(
                            height: 15.h,
                          ),
                          TextTranslated(
                            "Шаг $_currentIndex/2",
                            style: const TextStyle(
                                color: Color(0xff737373),
                                fontSize: 12,
                                fontWeight: FontWeight.w600),
                          ),
                          SizedBox(
                            height: 30.h,
                          ),
                          Visibility(
                            visible: _currentIndex == 1,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const TextTranslated(
                                  "Новая почта",
                                  style: AppTextStyle.textAuthStyle,
                                ),
                                SizedBox(
                                  height: 5.h,
                                ),
                                CustomTextField(
                                  errorText: '"E-mail"',
                                  controller: loginController,
                                  textInputType: TextInputType.emailAddress,
                                  inputFormatters: 40,
                                  maxLines: 1,
                                  obscureText: false,
                                  title: "Введите ваш новый e-mail",
                                  onChanged: (value) {
                                    setState(() {
                                      email = value;
                                    });
                                  },
                                ),
                                SizedBox(
                                  height: 25.h,
                                ),
                                CustomButton(
                                  borderRadius: 20,
                                  isLoading: state.isLoadingEmail,
                                  title: "Подтвердить",
                                  onPressed: () {
                                    setState(() {
                                      if (!_formKey.currentState!.validate()) {
                                        return;
                                      }
                                      final email = loginController.text;
                                      context
                                          .read<UserBloc>()
                                          .add(UserUpdateEmail(email: email));
                                    });
                                  },
                                )
                              ],
                            ),
                          ),
                          Visibility(
                            visible: _currentIndex == 2,
                            child: Column(children: [
                              const Center(
                                child: TextTranslated(
                                  'Введите код, отправленный на ваш e-mail',
                                  style: AppTextStyle.verifyCodeStyle,
                                ),
                              ),
                              OtpCodeField(
                                isDarkMode: stateSwitch,
                                onCompleted: (value) {
                                  setState(() {
                                    code = value;
                                  });
                                },
                                onEditing: (bool value) {
                                  setState(() {
                                    _onEditing = value;
                                  });
                                  if (!_onEditing) {
                                    FocusScope.of(context).unfocus();
                                  }
                                },
                              ),
                              SizedBox(
                                height: 25.h,
                              ),
                              CustomButton(
                                borderRadius: 20,
                                isLoading: state.isLoadingEmail,
                                title: "Подтвердить",
                                onPressed: () {
                                  setState(() {
                                    context.read<UserBloc>().add(
                                        UpdateEmail(email: email, code: code));
                                  });
                                },
                              )
                            ]),
                          )
                        ]))));
          },
        ));
  }
}
