import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Reusable price row showing label and value with optional green color.
class PriceRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isDarkMode;
  final bool isGreen;
  final double? fontSize;

  const PriceRow({
    super.key,
    required this.label,
    required this.value,
    required this.isDarkMode,
    this.isGreen = false,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final size = fontSize ?? 12.sp;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: size,
            color: isDarkMode ? Colors.white70 : Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: size,
            fontWeight: FontWeight.w500,
            color: isGreen
                ? Colors.green
                : (isDarkMode ? Colors.white : Colors.black),
          ),
        ),
      ],
    );
  }
}
