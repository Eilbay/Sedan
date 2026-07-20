import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Quantity selector widget with +/- buttons
/// Design matches the mockup: [ - ] 1 [ + ]
class QuantitySelector extends StatelessWidget {
  final int quantity;
  final ValueChanged<int> onChanged;
  final int minQuantity;
  final int maxQuantity;
  final Color? borderColor;
  final Color? iconColor;

  const QuantitySelector({
    super.key,
    required this.quantity,
    required this.onChanged,
    this.minQuantity = 0,
    this.maxQuantity = 99,
    this.borderColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBorderColor = borderColor ?? Colors.grey[300]!;
    final effectiveIconColor = iconColor ?? Colors.grey[600]!;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _QuantityButton(
          icon: Icons.remove,
          onPressed:
              quantity > minQuantity ? () => onChanged(quantity - 1) : null,
          borderColor: effectiveBorderColor,
          iconColor: effectiveIconColor,
        ),
        Container(
          constraints: BoxConstraints(minWidth: 32.w),
          padding: EdgeInsets.symmetric(horizontal: 8.w),
          child: Text(
            quantity.toString(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        _QuantityButton(
          icon: Icons.add,
          onPressed:
              quantity < maxQuantity ? () => onChanged(quantity + 1) : null,
          borderColor: effectiveBorderColor,
          iconColor: effectiveIconColor,
        ),
      ],
    );
  }

}

class _QuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color borderColor;
  final Color iconColor;

  const _QuantityButton({
    required this.icon,
    required this.onPressed,
    required this.borderColor,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null;

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(6.r),
      child: Container(
        width: 28.w,
        height: 28.w,
        decoration: BoxDecoration(
          border: Border.all(
            color: isDisabled ? borderColor.withValues(alpha: 0.5) : borderColor,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(6.r),
        ),
        child: Icon(
          icon,
          size: 16.sp,
          color: isDisabled ? iconColor.withValues(alpha: 0.5) : iconColor,
        ),
      ),
    );
  }
}
