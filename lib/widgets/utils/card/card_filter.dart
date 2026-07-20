import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CardFilter extends StatelessWidget {
  final Widget child;
  const CardFilter({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46.h,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xffDEDEDE))),
      alignment: Alignment.center,
      child: child,
    );
  }
}
