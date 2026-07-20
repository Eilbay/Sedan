import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:optombai/widgets/translation/text_translated.dart';

class VerifiedBadge extends StatelessWidget {
  final VoidCallback? onTap;

  const VerifiedBadge({
    super.key,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const Color badgeColor = Color(0xFF3AA162);

    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: badgeColor, width: 1.w),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.verified,
            color: badgeColor,
            size: 16,
          ),
          SizedBox(width: 4.w),
          const TextTranslated(
            'Проверен',
            style: TextStyle(
              color: badgeColor,
              fontSize: 6,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return badge;

    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: onTap,
      child: badge,
    );
  }
}
