import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:optombai/data/models/cart/delivery_type.dart';

/// Delivery type selector with radio buttons
class DeliverySelector extends StatelessWidget {
  final DeliveryType selectedType;
  final ValueChanged<DeliveryType> onChanged;

  const DeliverySelector({
    super.key,
    required this.selectedType,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: DeliveryType.values.map((type) {
        final isSelected = type == selectedType;
        return _DeliveryOption(
          type: type,
          isSelected: isSelected,
          onChanged: onChanged,
        );
      }).toList(),
    );
  }

}

class _DeliveryOption extends StatelessWidget {
  final DeliveryType type;
  final bool isSelected;
  final ValueChanged<DeliveryType> onChanged;

  const _DeliveryOption({
    required this.type,
    required this.isSelected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(type),
      borderRadius: BorderRadius.circular(6.r),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 5.h),
        child: Row(
          children: [
            // Radio indicator
            Container(
              width: 16.w,
              height: 16.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? const Color(0xffFFA800) : Colors.grey[400]!,
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 8.w,
                        height: 8.w,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xffFFA800),
                        ),
                      ),
                    )
                  : null,
            ),
            SizedBox(width: 8.w),
            // Label
            Expanded(
              child: Text(
                type == DeliveryType.pickup ? 'До пункта выдачи' : 'Курьером',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                ),
              ),
            ),
            // Price
            Text(
              _formatPrice(type.cost),
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: type.cost == 0 ? Colors.green : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatPrice(double price) {
    if (price == 0) return 'Бесплатно';
    return '${price.truncate()} \u20BD';
  }
}
