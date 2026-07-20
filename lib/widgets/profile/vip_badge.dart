import 'package:flutter/material.dart';

class VipBadge extends StatelessWidget {
  final double paddingH;
  final double paddingV;
  final double borderRadius;
  final double fontSize;

  const VipBadge({
    super.key,
    this.paddingH = 10,
    this.paddingV = 4,
    this.borderRadius = 8,
    this.fontSize = 14,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: paddingH, vertical: paddingV),
      decoration: BoxDecoration(
        color: const Color(0xFF7AD8FF),
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Text(
        'VIP',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: fontSize,
          letterSpacing: 1,
        ),
      ),
    );
  }
}
