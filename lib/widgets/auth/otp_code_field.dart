import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import 'package:smart_auth/smart_auth.dart';

/// 6-digit OTP input with native SMS autofill on both platforms.
///
/// - iOS: surfaces the code from the latest SMS in the keyboard
///   suggestion bar via the standard `AutofillHints.oneTimeCode` —
///   Pinput hooks this up automatically through its internal TextField.
/// - Android: auto-reads the incoming SMS via smart_auth's SMS User
///   Consent API (no app-hash, so no backend SMS-template change) wired
///   into `Pinput.smsRetriever`. The system shows a one-tap consent
///   prompt, then the code is filled automatically.
///
/// Single point of OTP UI for sign-up, password-reset, and email-change
/// flows — so styling and autofill behaviour stay consistent across the
/// app and changes happen in one place.
class OtpCodeField extends StatefulWidget {
  final int length;
  final ValueChanged<String> onCompleted;
  final ValueChanged<bool>? onEditing;
  final bool isDarkMode;

  const OtpCodeField({
    super.key,
    required this.onCompleted,
    this.onEditing,
    this.length = 6,
    this.isDarkMode = false,
  });

  @override
  State<OtpCodeField> createState() => _OtpCodeFieldState();
}

class _OtpCodeFieldState extends State<OtpCodeField> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  late final _SmsRetrieverImpl _smsRetriever;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_handleFocusChanged);
    _smsRetriever = _SmsRetrieverImpl(SmartAuth());
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChanged);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _handleFocusChanged() {
    widget.onEditing?.call(_focusNode.hasFocus);
  }

  @override
  Widget build(BuildContext context) {
    final textColor =
        widget.isDarkMode ? Colors.white : const Color(0xff78828A);

    final defaultTheme = PinTheme(
      width: 44,
      height: 50,
      textStyle: TextStyle(
        fontSize: 20,
        color: textColor,
        fontWeight: FontWeight.w500,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: textColor.withValues(alpha: 0.6)),
        ),
      ),
    );

    final focusedTheme = defaultTheme.copyDecorationWith(
      border: const Border(
        bottom: BorderSide(color: Colors.blue, width: 2),
      ),
    );

    return Pinput(
      controller: _controller,
      focusNode: _focusNode,
      smsRetriever: _smsRetriever,
      length: widget.length,
      keyboardType: TextInputType.number,
      autofocus: true,
      defaultPinTheme: defaultTheme,
      focusedPinTheme: focusedTheme,
      separatorBuilder: (_) => const SizedBox(width: 8),
      onCompleted: widget.onCompleted,
    );
  }
}

/// Android SMS auto-read via smart_auth's User Consent API (no app-hash, so
/// the backend SMS template needs no change). Pinput owns this object's
/// lifecycle and calls [dispose] when the field is torn down.
class _SmsRetrieverImpl implements SmsRetriever {
  _SmsRetrieverImpl(this._smartAuth);

  final SmartAuth _smartAuth;

  @override
  bool get listenForMultipleSms => false;

  @override
  Future<void> dispose() => _smartAuth.removeSmsListener();

  @override
  Future<String?> getSmsCode() async {
    final res = await _smartAuth.getSmsCode(useUserConsentApi: true);
    if (res.succeed && res.codeFound) return res.code;
    return null;
  }
}
