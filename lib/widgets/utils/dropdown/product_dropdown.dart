import 'package:optombai/core/theme_notifier.dart';
import 'package:optombai/widgets/translation/text_translated.dart';
import 'package:optombai/widgets/utils/card/card_filter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CustomDropdown extends StatelessWidget {
  final Function onChanged;
  final String? title;
  final double? titleSize;
  final double? itemSize;
  final dynamic value;
  final String? errorTex;
  final List list;
  final BoxBorder? border;
  final String? type;

  const CustomDropdown({
    super.key,
    required this.onChanged,
    required this.list,
    required this.value,
    this.border,
    this.errorTex,
    this.title,
    this.titleSize,
    this.itemSize,
    this.type,
  });

  @override
  Widget build(BuildContext context) {
    bool stateSwitch = context.select((ThemeNotifier n) => n.isDarkMode);
    return dropDawn(
        stateSwitch,
        list.map((items) {
          return DropdownMenuItem(
            value: items.id,
            child: Padding(
              padding: const EdgeInsets.only(left: 5),
              child: TextTranslated(
                items.name,
                style: TextStyle(
                    color: stateSwitch ? Colors.white : Colors.black,
                    fontSize: itemSize),
              ),
            ),
          );
        }).toList());
  }

  Widget dropDawn(bool stateSwitch, List<DropdownMenuItem<dynamic>>? items) =>
      CardFilter(
        child: DropdownButton<dynamic>(
          value: value,
          isDense: true,
          hint: TextTranslated(
            title ?? "",
            style: TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w500,
                fontSize: titleSize),
          ),
          underline: const SizedBox(),
          isExpanded: true,
          borderRadius: BorderRadius.circular(12),
          icon: const Icon(
            Icons.keyboard_arrow_down,
          ),
          items: items,
          onChanged: (newValue) {
            onChanged(newValue);
          },
        ),
      );
}
