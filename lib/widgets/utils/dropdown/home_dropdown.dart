import 'package:optombai/core/theme_notifier.dart';
import 'package:optombai/widgets/translation/text_translated.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomeDropdown extends StatelessWidget {
  final Function onChanged;
  final String? title;
  final double? titleSize;
  final double? itemSize;
  final dynamic value;
  final List list;

  const HomeDropdown({
    super.key,
    required this.onChanged,
    required this.list,
    required this.value,
    this.title,
    this.titleSize,
    this.itemSize,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.select((ThemeNotifier n) => n.isDarkMode);

    return Container(
      height: 20,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? const Color(0xff1A2A42) : const Color(0xffCFDEFB), width: 1),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<dynamic>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down, size: 20),
          hint: TextTranslated(
            title ?? '',
            style: TextStyle(
              fontSize: titleSize ?? 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          items: list.map((item) {
            return DropdownMenuItem(
              value: item.id,
              child: TextTranslated(
                item.name,
                style: TextStyle(fontSize: itemSize ?? 14),
              ),
            );
          }).toList(),
          onChanged: (v) => onChanged(v),
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}
