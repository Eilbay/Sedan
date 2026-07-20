import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:optombai/bloc/auth_bloc/auth_cubit.dart';
import 'package:optombai/bloc/auth_bloc/auth_state.dart';
import 'package:optombai/bloc/user_bloc/user_bloc.dart';
import 'package:optombai/configs/app_style.dart';
import 'package:optombai/widgets/translation/text_translated.dart';
import 'package:optombai/widgets/utils/buttons/custom_button.dart';
import 'package:optombai/widgets/utils/fields/custom_text_field.dart';
import 'package:optombai/widgets/utils/message_show.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

@RoutePage(name: 'ProfileEditPasswordRoute')
class ProfileEditPassword extends StatefulWidget {
  const ProfileEditPassword({super.key});

  @override
  State<ProfileEditPassword> createState() => _ProfileEditPasswordState();
}

class _ProfileEditPasswordState extends State<ProfileEditPassword> {
  int _currentIndex = 1;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController passController = TextEditingController();
  final TextEditingController passController1 = TextEditingController();
  final TextEditingController passController2 = TextEditingController();
  late String token;

  var password = "";

  bool passanable = true;
  bool passenable2 = true;
  bool passenable3 = true;

  @override
  void dispose() {
    passController.dispose();
    passController1.dispose();
    passController2.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var user = context.select((UserBloc b) => b.state.user);
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
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const TextTranslated(
                  "Изменение пароля",
                  style: AppTextStyle.welcomeTextStyle,
                ),
                SizedBox(
                  height: 10.h,
                ),
                const TextTranslated(
                  "Пароль должен содержать не менее шести символов, "
                  "включая цифры, буквы и специальные символы (!@%)",
                  style: TextStyle(
                      color: Color(0xff78828A),
                      fontSize: 12,
                      fontWeight: FontWeight.w500),
                ),
                SizedBox(
                  height: 25.h,
                ),
                const TextTranslated(
                  'Текущий пароль',
                  style: AppTextStyle.textAuthStyle,
                ),
                SizedBox(
                  height: 5.h,
                ),
                CustomTextField(
                    maxLines: 1,
                    errorText: 'Пароль',
                    inputFormatters: 20,
                    textInputType: TextInputType.visiblePassword,
                    controller: passController,
                    title: 'Введите текущий пароль',
                    onChanged: (value) {
                      setState(() {
                        password = value;
                      });
                    },
                    icon: passanable ? Icons.visibility : Icons.visibility_off,
                    onPressed: () {
                      setState(() {
                        passanable = !passanable;
                      });
                    },
                    obscureText: passanable),
                SizedBox(
                  height: 25.h,
                ),
                const TextTranslated(
                  'Новый пароль',
                  style: AppTextStyle.textAuthStyle,
                ),
                SizedBox(
                  height: 5.h,
                ),
                CustomTextField(
                    maxLines: 1,
                    errorText: '"Пароль"',
                    inputFormatters: 20,
                    textInputType: TextInputType.visiblePassword,
                    controller: passController1,
                    title: 'Введите новый пароль',
                    onChanged: (value) {
                      setState(() {
                        password = value;
                      });
                    },
                    icon: passenable2 ? Icons.visibility : Icons.visibility_off,
                    onPressed: () {
                      setState(() {
                        passenable2 = !passenable2;
                      });
                    },
                    obscureText: passenable2),
                SizedBox(
                  height: 25.h,
                ),
                const TextTranslated(
                  'Подтвердите ваш пароль',
                  style: AppTextStyle.textAuthStyle,
                ),
                SizedBox(
                  height: 5.h,
                ),
                CustomTextField(
                    controller: passController2,
                    errorText: 'Пароль',
                    inputFormatters: 20,
                    textInputType: TextInputType.visiblePassword,
                    maxLines: 1,
                    title: 'Введите новый пароль повторно',
                    onChanged: (value) {
                      setState(() {
                        password = value;
                      });
                    },
                    icon: passenable3 ? Icons.visibility : Icons.visibility_off,
                    onPressed: () {
                      setState(() {
                        passenable3 = !passenable3;
                      });
                    },
                    obscureText: passenable3),
                SizedBox(
                  height: 35.h,
                ),
                BlocConsumer<AuthCubit, AuthState>(
                  listener: (context, state) {
                    if (state is AuthStateSuccess) {
                      showMessage(
                        context,
                        ["Пароль успешно обновлён!"],
                        EnumStatusMessage.success,
                      );
                      context.router.maybePop();
                    } else if (state is AuthStateError) {
                      showMessage(context, state.list, EnumStatusMessage.error);
                    }
                  },
                  builder: (context, state) {
                    return CustomButton(
                      borderRadius: 20,
                      isLoading: state is AuthLoading,
                      title: "Подтвердить",
                      onPressed: () async {
                        if (!_formKey.currentState!.validate()) {
                          return;
                        }
                        final oldPassword = passController.text;

                        if (passController1.text != passController2.text) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: TextTranslated('Пароли не совпадают'),
                                duration: Duration(seconds: 2)),
                          );
                          return;
                        }
                        // context
                        //     .read<AuthCubit>()
                        //     .updatePassword(password, user.id);
                        context
                            .read<AuthCubit>()
                            .checkOldPassword(oldPassword, password, user.id);
                      },
                    );
                  },
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
