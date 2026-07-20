import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:optombai/app/router/app_router.dart';
import 'package:optombai/widgets/auth/otp_code_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

const String patternPhone = r'(^(?:[+0]9)?[0-9]{10,12}$)';
const String patternEmail =
    r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+";
const String patternCharacterNumber = r'[0-9]+$';

final spinkit = SpinKitFadingCircle(
  itemBuilder: (BuildContext context, int index) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: index.isEven ? Colors.blue : Colors.white,
      ),
    );
  },
);

enum EnumStatusMessage { success, warning, error }

// Suppresses duplicate snackbars triggered by rapid bloc emissions (e.g. a
// listener firing several times during a route transition). The window is
// short enough not to swallow legitimately repeated messages a user might
// trigger by tapping again.
String? _lastSnackKey;
DateTime? _lastSnackAt;
const Duration _snackDedupWindow = Duration(milliseconds: 1200);

const Duration _autoHideAfter = Duration(milliseconds: 800);
Timer? _autoHideTimer;

void showMessage(
    BuildContext context, List<String> errors, EnumStatusMessage variant,
    {bool isExit = false}) {
  final isOtpScreen =
      context.findAncestorWidgetOfExactType<OtpCodeField>() != null;
  if (isOtpScreen) return;
  String message = errors.join(". ");

  final key = '${variant.name}|$message';
  final now = DateTime.now();
  if (_lastSnackKey == key &&
      _lastSnackAt != null &&
      now.difference(_lastSnackAt!) < _snackDedupWindow) {
    return;
  }
  _lastSnackKey = key;
  _lastSnackAt = now;

  Color getBackgroundColor() {
    if (variant == EnumStatusMessage.success) {
      return const Color.fromARGB(255, 16, 130, 73);
    } else if (variant == EnumStatusMessage.error) {
      return const Color(0xffff5252);
    } else {
      return const Color(0xff1d84d7);
    }
  }

  IconData getIcon() {
    if (variant == EnumStatusMessage.success) {
      return Icons.check_circle;
    } else if (variant == EnumStatusMessage.error) {
      return Icons.error;
    } else {
      return Icons.info;
    }
  }

  // clearSnackBars() drops both the visible snack AND every queued one.
  // hideCurrentSnackBar() only kills the visible bar, so direct calls to
  // ScaffoldMessenger.showSnackBar from other screens (chat, sign_up,
  // referral, etc.) would stack up and look stuck. Wiping the queue here
  // means a fresh snack is always the only one on screen.
  final messenger = ScaffoldMessenger.of(context);
  messenger.clearSnackBars();

  messenger.showSnackBar(
    SnackBar(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(25),
      ),
      content: Row(
        children: [
          Icon(
            getIcon(),
            color: Colors.white,
            size: 25,
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 16,
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w500,
                fontStyle: FontStyle.normal,
              ),
              maxLines: 3,
            ),
          ),
        ],
      ),
      backgroundColor: getBackgroundColor(),
      duration: const Duration(milliseconds: 500),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.only(left: 10, right: 10, bottom: 20, top: 20),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      elevation: 6,
      action: SnackBarAction(
        label: "",
        textColor: Colors.white,
        onPressed: () {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
        },
      ),
    ),
  );

  _autoHideTimer?.cancel();
  _autoHideTimer = Timer(_autoHideAfter, () {
    messenger.hideCurrentSnackBar();
  });

  if (isExit) {
    debugPrint('[AUTH] message_show exit -> sign in');
    context.router.push(const SignInRoute());
  }
}
