import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:optombai/l10n/tr.dart';
import 'package:optombai/tour/controller/tour_controller.dart';
import 'package:provider/provider.dart';
import 'package:showcaseview/showcaseview.dart';

const _brandPrimary = Color(0xFF0097B2);

class TourTooltipWidget extends StatelessWidget {
  final String text;
  final int totalInThisScreen;

  const TourTooltipWidget({
    super.key,
    required this.text,
    required this.totalInThisScreen,
  });

  @override
  Widget build(BuildContext context) {
    final tour = context.read<TourController>();
    final isLastTourStep =
        tour.isRunning && tour.stepIndex == tour.steps.length - 1;

    void onNext() {
      if (tour.innerIndex < totalInThisScreen - 1) {
        tour.innerIndex++;
        ShowcaseView.get().next();
        return;
      }

      tour.innerIndex = 0;

      if (isLastTourStep) {
        tour.stop();
        ShowcaseView.get().dismiss();
        return;
      }

      ShowcaseView.get().dismiss();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        tour.nextStep(context);
      });
    }

    final nextText =
        (isLastTourStep && tour.innerIndex >= totalInThisScreen - 1)
            ? tr(context, 'tour_start_work')
            : tr(context, 'tour_next');

    return Material(
      color: Colors.transparent,
      child: Container(
        width: 320.w,
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14.r),
          boxShadow: const [
            BoxShadow(
              blurRadius: 18,
              offset: Offset(0, 10),
              color: Color(0x22000000),
            )
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              style: TextStyle(
                fontSize: 13.sp,
                height: 1.25,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF111827),
              ),
            ),
            SizedBox(height: 12.h),
            SizedBox(
              width: double.infinity,
              child: _TourPillButton(
                text: nextText,
                onPressed: onNext,
                filled: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TourPillButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool filled;

  const _TourPillButton({
    required this.text,
    required this.onPressed,
    required this.filled,
  });

  @override
  Widget build(BuildContext context) {
    final ButtonStyle style = filled
        ? ElevatedButton.styleFrom(
            backgroundColor: _brandPrimary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: const StadiumBorder(),
            padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 10.h),
          )
        : OutlinedButton.styleFrom(
            foregroundColor: _brandPrimary,
            side: const BorderSide(color: _brandPrimary, width: 1.2),
            shape: const StadiumBorder(),
            padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 10.h),
          );

    return SizedBox(
      height: 38.h,
      child: filled
          ? ElevatedButton(onPressed: onPressed, style: style, child: _t(text))
          : OutlinedButton(onPressed: onPressed, style: style, child: _t(text)),
    );
  }

  Widget _t(String t) => Text(
        t,
        style: TextStyle(
          fontSize: 13.sp,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
        ),
      );
}
