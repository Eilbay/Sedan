import 'dart:async';
import 'package:flutter/widgets.dart';

class TourStep {
  final int? tabIndex;
  final List<GlobalKey> showcaseKeys;
  final bool Function(BuildContext context)? canRun;

  final FutureOr<void> Function(BuildContext context)? onEnter;

  const TourStep({
    this.tabIndex,
    required this.showcaseKeys,
    this.canRun,
    this.onEnter,
  });
}
