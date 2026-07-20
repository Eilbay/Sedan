import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:optombai/core/theme_notifier.dart';
import 'package:optombai/widgets/translation/text_translated.dart';
import 'package:provider/provider.dart';

class PremiumBadge extends StatelessWidget {
  final VoidCallback? onTap;
  final bool flagCardProduct;

  const PremiumBadge({
    super.key,
    this.onTap,
    this.flagCardProduct = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = context.select((ThemeNotifier n) => n.isDarkMode);

    const lightGradient = [
      Color(0xFF1E3C72),
      Color(0xFF2A5298),
      Color(0xFF4263EB),
    ];

    const darkGradient = [
      Color(0xFFA2CFFC),
      Color(0xFFF7CFFF),
    ];

    final gradientColors = isDarkMode ? darkGradient : lightGradient;

    final borderColor =
        isDarkMode ? const Color(0xFFA2CFFC) : const Color(0xFF2A5298);
    final backgroundColor = isDarkMode ? const Color(0xFF0E1E33) : Colors.white;

    final badge = Container(
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 2.h),
      decoration: BoxDecoration(
        border: Border.all(color: borderColor, width: 1.w),
        borderRadius: BorderRadius.circular(6.r),
        color: backgroundColor,
      ),
      child: ShaderMask(
        shaderCallback: (bounds) => LinearGradient(
          colors: gradientColors,
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ).createShader(bounds),
        blendMode: BlendMode.srcIn,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: EdgeInsets.only(bottom: 0.5.h),
              child: const Icon(
                Icons.business_center_rounded,
                size: 15,
                color: Colors.white,
              ),
            ),
            if (!flagCardProduct) ...[
              SizedBox(width: 4.w),
              const TextTranslated(
                'Бизнес',
                style: TextStyle(
                  fontSize: 6,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  height: 1,
                ),
              ),
            ],
          ],
        ),
      ),
    );

    if (onTap == null) return badge;

    return InkWell(
      borderRadius: BorderRadius.circular(6.r),
      onTap: onTap,
      child: badge,
    );
  }
}
