import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:auto_route/auto_route.dart';
import 'package:optombai/app/router/app_router.dart';
import 'package:optombai/bloc/auth_bloc/auth_cubit.dart';
import 'package:optombai/bloc/auth_bloc/auth_state.dart';
import 'package:optombai/bloc/category_bloc/category_bloc.dart';
import 'package:optombai/bloc/user_bloc/user_bloc.dart';
import 'package:optombai/configs/app_style.dart';
import 'package:optombai/core/theme_notifier.dart';
import 'package:optombai/widgets/translation/text_translated.dart';
import 'package:optombai/widgets/translation/textspan_translated.dart';
import 'package:optombai/widgets/utils/buttons/custom_button.dart';
import 'package:optombai/widgets/utils/fields/custom_text_field.dart';
import 'package:optombai/widgets/utils/message_show.dart';

/// Inline sign-in form used inside tabs that require auth (Profile, Messages).
/// Shows the login form without navigating away, so the bottom bar remains
/// visible and the active tab stays highlighted.
class InlineSignIn extends StatefulWidget {
  const InlineSignIn({super.key});

  @override
  State<InlineSignIn> createState() => _InlineSignInState();
}

class _InlineSignInState extends State<InlineSignIn> {
  final _loginController = TextEditingController();
  final _passController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _passVisible = false;
  bool _userFetchDispatched = false;
  bool _authNavigated = false;

  static const Color _blue = Color(0xFF197FBD);

  @override
  void dispose() {
    _loginController.dispose();
    _passController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = context.select((ThemeNotifier n) => n.isDarkMode);
    final bool isRegister = context.select((ThemeNotifier n) => n.isRegister);
    final tokenPresent = context.read<AuthCubit>().getToken().isNotEmpty;
    final routeName = ModalRoute.of(context)?.settings.name ?? 'unknown';
    debugPrint(
      '[AUTH] InlineSignIn build route=$routeName isRegister=$isRegister '
      'tokenPresent=$tokenPresent',
    );
    final Color fg = isDark ? Colors.white : Colors.black87;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 40.h),
            Center(
              child: TextTranslated(
                'Добро пожаловать!',
                style: TextStyle(
                  fontSize: 26.sp,
                  fontWeight: FontWeight.w800,
                  color: fg,
                ),
              ),
            ),
            SizedBox(height: 8.h),
            Center(
              child: TextTranslated(
                'Мы рады видеть тебя снова',
                style: TextStyle(
                  fontSize: 15.sp,
                  color: isDark ? Colors.white60 : const Color(0xFF8A8F98),
                ),
              ),
            ),
            SizedBox(height: 34.h),
            TextTranslated('Номер телефона или имя',
                style: AppTextStyle.textAuthStyle),
            SizedBox(height: 6.h),
            CustomTextField(
              errorText: 'Имя',
              maxLines: 1,
              obscureText: false,
              textInputType: TextInputType.emailAddress,
              controller: _loginController,
              title: 'Введите номер или имя',
              path: const Icon(Icons.person_outline, color: _blue),
              onChanged: (_) {},
            ),
            SizedBox(height: 14.h),
            TextTranslated('Пароль', style: AppTextStyle.textAuthStyle),
            SizedBox(height: 6.h),
            CustomTextField(
              isPassword: true,
              errorText: 'Пароль',
              maxLines: 1,
              obscureText: !_passVisible,
              controller: _passController,
              title: 'Введите пароль',
              path: const Icon(Icons.lock_outline, color: _blue),
              textInputType: TextInputType.visiblePassword,
              icon: _passVisible ? Icons.visibility : Icons.visibility_off,
              onPressed: () => setState(() => _passVisible = !_passVisible),
              onChanged: (_) {},
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: _blue,
                  textStyle: AppTextStyle.forgotPassword,
                ),
                onPressed: () =>
                    context.router.push(const ForgotPasswordRoute()),
                child: const TextTranslated('Забыли пароль?'),
              ),
            ),
            SizedBox(height: 10.h),
            BlocConsumer<AuthCubit, AuthState>(
              listenWhen: (prev, cur) => prev.runtimeType != cur.runtimeType,
              listener: (context, state) {
                debugPrint(
                  '[AUTH] InlineSignIn listener state=${state.runtimeType} '
                  'userFetch=$_userFetchDispatched navigated=$_authNavigated',
                );
                if (state is AuthInitial) {
                  _userFetchDispatched = false;
                  _authNavigated = false;
                  return;
                }
                if (state is LoginStateSuccess && !_userFetchDispatched) {
                  _userFetchDispatched = true;
                  debugPrint('[AUTH] inline sign-in success -> fetch user');
                  context.read<UserBloc>().add(UserOwnerEvent());
                  context.read<ThemeNotifier>().setRegistrationStatus(true);
                  debugPrint(
                    '[AUTH] InlineSignIn after success tokenPresent=${context.read<AuthCubit>().getToken().isNotEmpty}',
                  );
                }
                if (state is AuthStateError) {
                  debugPrint(
                    '[AUTH] InlineSignIn error=${state.list.join(" | ")}',
                  );
                  showMessage(
                    context,
                    state.list.isNotEmpty ? state.list : ['Неизвестная ошибка'],
                    EnumStatusMessage.error,
                  );
                }
              },
              builder: (context, state) => CustomButton(
                borderRadius: 16,
                isLoading: state is AuthLoading,
                onPressed: () {
                  if (!_formKey.currentState!.validate()) return;
                  context.read<AuthCubit>().login(
                        _loginController.text.trim().toLowerCase(),
                        _passController.text,
                      );
                },
                title: 'Войти',
              ),
            ),
            BlocListener<UserBloc, UserState>(
              listenWhen: (prev, cur) => !prev.isSuccess && cur.isSuccess,
              listener: (context, state) {
                if (_authNavigated) return;
                _authNavigated = true;
                debugPrint(
                  '[AUTH] InlineSignIn user fetch success -> category refresh',
                );
                showMessage(context, ['Авторизация прошла успешно'],
                    EnumStatusMessage.success);
                context.read<CategoryBloc>().add(CategoryAllEvent());
                // No navigation needed: the host screen (BottomNav tab or
                // ChatListScreen) reactively watches ThemeNotifier.isRegister
                // and swaps away from this form in place once it flips —
                // preserving whatever tab/route the user was already on.
              },
              child: const SizedBox(),
            ),
            SizedBox(height: 22.h),
            Center(
              child: TranslatedRichText(
                defaultStyle: AppTextStyle.verifyCodeStyle,
                spans: [
                  TranslatedTextSpanData(text: 'Еще нет аккаунта? '),
                  TranslatedTextSpanData(
                    text: 'Зарегистрироваться',
                    style: AppTextStyle.forgotPassword,
                    recognizer: TapGestureRecognizer()
                      ..onTap = () => context.router.push(const SignUpRoute()),
                  ),
                ],
              ),
            ),
            SizedBox(height: 40.h),
          ],
        ),
      ),
    );
  }
}
