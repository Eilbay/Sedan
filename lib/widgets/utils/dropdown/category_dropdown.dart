import 'package:optombai/core/theme_notifier.dart';
import 'package:optombai/data/models/category/category_model.dart';
import 'package:optombai/widgets/translation/text_translated.dart';
import 'package:optombai/widgets/utils/card/card_filter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CustomCategoryDropdown extends StatelessWidget {
  final String? value;
  final List<Category> list;
  final ValueChanged<String?> onChanged;
  final String hint;
  final double fontSize;

  const CustomCategoryDropdown({
    super.key,
    this.value,
    required this.list,
    required this.onChanged,
    this.hint = 'Выберите...',
    this.fontSize = 16,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.select((ThemeNotifier n) => n.isDarkMode);

    final items = <DropdownMenuItem<String>>[];
    for (final cat in list) {
      items.add(
        DropdownMenuItem(
          value: cat.id,
          child: Row(
            children: [
              Expanded(
                  child: TextTranslated(cat.name,
                      style: TextStyle(fontSize: fontSize))),
            ],
          ),
        ),
      );

      for (final sub in cat.children) {
        items.add(
          DropdownMenuItem(
            value: sub.id,
            child: Padding(
              padding: const EdgeInsets.only(left: 16),
              child: TextTranslated(sub.name,
                  style: TextStyle(fontSize: fontSize)),
            ),
          ),
        );
      }
    }

    return CardFilter(
      child: DropdownButton<String>(
        value: value,
        isExpanded: true,
        underline: const SizedBox(),
        icon: const Icon(Icons.keyboard_arrow_down),
        hint: TextTranslated(hint,
            style: TextStyle(fontSize: fontSize, color: Colors.grey)),
        items: items,
        onChanged: onChanged,
        dropdownColor: isDark ? Colors.grey[850] : Colors.white,
        style: TextStyle(
            color: isDark ? Colors.white : Colors.black, fontSize: fontSize),
      ),
    );
  }
}
