import 'package:flutter/material.dart';

class HolePainter extends CustomPainter {
  final Rect holeRect;
  final BorderRadius borderRadius;

  HolePainter({required this.holeRect, required this.borderRadius});

  @override
  void paint(Canvas canvas, Size size) {
    final overlayPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final rrect = borderRadius.toRRect(holeRect);
    final holePath = Path()..addRRect(rrect);

    final paint = Paint()..color = Colors.black.withOpacity(0.55);

    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());
    canvas.drawPath(overlayPath, paint);

    final clearPaint = Paint()..blendMode = BlendMode.clear;
    canvas.drawPath(holePath, clearPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant HolePainter oldDelegate) {
    return oldDelegate.holeRect != holeRect ||
        oldDelegate.borderRadius != borderRadius;
  }
}
