import 'package:flutter/material.dart';
import 'package:optombai/widgets/translation/text_translated.dart';

class CategoryTabs extends StatelessWidget {
  final int currentIndex;
  final List<String> labels;
  final Color backgroundColor;
  final Function(int) onTap;
  final TextStyle? textStyle;
  final double spacing;

  const CategoryTabs({
    super.key,
    required this.currentIndex,
    required this.labels,
    required this.backgroundColor,
    required this.onTap,
    this.textStyle,
    this.spacing = 12,
  });

  bool _isLightBackground(Color color) {
    return color.computeLuminance() > 0.5;
  }

  Color _getSelectedColor() {
    return _isLightBackground(backgroundColor) ? Colors.black : Colors.white;
  }

  Color _getUnselectedColor() {
    return _isLightBackground(backgroundColor)
        ? Colors.grey[700]!
        : Colors.grey;
  }

  Color _getSeparatorColor() {
    return _isLightBackground(backgroundColor) ? Colors.black : Colors.white;
  }

  List<Shadow> _getShadows() {
    return _isLightBackground(backgroundColor)
        ? []
        : const [
            Shadow(color: Colors.black45, blurRadius: 2),
          ];
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < labels.length; i++) ...[
          if (i > 0)
            TextTranslated(
              '/',
              style: (textStyle ?? const TextStyle()).copyWith(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: _getSeparatorColor(),
                shadows: _getShadows(),
              ),
            ),
          if (i > 0) SizedBox(width: spacing),
          GestureDetector(
            onTap: () => onTap(i),
            child: TextTranslated(
              labels[i],
              style: (textStyle ?? const TextStyle()).copyWith(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: currentIndex == i
                    ? _getSelectedColor()
                    : _getUnselectedColor(),
                shadows: _getShadows(),
              ),
            ),
          ),
          if (i < labels.length - 1) SizedBox(width: spacing),
        ],
      ],
    );
  }
}
