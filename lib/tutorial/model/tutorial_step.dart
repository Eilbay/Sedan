import 'package:flutter/material.dart';

class TutorialStep {
  final GlobalKey targetKey;

  final String titleKey;
  final String bodyKey;

  final EdgeInsets padding;
  final BorderRadius borderRadius;

  const TutorialStep({
    required this.targetKey,
    required this.titleKey,
    required this.bodyKey,
    this.padding = const EdgeInsets.all(10),
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
  });
}
