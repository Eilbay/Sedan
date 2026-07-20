import 'package:flutter/material.dart';
import 'package:optombai/features/promotion/data/models/promotion_package_model.dart';
import 'package:optombai/widgets/translation/text_translated.dart';

class PromotionPriceDisplay extends StatelessWidget {
  final int days;
  final double pricePerDay;
  final double totalPrice;
  final ReachRange estimatedReach;
  final bool isDark;

  const PromotionPriceDisplay({
    super.key,
    required this.days,
    required this.pricePerDay,
    required this.totalPrice,
    required this.estimatedReach,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xff0095D5).withValues(alpha: 0.15)
            : const Color(0xff0095D5).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xff0095D5).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          _buildRow(
            'Цена за день:',
            '${pricePerDay.toStringAsFixed(0)} сом',
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          _buildRow(
            'Количество дней:',
            '$days',
            isDark: isDark,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Divider(
              color: isDark ? Colors.white24 : Colors.grey.shade300,
              height: 1,
            ),
          ),
          _buildRow(
            'Итого:',
            '${totalPrice.toStringAsFixed(0)} сом',
            isDark: isDark,
            isBold: true,
            valueColor: const Color(0xff0095D5),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? Colors.green.withValues(alpha: 0.15) : Colors.green.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.visibility, size: 20, color: Colors.green),
                const SizedBox(width: 8),
                Expanded(
                  child: TextTranslated(
                    'Ожидаемый охват:',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ),
                Text(
                  '${_formatNumber(estimatedReach.from)} - ${_formatNumber(estimatedReach.to)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(
    String label,
    String value, {
    required bool isDark,
    bool isBold = false,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TextTranslated(
          label,
          style: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 18 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: valueColor ?? (isDark ? Colors.white : Colors.black87),
          ),
        ),
      ],
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}
