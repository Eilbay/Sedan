import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:optombai/bloc/auth_bloc/auth_cubit.dart';
import 'package:optombai/bloc/auth_bloc/auth_state.dart';
import 'package:optombai/bloc/category_bloc/category_bloc.dart';
import 'package:optombai/bloc/user_bloc/user_bloc.dart';
import 'package:optombai/configs/constrants.dart';
import 'package:optombai/configs/app_style.dart';
import 'package:optombai/app/router/app_router.dart';
import 'package:optombai/core/di/injection.dart';
import 'package:optombai/widgets/translation/text_translated.dart';
import 'package:optombai/widgets/translation/textspan_translated.dart';
import 'package:optombai/widgets/utils/buttons/custom_button.dart';
import 'package:optombai/widgets/utils/fields/custom_text_field.dart';
import 'package:optombai/core/theme_notifier.dart';
import 'package:optombai/widgets/app_scaffold/bazarlar_app_scaffold.dart';
import 'package:optombai/widgets/bottom_nav.dart';
import 'package:optombai/widgets/utils/message_show.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:auto_route/auto_route.dart';
import 'package:shared_preferences/shared_preferences.dart';

@RoutePage(name: 'SignInRoute')
class SignIn extends StatefulWidget {
  const SignIn({super.key});

  @override
  State<SignIn> createState() => _SignInState();
}

class _SignInState extends State<SignIn> {
  final TextEditingController loginController = TextEditingController();
  final TextEditingController passController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool passanable = true;
  var name = "";
  var password = "";
  bool _userFetchDispatched = false;
  bool _authNavigated = false;

  static const Color _blue = Color(0xFF197FBD);

  @override
  void dispose() {
    loginController.dispose();
    passController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = context.select((ThemeNotifier n) => n.isDarkMode);
    final Color fg = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      bottomNavigationBar: const BottomNav(
        currentIndexOverride: -4,
        passive: true,
      ),
      body: BazarlarAppScaffold(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 40.h),
                Center(
                  child: TextTranslated(
                    "Добро пожаловать!",
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
                    "Мы рады видеть тебя снова",
                    style: TextStyle(
                      fontSize: 15.sp,
                      color: isDark ? Colors.white60 : const Color(0xFF8A8F98),
                    ),
                  ),
                ),
                SizedBox(height: 34.h),
                const TextTranslated(
                  "Номер телефона или имя",
                  style: AppTextStyle.textAuthStyle,
                ),
                SizedBox(height: 6.h),
                CustomTextField(
                  errorText: 'Имя',
                  maxLines: 1,
                  obscureText: false,
                  textInputType: TextInputType.emailAddress,
                  controller: loginController,
                  title: "Введите номер или имя",
                  path: const Icon(Icons.person_outline, color: _blue),
                  onChanged: (value) => setState(() => name = value),
                ),
                SizedBox(height: 14.h),
                const TextTranslated(
                  "Пароль",
                  style: AppTextStyle.textAuthStyle,
                ),
                SizedBox(height: 6.h),
                CustomTextField(
                  isPassword: true,
                  errorText: 'Пароль',
                  maxLines: 1,
                  obscureText: passanable,
                  controller: passController,
                  title: "Введите пароль",
                  path: const Icon(Icons.lock_outline, color: _blue),
                  textInputType: TextInputType.visiblePassword,
                  icon: passanable ? Icons.visibility : Icons.visibility_off,
                  onPressed: () => setState(() => passanable = !passanable),
                  onChanged: (value) => setState(() => password = value),
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
                    child: const TextTranslated("Забыли пароль?"),
                  ),
                ),
                SizedBox(height: 10.h),
                BlocConsumer<AuthCubit, AuthState>(
                  listenWhen: (prev, current) =>
                      prev.runtimeType != current.runtimeType,
                  listener: (context, state) {
                    debugPrint(
                      '[AUTH] SignIn listener state=${state.runtimeType} '
                      'userFetch=$_userFetchDispatched navigated=$_authNavigated',
                    );
                    if (state is AuthInitial) {
                      _userFetchDispatched = false;
                      _authNavigated = false;
                      debugPrint('[AUTH] SignIn reset auth flags');
                      return;
                    }
                    if (state is LoginStateSuccess && !_userFetchDispatched) {
                      final route = ModalRoute.of(context);
                      if (route?.isCurrent != true) {
                        debugPrint(
                          '[AUTH] SignIn ignored success navigation because '
                          'route is covered by ${context.router.topRoute.name}',
                        );
                        return;
                      }
                      _userFetchDispatched = true;
                      debugPrint('[AUTH] SignIn login success -> fetch user');
                      BlocProvider.of<UserBloc>(context).add(UserOwnerEvent());
                      context.read<ThemeNotifier>().setRegistrationStatus(true);
                      if (_authNavigated) return;
                      _authNavigated = true;

                      final messenger = ScaffoldMessenger.of(context);

                      showMessage(
                        context,
                        ["Авторизация прошла успешно"],
                        EnumStatusMessage.success,
                      );

                      BlocProvider.of<CategoryBloc>(context)
                          .add(CategoryAllEvent());

                      final router = context.router;
                      final stackNames = router.stack
                          .map((route) => route.routeData.name)
                          .toList();
                      debugPrint(
                        '[AUTH] SignIn stack before close=$stackNames',
                      );

                      if (router.canPop()) {
                        debugPrint(
                          '[AUTH] SignIn pop back to previous route '
                          'stackAfterLogin=${router.stack.map((r) => r.routeData.name).toList()}',
                        );
                        router.pop();
                      } else {
                        final prefs = getIt<SharedPreferences>();
                        final lastTab = prefs.getInt(LAST_BOTTOM_TAB_KEY) ?? 0;
                        debugPrint(
                          '[AUTH] SignIn fallback replaceAll -> '
                          'BottomNavRoute(initialIndex=$lastTab)',
                        );
                        router.replaceAll([
                          BottomNavRoute(initialIndex: lastTab),
                        ]);
                      }

                      Future.delayed(const Duration(milliseconds: 1300), () {
                        messenger.clearSnackBars();
                      });
                    }
                    if (state is AuthStateError) {
                      showMessage(
                        context,
                        state.list.isNotEmpty
                            ? state.list
                            : ["Неизвестная ошибка"],
                        EnumStatusMessage.error,
                      );
                    }
                  },
                  builder: (context, state) {
                    return SizedBox(
                      width: double.infinity,
                      child: CustomButton(
                        borderRadius: 16,
                        isLoading: state is AuthLoading,
                        onPressed: () {
                          if (!_formKey.currentState!.validate()) return;
                          final username = loginController.text.toLowerCase();
                          final password = passController.text;
                          context.read<AuthCubit>().login(username, password);
                        },
                        title: "Войти",
                      ),
                    );
                  },
                ),
                SizedBox(height: 22.h),
                Center(
                  child: TranslatedRichText(
                    defaultStyle: AppTextStyle.verifyCodeStyle,
                    spans: [
                      TranslatedTextSpanData(
                        text: 'Еще нет аккаунта? ',
                        style: AppTextStyle.verifyCodeStyle,
                      ),
                      TranslatedTextSpanData(
                        text: 'Зарегистрироваться',
                        style: AppTextStyle.forgotPassword,
                        recognizer: TapGestureRecognizer()
                          ..onTap =
                              () => context.router.push(const SignUpRoute()),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
