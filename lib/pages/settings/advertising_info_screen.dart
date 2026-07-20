import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:optombai/widgets/translation/text_translated.dart';
import 'package:url_launcher/url_launcher.dart';

/// Marketing landing for in-app advertising, opened from Settings.
/// Intentionally always dark (matches the promo design), regardless of theme.
@RoutePage()
class AdvertisingInfoScreen extends StatelessWidget {
  const AdvertisingInfoScreen({super.key});

  static const _background = Color(0xFF0B0B12);
  static const _accent = Color(0xFF7B2FF2);

  // Same manager number used across the app (pit / law_data screens).
  static const String _whatsappUrl =
      'https://wa.me/996551947777?text=%D0%97%D0%B4%D1%80%D0%B0%D0%B2%D1%81%D1%82%D0%B2%D1%83%D0%B9%D1%82%D0%B5%2C%20%D1%85%D0%BE%D1%87%D1%83%20%D1%80%D0%B0%D0%B7%D0%BC%D0%B5%D1%81%D1%82%D0%B8%D1%82%D1%8C%20%D1%80%D0%B5%D0%BA%D0%BB%D0%B0%D0%BC%D1%83%20%D0%B2%20%D0%BF%D1%80%D0%B8%D0%BB%D0%BE%D0%B6%D0%B5%D0%BD%D0%B8%D0%B8';

  Future<void> _contactManager() async {
    final uri = Uri.parse(_whatsappUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20.w, 4.h, 20.w, 28.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _HeroSection(),
            SizedBox(height: 24.h),
            const Center(
              child: TextTranslated(
                'Где показывается реклама?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
            SizedBox(height: 16.h),
            const _PlacementsGrid(),
            SizedBox(height: 28.h),
            const TextTranslated(
              'Баннеры в популярных разделах приложения каждый день.',
              style:
                  TextStyle(fontSize: 15, height: 1.4, color: Colors.white70),
            ),
            SizedBox(height: 20.h),
            const _BenefitItem(
              icon: Icons.remove_red_eye_outlined,
              title: 'Максимальный охват',
              subtitle: 'Вашу рекламу увидят наши пользователи.',
            ),
            SizedBox(height: 18.h),
            const _BenefitItem(
              icon: Icons.link,
              title: 'Переходы на внешние ресурсы',
              subtitle:
                  'Ведите пользователей на ваш сайт, Instagram, Telegram и другие площадки.',
            ),
            SizedBox(height: 18.h),
            const _BenefitItem(
              icon: Icons.bolt_outlined,
              title: 'Никаких лишних шагов',
              subtitle:
                  'Реклама ведёт на внешние ресурсы, а не на страницы пользователей.',
            ),
            SizedBox(height: 28.h),
            _ContactManagerCard(onContact: _contactManager),
          ],
        ),
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  const _HeroSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: AdvertisingInfoScreen._accent.withValues(alpha: 0.7),
            ),
          ),
          child: const TextTranslated(
            'РЕКЛАМА В ПРИЛОЖЕНИИ',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
              color: Color(0xFFB388FF),
            ),
          ),
        ),
        SizedBox(height: 16.h),
        const TextTranslated(
          'Размещайте рекламу',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            height: 1.15,
            color: Colors.white,
          ),
        ),
        const TextTranslated(
          'и привлекайте клиентов',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            height: 1.15,
            color: Color(0xFF9B4DFF),
          ),
        ),
      ],
    );
  }
}

class _BenefitItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _BenefitItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 52.w,
          height: 52.w,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Icon(icon, color: AdvertisingInfoScreen._accent, size: 26),
        ),
        SizedBox(width: 14.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextTranslated(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 4.h),
              TextTranslated(
                subtitle,
                style: const TextStyle(
                  fontSize: 13.5,
                  height: 1.35,
                  color: Colors.white60,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PlacementsGrid extends StatelessWidget {
  const _PlacementsGrid();

  static const _placements = [
    (
      title: 'В ленте объявлений',
      subtitle: 'Среди объявлений на главной странице.',
      fullScreen: false,
    ),
    (
      title: 'Внутри всех категорий',
      subtitle: 'Среди объявлений во всех категориях.',
      fullScreen: false,
    ),
    (
      title: 'Внутри поиска',
      subtitle: 'Среди объявлений в разделе поиска.',
      fullScreen: false,
    ),
    (
      title: 'В видеоленте',
      subtitle: 'Полноэкранная реклама в разделе видеоленты.',
      fullScreen: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _placements.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12.h,
        crossAxisSpacing: 12.w,
        childAspectRatio: 0.62,
      ),
      itemBuilder: (context, index) {
        final placement = _placements[index];
        return _PlacementCard(
          title: placement.title,
          subtitle: placement.subtitle,
          fullScreenPreview: placement.fullScreen,
        );
      },
    );
  }
}

class _PlacementCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool fullScreenPreview;

  const _PlacementCard({
    required this.title,
    required this.subtitle,
    required this.fullScreenPreview,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(12.w, 14.h, 12.w, 0),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(
        children: [
          TextTranslated(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 6.h),
          TextTranslated(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11.5,
              height: 1.3,
              color: Colors.white54,
            ),
          ),
          SizedBox(height: 10.h),
          Expanded(child: _PhonePreview(fullScreenBanner: fullScreenPreview)),
        ],
      ),
    );
  }
}

/// Tiny stylized phone mock: grey placeholder rows around a purple ad
/// banner (or a full-screen ad when [fullScreenBanner] is true).
class _PhonePreview extends StatelessWidget {
  final bool fullScreenBanner;

  const _PhonePreview({required this.fullScreenBanner});

  static const _bannerGradient = LinearGradient(
    colors: [Color(0xFF4A148C), Color(0xFF7B2FF2)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFF14141D),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
        ),
        padding: const EdgeInsets.all(7),
        child: fullScreenBanner ? _fullScreenAd() : _feedWithBanner(),
      ),
    );
  }

  Widget _fullScreenAd() {
    return Container(
      decoration: BoxDecoration(
        gradient: _bannerGradient,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _adLabel(),
          const Spacer(),
          _lightBar(widthFactor: 0.8),
          const SizedBox(height: 4),
          _lightBar(widthFactor: 0.55),
          const SizedBox(height: 10),
          Container(
            height: 18,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _feedWithBanner() {
    return Column(
      children: [
        _placeholderRow(),
        const SizedBox(height: 5),
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: _bannerGradient,
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(7),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _adLabel(),
                const Spacer(),
                _lightBar(widthFactor: 0.85),
                const SizedBox(height: 4),
                _lightBar(widthFactor: 0.5),
              ],
            ),
          ),
        ),
        const SizedBox(height: 5),
        _placeholderRow(),
        const SizedBox(height: 5),
        _placeholderRow(),
      ],
    );
  }

  Widget _adLabel() {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const TextTranslated(
          'Реклама',
          style: TextStyle(fontSize: 7, color: Colors.white),
        ),
      ),
    );
  }

  Widget _lightBar({required double widthFactor}) {
    return FractionallySizedBox(
      alignment: Alignment.centerLeft,
      widthFactor: widthFactor,
      child: Container(
        height: 6,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
  }

  Widget _placeholderRow() {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 5),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 5,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(height: 3),
              FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: 0.6,
                child: Container(
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ContactManagerCard extends StatelessWidget {
  final VoidCallback onContact;

  const _ContactManagerCard({required this.onContact});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TextTranslated(
            'Готовы запустить рекламу?',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 6.h),
          const TextTranslated(
            'Свяжитесь с нашим менеджером — ответим на вопросы и подберём лучшее решение.',
            style: TextStyle(fontSize: 13.5, height: 1.4, color: Colors.white60),
          ),
          SizedBox(height: 14.h),
          SizedBox(
            width: double.infinity,
            height: 48.h,
            child: ElevatedButton.icon(
              onPressed: onContact,
              icon: const Icon(Icons.chat, size: 20),
              label: const TextTranslated(
                'Связаться с менеджером',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff25D366),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
