import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:optombai/widgets/translation/text_translated.dart';
import 'package:flutter/material.dart';

class SubscriptionSuccessPopup extends StatelessWidget {
  final String planTitle;
  final int visitLimitManufacturer;
  final int visitLimit;

  const SubscriptionSuccessPopup({
    super.key,
    required this.planTitle,
    required this.visitLimitManufacturer,
    required this.visitLimit,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const TextTranslated(
              "Поздравляем!",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            SizedBox(height: 10.h),
            TextTranslated(
              "Вы успешно активировали тариф: \n$planTitle",
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 10.h),
            TextTranslated(
              "Теперь у вас есть доступ к $visitLimitManufacturer предприятиям и $visitLimit заказам.",
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 20.h),
            SizedBox(
              width: 120.w,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const TextTranslated(
                  "Закрыть",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
