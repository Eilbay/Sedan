import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:optombai/widgets/translation/text_translated.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:optombai/configs/app_color.dart';
import 'package:optombai/core/theme_notifier.dart';

class EmptyProductCard extends StatelessWidget {
  const EmptyProductCard(
      {super.key,
      required this.title,
      required this.subTitle,
      required this.width,
      required this.height,
      required this.image,
      this.child});

  final String title;
  final String subTitle;
  final String image;
  final double width;
  final double height;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    bool stateSwitch = context.select((ThemeNotifier n) => n.isDarkMode);

    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: stateSwitch
                  ? const Color(0xff0e1e33)
                  : Colors.grey.withValues(alpha: 0.5),
              spreadRadius: 3,
              blurRadius: 4,
              offset: const Offset(0, 3),
            ),
          ],
          borderRadius: BorderRadius.circular(10),
          color: stateSwitch ? const Color(0xff101A29) : const Color(0xffEDF3FF)
          // color: Colors.white,
          ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextTranslated(
            title,
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w700, color: activeColor),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 10.h),
          Flexible(
            child: Image(
              image: AssetImage(image),
              height: 70.h,
              fit: BoxFit.contain,
            ),
          ),
          SizedBox(height: 10.h),
          TextTranslated(
            subTitle,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (child != null) ...[
            SizedBox(height: 6.h),
            child!,
          ],
        ],
      ),
    );
  }
}

class EmptyComment extends StatelessWidget {
  const EmptyComment(
      {super.key,
      required this.subTitle,
      required this.image,
      required this.height});

  final String subTitle;
  final String image;
  final double height;

  @override
  Widget build(BuildContext context) {
    bool stateSwitch = context.select((ThemeNotifier n) => n.isDarkMode);

    return Container(
      width: double.infinity,
      height: height,
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: stateSwitch
                  ? const Color(0xff0e1e33)
                  : Colors.grey.withValues(alpha: 0.5),
              spreadRadius: 3,
              blurRadius: 4,
              offset: const Offset(0, 3),
            ),
          ],
          borderRadius: BorderRadius.circular(10),
          color: stateSwitch ? const Color(0xff101A29) : const Color(0xffEDF3FF)
          // color: Colors.white,
          ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: 10.h),
          Image(
            image: AssetImage(image),
            width: 70.w,
            height: 70.h,
            fit: BoxFit.cover,
          ),
          SizedBox(height: 6.h),
          TextTranslated(
            subTitle,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600, color: activeColor),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
