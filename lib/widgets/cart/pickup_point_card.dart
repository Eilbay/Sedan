import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:optombai/core/theme_notifier.dart';
import 'package:optombai/data/models/cart/pickup_point_model.dart';
import 'package:provider/provider.dart';

/// Card for pickup point with map image
class PickupPointCard extends StatelessWidget {
  final PickupPoint point;
  final bool isSelected;
  final VoidCallback? onSelect;

  const PickupPointCard({
    super.key,
    required this.point,
    this.isSelected = false,
    this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.select((ThemeNotifier n) => n.isDarkMode);

    return Material(
      color: isDarkMode ? const Color(0xff0e1e33) : Colors.white,
      borderRadius: BorderRadius.circular(10.r),
      elevation: isSelected ? 3 : 1,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10.r),
          border: isSelected
              ? Border.all(color: const Color(0xffFFA800), width: 2)
              : Border.all(color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!, width: 1),
        ),
        child: Padding(
          padding: EdgeInsets.all(10.w),
          child: Row(
            children: [
              // Map icon
              ClipRRect(
                borderRadius: BorderRadius.circular(6.r),
                child: Image.asset(
                  'assets/maps/ic_map.png',
                  width: 50.w,
                  height: 50.w,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 50.w,
                    height: 50.w,
                    color: Colors.grey[200],
                    child: Icon(Icons.map, color: Colors.grey[400], size: 24.sp),
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              // Point info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      point.name,
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      point.address,
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      point.workingHours,
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: isDarkMode ? Colors.grey[500] : Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              // Select button
              ElevatedButton(
                onPressed: onSelect,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isSelected ? const Color(0xffFFA800) : (isDarkMode ? Colors.grey[700] : Colors.grey[200]),
                  foregroundColor: isSelected ? Colors.white : (isDarkMode ? Colors.white : Colors.black),
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6.r)),
                  elevation: 0,
                ),
                child: Text(
                  isSelected ? 'Выбрано' : 'Выбрать',
                  style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
