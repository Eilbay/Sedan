import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:optombai/configs/app_color.dart';
import 'package:optombai/widgets/translation/text_translated.dart';
import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool? isDelete;

  const CustomButton({
    super.key,
    required this.title,
    required this.onPressed,
    this.isDelete = true,
    this.icon,
    this.isLoading = false,
    this.borderRadius = 8,
  });

  final String title;
  final IconData? icon;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(
          horizontal: 50.w,
          vertical: 15.h,
        ),
        backgroundColor: isDelete! ? activeColor : Colors.red,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius.r),
        ),
      ),
      child: !isLoading
          ? Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextTranslated(
                  title,
                  style: TextStyle(fontSize: 16.sp),
                ),
              ],
            )
          : Center(
              child: SizedBox(
                height: 20.h,
                width: 20.w,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            ),
    );
  }
}

class ChangeBtn extends StatelessWidget {
  const ChangeBtn(
      {super.key,
      required this.title,
      required this.icon,
      required this.onPressed,
      required this.color});

  final String title;
  final Color color;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(backgroundColor: color),
      onPressed: onPressed,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextTranslated(
            title,
            style: const TextStyle(color: Colors.white, fontSize: 15),
          ),
          Icon(
            icon,
            color: Colors.white,
          )
        ],
      ),
    );
  }
}
