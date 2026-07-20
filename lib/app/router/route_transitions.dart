import 'package:flutter/widgets.dart';

/// Instant transition — renders child directly without any animation.
/// Used for routes that behave like tab switches (no slide/fade expected).
Widget noTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) =>
    child;
