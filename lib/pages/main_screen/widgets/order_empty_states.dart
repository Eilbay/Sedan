import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:optombai/widgets/translation/text_translated.dart';

class OrderContentHeader extends StatelessWidget {
  final String ownerName;
  final String correctCountryName;
  final int totalQuantity;

  const OrderContentHeader({
    super.key,
    required this.ownerName,
    required this.correctCountryName,
    required this.totalQuantity,
  });

  @override
  Widget build(BuildContext context) {
    return TextTranslated(
      correctCountryName.isNotEmpty
          ? "$ownerName из $correctCountryName: $totalQuantity"
          : ownerName,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }
}

class EmptySearchResult extends StatelessWidget {
  const EmptySearchResult({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.search_off, size: 46, color: Colors.grey),
            SizedBox(height: 12.h),
            const TextTranslated(
              'По вашему запросу ничего не найдено',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 6.h),
            const TextTranslated(
              'Попробуйте изменить фильтры или страну',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class EmptyUsersResult extends StatelessWidget {
  const EmptyUsersResult({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.person_off, size: 46, color: Colors.grey),
            SizedBox(height: 12.h),
            const TextTranslated(
              'Пользователи не найдены',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 6.h),
            const TextTranslated(
              'Попробуйте изменить страну или категорию',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
