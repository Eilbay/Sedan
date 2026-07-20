import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:optombai/widgets/app_scaffold/custom_scaffold.dart';
import 'package:optombai/widgets/bottom_nav.dart';
import 'package:optombai/widgets/translation/text_translated.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

@RoutePage()
class InfoScreen extends StatelessWidget {
  final String title;
  final String text;

  const InfoScreen({
    super.key,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
        bottomNavigationBar: const BottomNav(
          currentIndexOverride: -1,
          passive: true,
        ),
        title: '',
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 30.h,
                ),
                TextTranslated(
                  title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                SizedBox(
                  height: 40.h,
                ),
                Container(
                  width: double.infinity,
                  height: 243.h,
                  color: const Color(0xffD9D9D9),
                ),
                SizedBox(
                  height: 23.h,
                ),
                TextTranslated(
                  text,
                  style: const TextStyle(fontSize: 14),
                  textAlign: TextAlign.start,
                ),
                SizedBox(
                  height: 10.h,
                ),
              ],
            ),
          ),
        ));
  }
}
