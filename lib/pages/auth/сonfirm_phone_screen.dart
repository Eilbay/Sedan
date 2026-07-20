import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:optombai/bloc/auth_bloc/auth_cubit.dart';
import 'package:optombai/bloc/auth_bloc/auth_state.dart';
import 'package:optombai/app/router/app_router.dart';
import 'package:optombai/widgets/auth/otp_code_field.dart';

@RoutePage()
class ConfirmPhoneScreen extends StatefulWidget {
  final String username;
  final String password;
  final String phone;
  final int? regionId;
  final String? email;
  const ConfirmPhoneScreen({
    super.key,
    required this.username,
    required this.password,
    required this.phone,
    this.regionId,
    this.email,
  });

  @override
  State<ConfirmPhoneScreen> createState() => _ConfirmPhoneScreenState();
}

class _ConfirmPhoneScreenState extends State<ConfirmPhoneScreen> {
  // Stored OTP — populated by `OtpCodeField.onCompleted` (autofill or
  // manual). The button uses this instead of a TextEditingController.
  String _code = '';
  String? _codeError;

  void _submit(BuildContext context, {required bool isLoading}) {
    if (isLoading) return;
    if (_code.length != 6) {
      setState(() => _codeError = 'Введите 6-значный код');
      return;
    }
    setState(() => _codeError = null);
    context
        .read<AuthCubit>()
        .activeAccount(_code, widget.username, widget.password);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Подтверждение телефона')),
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (ctx, state) {
          if (state is AuthStateCodeSuccess) {
            ScaffoldMessenger.of(ctx).showSnackBar(
              const SnackBar(content: Text('Регистрация завершена')),
            );
            ctx.router.replaceAll([const SignInRoute()]);
          } else if (state is AuthStateInvalidCode) {
            setState(() {
              _codeError = 'Код неверный, попробуйте ещё раз';
              _code = '';
            });
            ScaffoldMessenger.of(ctx).showSnackBar(
              const SnackBar(content: Text('Код неверный, попробуйте ещё раз')),
            );
          } else if (state is AuthStateError) {
            final msg = state.list.isNotEmpty ? state.list.first : 'Ошибка';
            ScaffoldMessenger.of(ctx)
                .showSnackBar(SnackBar(content: Text(msg)));
          }
        },
        builder: (ctx, state) {
          final isLoading = state is AuthLoading;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text(
                  'Введите код из SMS',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                // OtpCodeField uses Pinput with AutofillHints.oneTimeCode,
                // so the latest SMS code is offered in the keyboard
                // suggestion bar (iOS) / autofill prompt (Android).
                OtpCodeField(
                  key: ValueKey(_code.isEmpty ? 'fresh' : 'filled'),
                  onCompleted: (code) {
                    _code = code;
                    if (_codeError != null) {
                      setState(() => _codeError = null);
                    }
                    _submit(context, isLoading: isLoading);
                  },
                ),
                if (_codeError != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _codeError!,
                    style: const TextStyle(color: Colors.red, fontSize: 13),
                  ),
                ],
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () => _submit(context, isLoading: isLoading),
                  child: Text(isLoading ? 'Проверяем…' : 'Подтвердить'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: isLoading
                      ? null
                      : () {
                          context.read<AuthCubit>().authenticateUser(
                                email: widget.email,
                                password: widget.password,
                                username: widget.username,
                                phoneNumber: widget.phone,
                                regionId: widget.regionId,
                              );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Код отправлен повторно')),
                          );
                        },
                  child: const Text('Отправить код повторно'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
