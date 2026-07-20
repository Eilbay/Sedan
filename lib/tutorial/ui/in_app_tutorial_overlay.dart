import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:optombai/widgets/translation/text_translated.dart';
import '../model/tutorial_step.dart';
import '../paint/hole_painter.dart';

class InAppTutorialOverlay extends StatelessWidget {
  final Rect holeRect;
  final TutorialStep step;
  final int index;
  final int total;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const InAppTutorialOverlay({
    super.key,
    required this.holeRect,
    required this.step,
    required this.index,
    required this.total,
    required this.onNext,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final safe = MediaQuery.paddingOf(context);
    final screen = MediaQuery.sizeOf(context);

    final preferBelow = holeRect.bottom + 170 < screen.height - safe.bottom;
    final rawTop =
        preferBelow ? holeRect.bottom + 12 : (holeRect.top - 12 - 170);
    final cardTop =
        rawTop.clamp(safe.top + 8, screen.height - safe.bottom - 170);

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              ignoring: true,
              child: CustomPaint(
                painter: HolePainter(
                  holeRect: holeRect,
                  borderRadius: step.borderRadius,
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            top: cardTop.toDouble(),
            child: Container(
              padding: EdgeInsets.all(14.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [
                  BoxShadow(blurRadius: 18, color: Color(0x22000000))
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextTranslated(
                          step.titleKey,
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF111827),
                          ),
                        ),
                      ),
                      Text(
                        '${index + 1}/$total',
                        style: TextStyle(
                            fontSize: 12.sp, color: const Color(0xFF6B7280)),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  TextTranslated(
                    step.bodyKey,
                    style: TextStyle(
                        fontSize: 14.sp,
                        height: 1.35,
                        color: const Color(0xFF374151)),
                  ),
                  SizedBox(height: 12.h),
                  Row(
                    children: [
                      const Spacer(),
                      if (index > 0)
                        OutlinedButton(
                          onPressed: onBack,
                          style: OutlinedButton.styleFrom(
                            shape: const StadiumBorder(),
                            side: BorderSide(
                                color: Colors.black.withOpacity(0.12)),
                          ),
                          child: TextTranslated('Назад',
                              style: TextStyle(fontSize: 14.sp)),
                        ),
                      SizedBox(width: 10.w),
                      ElevatedButton(
                        onPressed: onNext,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0097B2),
                          shape: const StadiumBorder(),
                          elevation: 0,
                        ),
                        child: TextTranslated(
                          index == total - 1 ? 'Начать работу' : 'Далее',
                          style: TextStyle(
                              fontSize: 14.sp,
                              color: Colors.white,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
