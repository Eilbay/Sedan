import 'package:flutter/material.dart';

class DarkBackground extends StatelessWidget {
  final Widget child;
  final String assetPath;

  const DarkBackground({
    super.key,
    required this.child,
    this.assetPath = 'assets/dark_theme.png',
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          assetPath,
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
        ),
        Container(color: const Color(0xFF0A1C2C).withValues(alpha: 0.35)),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0.0, -0.35),
              radius: 1.0,
              colors: [Colors.white.withValues(alpha: 0.10), Colors.transparent],
              stops: const [0.0, 0.60],
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0.0, -0.15),
              radius: 1.35,
              colors: [Colors.transparent, Colors.black.withValues(alpha: 0.70)],
              stops: const [0.55, 1.0],
            ),
          ),
        ),
        child,
      ],
    );
  }
}
