import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import 'package:optombai/core/theme_notifier.dart';
import 'package:optombai/widgets/translation/text_translated.dart';

class BorderText extends StatelessWidget {
  final String text;

  const BorderText({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    final stateSwitch = context.select((ThemeNotifier n) => n.isDarkMode);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: stateSwitch ? Colors.white : Colors.black,
          width: 1.3,
        ),
      ),
      child: TextTranslated(
        text,
        style: TextStyle(
          color: stateSwitch ? Colors.white : Colors.black,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class InfoRow extends StatelessWidget {
  final String title;
  final String value;
  final TextStyle? titleStyle;
  final TextStyle? valueStyle;

  const InfoRow({
    super.key,
    required this.title,
    required this.value,
    this.titleStyle,
    this.valueStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextTranslated(
          title,
          style: titleStyle ??
              const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: TextTranslated(
            value,
            style: valueStyle ??
                const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
          ),
        ),
      ],
    );
  }
}

class CategoryChip extends StatelessWidget {
  final String text;

  const CategoryChip({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    final isDark = context.select((ThemeNotifier n) => n.isDarkMode);

    final Color bg = isDark ? const Color(0xff0B1220) : const Color(0xffE0F2FE);
    final Color border =
        isDark ? const Color(0xff1D4ED8) : const Color(0xffBAE6FD);
    final Color textColor = isDark ? Colors.white : const Color(0xff0F172A);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border, width: 1),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  offset: const Offset(0, 2),
                  blurRadius: 4,
                  color: Colors.black.withValues(alpha: 0.05),
                ),
              ],
      ),
      child: TextTranslated(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
    );
  }
}

class ManufacturerInfoCard extends StatelessWidget {
  const ManufacturerInfoCard({super.key});

  static const List<String> _categories = [
    'Футболки',
    'Рубашки',
    'Толстовки',
    'Спортивная одежда',
    'Платья',
    'Брюки',
    'Верхняя одежда',
    'Детская одежда',
    'Женская одежда',
    'Мужская одежда',
    'Школьная форма',
    'Медицинская форма',
    'Оверсайз',
    'Трикотаж',
    'Нижнее бельё',
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = context.select((ThemeNotifier n) => n.isDarkMode);

    const accent = Color(0xff328AC0);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xff293244) : const Color(0xffF5FAFF),
        borderRadius: BorderRadius.circular(30.r),
        border: Border.all(
          color:
              isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xffD1E9FF),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const BorderText(text: 'О производителе'),
          SizedBox(height: 24.h),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InfoRow(
                title: 'Кол-во сотрудников: ',
                value: '120',
                valueStyle: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: accent,
                ),
              ),
              SizedBox(height: 10),
              InfoRow(
                title: 'Размерная сетка: ',
                value: '64–42',
                valueStyle: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: accent,
                ),
              ),
              InfoRow(
                title: 'Минимальный заказ: ',
                value: '500 ед',
                valueStyle: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: accent,
                ),
              ),
              SizedBox(height: 10),
              InfoRow(
                title: 'Работа в белую: ',
                value: '✔️',
                valueStyle: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: accent,
                ),
              ),
              SizedBox(height: 10),
              InfoRow(
                title: 'Документы для экспорта в РФ: ',
                value: '✔️',
                valueStyle: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: accent,
                ),
              ),
              SizedBox(height: 10),
              InfoRow(
                title: 'Документы для экспорта в Европу: ',
                value: '✔️',
                valueStyle: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: accent,
                ),
              ),
              SizedBox(height: 10),
            ],
          ),
          SizedBox(height: 24.h),
          const TextTranslated(
            'Категории одежды',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 8.h),
          const TextTranslated(
            'Можете выбрать из следующих категорий:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
          SizedBox(height: 16.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: _categories
                .map((c) => CategoryChip(text: c))
                .toList(growable: false),
          ),
        ],
      ),
    );
  }
}
