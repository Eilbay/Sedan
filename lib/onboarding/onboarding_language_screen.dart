import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:optombai/bloc/language_bloc/language_bloc.dart';
import 'package:optombai/bloc/language_bloc/language_event.dart';
import 'package:optombai/bloc/language_bloc/language_state.dart';
import 'package:optombai/app/router/app_router.dart';
import 'package:optombai/widgets/translation/text_translated.dart';

@RoutePage()
class OnboardingLanguageScreen extends StatefulWidget {
  const OnboardingLanguageScreen({super.key});

  @override
  State<OnboardingLanguageScreen> createState() =>
      _OnboardingLanguageScreenState();
}

class _OnboardingLanguageScreenState extends State<OnboardingLanguageScreen> {
  bool _navigated = false;

  static const brandPrimary = Color(0xFF0097B2);

  void _goToHome({required bool startTour}) {
    if (!mounted || _navigated) return;
    _navigated = true;

    context.router.replaceAll([BottomNavRoute(startTour: startTour)]);
  }

  @override
  Widget build(BuildContext context) {
    final selectedLanguage = context.select<LanguageBloc, String>((bloc) {
      final state = bloc.state;
      return state is LanguageChangedState ? state.language : 'ru';
    });

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF95C6E5), Color(0xFFEDE7F6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          bottom: true,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 6.h),
                Center(
                  child: Column(
                    children: [
                      Image.asset("assets/pro2.png", height: 54.h),
                      SizedBox(height: 8.h),
                      Text(
                        'Sedan',
                        style: TextStyle(
                          fontSize: 28.sp,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF111827),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 14.h),
                TextTranslated(
                  'Добро пожаловать в Sedan!',
                  style:
                      TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w800),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 6.h),
                TextTranslated(
                  'Выберите язык, чтобы продолжить.',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: const Color(0xFF374151),
                    height: 1.25,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 14.h),
                Expanded(
                  child: _LanguageList(
                    selectedLanguage: selectedLanguage,
                    onChanged: (code) => context
                        .read<LanguageBloc>()
                        .add(ChangeLanguageEvent(code)),
                  ),
                ),
                SizedBox(height: 14.h),
                SizedBox(
                  height: 54.h,
                  child: ElevatedButton(
                    onPressed: () => _goToHome(startTour: true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: brandPrimary,
                      shape: const StadiumBorder(),
                      elevation: 0,
                    ),
                    child: TextTranslated(
                      'Далее',
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LanguageList extends StatelessWidget {
  final String selectedLanguage;
  final ValueChanged<String> onChanged;

  const _LanguageList({
    required this.selectedLanguage,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    const languages = [
      {'flag': '🇷🇺', 'code': 'ru', 'name': 'Русский'},
      {'flag': '🇺🇸', 'code': 'en', 'name': 'English'},
      {'flag': '🇩🇪', 'code': 'de', 'name': 'Deutsch'},
      {'flag': '🇹🇷', 'code': 'tr', 'name': 'Türkçe'},
      {'flag': '🇨🇳', 'code': 'zh-cn', 'name': '中文'},
      {'flag': '🇰🇬', 'code': 'ky', 'name': 'Кыргызча'},
    ];

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [BoxShadow(blurRadius: 16, color: Color(0x22000000))],
      ),
      child: ListView.separated(
        physics: const BouncingScrollPhysics(),
        itemCount: languages.length,
        separatorBuilder: (_, __) => SizedBox(height: 10.h),
        itemBuilder: (_, i) {
          final l = languages[i];
          final code = l['code']!;
          final active = code == selectedLanguage;

          return InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => onChanged(code),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: active ? const Color(0x140097B2) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: active
                      ? const Color(0xFF0097B2)
                      : const Color(0x11000000),
                ),
              ),
              child: Row(
                children: [
                  Text(l['flag']!, style: TextStyle(fontSize: 24.sp)),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      l['name']!,
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                        color: const Color(0xFF111827),
                      ),
                    ),
                  ),
                  if (active)
                    const Icon(
                      Icons.check_circle,
                      color: Color(0xFF0097B2),
                      size: 22,
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
