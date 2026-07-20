import 'package:flutter/material.dart';
import 'package:optombai/widgets/translation/text_translated.dart';

class PromotionSlider extends StatelessWidget {
  final int minDays;
  final int maxDays;
  final int currentDays;
  final ValueChanged<int> onChanged;
  final bool isDark;

  const PromotionSlider({
    super.key,
    required this.minDays,
    required this.maxDays,
    required this.currentDays,
    required this.onChanged,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextTranslated(
              'Срок продвижения',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xff0095D5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$currentDays ${_getDaysWord(currentDays)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: const Color(0xff0095D5),
            inactiveTrackColor: isDark ? Colors.white24 : Colors.grey.shade300,
            thumbColor: const Color(0xff0095D5),
            overlayColor: const Color(0xff0095D5).withValues(alpha: 0.2),
            trackHeight: 6,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
          ),
          child: Slider(
            value: currentDays.toDouble(),
            min: minDays.toDouble(),
            max: maxDays.toDouble(),
            divisions: maxDays - minDays,
            label: '$currentDays',
            onChanged: (value) => onChanged(value.round()),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$minDays дн.',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white54 : Colors.grey,
              ),
            ),
            Text(
              '$maxDays дн.',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white54 : Colors.grey,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _getDaysWord(int days) {
    if (days % 10 == 1 && days % 100 != 11) {
      return 'день';
    } else if ([2, 3, 4].contains(days % 10) &&
        ![12, 13, 14].contains(days % 100)) {
      return 'дня';
    } else {
      return 'дней';
    }
  }
}
