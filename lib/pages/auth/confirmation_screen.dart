import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:optombai/widgets/translation/text_translated.dart';
import 'package:flutter/material.dart';

class ConfirmationChoiceScreen extends StatelessWidget {
  final Function(int) onSelected;

  const ConfirmationChoiceScreen({super.key, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const TextTranslated("Выберите способ подтверждения"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 50),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => onSelected(0),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
                textStyle:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              child: const TextTranslated("Получить код по телефону"),
            ),
            SizedBox(height: 20.h),
            ElevatedButton(
              onPressed: () => onSelected(1),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
                textStyle:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              child: const TextTranslated("Получить код по e-mail"),
            ),
          ],
        ),
      ),
    );
  }
}
