import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:optombai/widgets/translation/text_translated.dart';
import 'package:flutter/material.dart';

class ProductRating extends StatelessWidget {
  const ProductRating({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(height: 8.h),
        chartRow(context, '5', 95),
        chartRow(context, '4', 65),
        chartRow(context, '3', 3),
        chartRow(context, '4', 5),
        chartRow(context, '1', 1),
        SizedBox(height: 8.h),
      ],
    );
  }

  Widget chartRow(BuildContext context, String label, int pct) {
    return Row(
      children: [
        TextTranslated(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
        ),
        SizedBox(width: 8.w),
        const Icon(
          Icons.star,
          color: Color(0xffFFA800),
          size: 25,
        ),
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(8, 0, 8, 0),
          child: Stack(children: [
            Container(
              width: MediaQuery.sizeOf(context).width * 0.65,
              height: 3.h,
              decoration: BoxDecoration(
                  color: Colors.black, borderRadius: BorderRadius.circular(20)),
              child: const TextTranslated(''),
            ),
            Container(
              width: MediaQuery.sizeOf(context).width * (pct / 100) * 0.65,
              height: 4.h,
              decoration: BoxDecoration(
                  color: const Color(0xffFFA800),
                  borderRadius: BorderRadius.circular(20)),
              child: const TextTranslated(''),
            ),
          ]),
        ),
        TextTranslated(
          '$pct%',
          style: const TextStyle(
              color: Color(0xff808080),
              fontSize: 15,
              fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
