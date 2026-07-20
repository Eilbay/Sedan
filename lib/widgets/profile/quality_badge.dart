import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:optombai/widgets/translation/text_translated.dart';

enum QualityTier { gold, silver, bronze }

class QualityBadge extends StatelessWidget {
  final QualityTier tier;
  final VoidCallback? onTap;

  const QualityBadge({
    super.key,
    required this.tier,
    this.onTap,
  });

  String get _assetPath {
    switch (tier) {
      case QualityTier.gold:
        return 'assets/gold/gold.png';
      case QualityTier.silver:
        return 'assets/gold/silver.png';
      case QualityTier.bronze:
        return 'assets/gold/bronze.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    const borderColor = Color(0xFF3AA162);

    final badge = Container(
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 2.h),
      decoration: BoxDecoration(
        border: Border.all(color: borderColor, width: 1.w),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(_assetPath, width: 16.w, height: 16.w),
          SizedBox(width: 4.w),
          const TextTranslated(
            'Качество',
            style: TextStyle(
              color: borderColor,
              fontSize: 6,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
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

QualityTier? qualityTierForLevel(String level) {
  switch (level) {
    case "gold":
      return QualityTier.gold;
    case "silver":
      return QualityTier.silver;
    case "bronz":
      return QualityTier.bronze;
    default:
      return null;
  }
}
