import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:optombai/widgets/translation/text_translated.dart';

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
                fontSize: 16,
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

class BulletList extends StatelessWidget {
  final List<String> items;
  final TextStyle? textStyle;
  final double spacing;

  const BulletList({
    super.key,
    required this.items,
    this.textStyle,
    this.spacing = 4,
  });

  @override
  Widget build(BuildContext context) {
    final style = textStyle ??
        const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items
          .map(
            (item) => Padding(
              padding: EdgeInsets.only(bottom: spacing.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const TextTranslated(
                    '• ',
                    style: TextStyle(fontSize: 14),
                  ),
                  Expanded(
                    child: TextTranslated(
                      item,
                      style: style,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}
