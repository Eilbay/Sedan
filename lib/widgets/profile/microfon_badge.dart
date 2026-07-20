import 'package:flutter/material.dart';

class MicrofonBadge extends StatelessWidget {
  final double size;
  final double rotationAngle;

  const MicrofonBadge({
    super.key,
    this.size = 20,
    this.rotationAngle = -0.3,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size + 6,
      height: size + 6,
      decoration: const BoxDecoration(
        color: Colors.black54,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Transform.rotate(
        angle: rotationAngle,
        child: Image.asset(
          'assets/7.png',
          height: 14,
          width: 14,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
