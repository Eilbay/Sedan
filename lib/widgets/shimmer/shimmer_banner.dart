import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Shimmer placeholder for the banner carousel on the home page.
class ShimmerBanner extends StatelessWidget {
  const ShimmerBanner({super.key});

  static const double _height = 200.0;
  static const double _borderRadius = 16.0;
  static const double _horizontalMargin = 8.0;
  static const double _dotSize = 6.0;
  static const int _dotCount = 3;
  static const double _dotSpacing = 8.0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Column(
        children: [
          Container(
            height: _height,
            margin: const EdgeInsets.symmetric(horizontal: _horizontalMargin),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(_borderRadius),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _dotCount,
              (_) => Container(
                width: _dotSize,
                height: _dotSize,
                margin: const EdgeInsets.symmetric(
                  horizontal: _dotSpacing / 2,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
