import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:optombai/widgets/translation/text_translated.dart';
import 'package:optombai/core/theme_notifier.dart';
import 'package:provider/provider.dart';

class AmountSelector extends StatelessWidget {
  final List<double> presetAmounts;
  final double minAmount;
  final double selectedAmount;
  final bool useCustomAmount;
  final TextEditingController customAmountController;
  final ValueChanged<double> onPresetSelected;
  final ValueChanged<bool> onCustomToggled;

  const AmountSelector({
    super.key,
    required this.presetAmounts,
    required this.minAmount,
    required this.selectedAmount,
    required this.useCustomAmount,
    required this.customAmountController,
    required this.onPresetSelected,
    required this.onCustomToggled,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.select((ThemeNotifier n) => n.isDarkMode);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextTranslated(
          'Сумма пополнения',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        SizedBox(height: 10.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: presetAmounts.map((amount) {
            final isSelected = !useCustomAmount && selectedAmount == amount;
            return _AmountChip(
              amount: amount,
              isSelected: isSelected,
              isDark: isDark,
              onTap: () => onPresetSelected(amount),
            );
          }).toList(),
        ),
        SizedBox(height: 12.h),
        _CustomAmountToggle(
          useCustomAmount: useCustomAmount,
          customAmountController: customAmountController,
          minAmount: minAmount,
          isDark: isDark,
          onToggle: () => onCustomToggled(!useCustomAmount),
        ),
      ],
    );
  }
}

class _AmountChip extends StatelessWidget {
  final double amount;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _AmountChip({
    required this.amount,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xff0095D5)
              : (isDark ? Colors.white10 : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? const Color(0xff0095D5)
                : (isDark ? Colors.white24 : Colors.grey.shade300),
          ),
        ),
        child: Text(
          '${amount.toStringAsFixed(0)} сом',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : (isDark ? Colors.white : Colors.black87),
          ),
        ),
      ),
    );
  }
}

class _CustomAmountToggle extends StatelessWidget {
  final bool useCustomAmount;
  final TextEditingController customAmountController;
  final double minAmount;
  final bool isDark;
  final VoidCallback onToggle;

  const _CustomAmountToggle({
    required this.useCustomAmount,
    required this.customAmountController,
    required this.minAmount,
    required this.isDark,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: onToggle,
          child: Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: useCustomAmount ? const Color(0xff0095D5) : Colors.transparent,
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                    color: useCustomAmount
                        ? const Color(0xff0095D5)
                        : (isDark ? Colors.white38 : Colors.grey),
                    width: 1.5,
                  ),
                ),
                child: useCustomAmount
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : null,
              ),
              SizedBox(width: 8.w),
              TextTranslated(
                'Своя сумма',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),
        if (useCustomAmount) ...[
          SizedBox(height: 10.h),
          Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.white10 : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xff0095D5).withValues(alpha: 0.5),
              ),
            ),
            child: TextField(
              controller: customAmountController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(7),
              ],
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
              decoration: InputDecoration(
                hintText: 'Введите сумму',
                hintStyle: TextStyle(
                  color: isDark ? Colors.white38 : Colors.grey,
                  fontWeight: FontWeight.w400,
                  fontSize: 14,
                ),
                suffixText: 'сом',
                suffixStyle: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
                border: InputBorder.none,
              ),
            ),
          ),
          SizedBox(height: 4.h),
          TextTranslated(
            'Минимум: ${minAmount.toStringAsFixed(0)} сом',
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.white54 : Colors.black45,
            ),
          ),
        ],
      ],
    );
  }
}
