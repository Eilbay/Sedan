import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:optombai/widgets/translation/text_translated.dart';
import 'package:optombai/core/theme_notifier.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

@RoutePage()
class ManagerContactScreen extends StatelessWidget {
  final double amount;

  const ManagerContactScreen({
    super.key,
    required this.amount,
  });

  static const String _whatsappUrl = 'https://wa.me/996551947777';
  static const String _telegramUrl = 'https://t.me/eldiiar';

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.select((ThemeNotifier n) => n.isDarkMode);

    return Scaffold(
      appBar: AppBar(
        title: const TextTranslated('Оплата через менеджера'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _AmountCard(amount: amount),
            SizedBox(height: 18.h),
            _InstructionsCard(isDark: isDark),
            SizedBox(height: 18.h),
            _ContactButtons(
              onWhatsApp: () => _launchUrl(_whatsappUrl),
              onTelegram: () => _launchUrl(_telegramUrl),
            ),
            SizedBox(height: 16.h),
            _AfterPaymentNote(isDark: isDark),
          ],
        ),
      ),
    );
  }
}

class _AmountCard extends StatelessWidget {
  final double amount;

  const _AmountCard({required this.amount});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xffFF9800), Color(0xffFF5722)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xffFF9800).withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const TextTranslated(
            'Сумма к оплате',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.white70,
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                amount.toStringAsFixed(0),
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 4.w),
              const TextTranslated(
                'сом',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InstructionsCard extends StatelessWidget {
  final bool isDark;

  const _InstructionsCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : const Color(0xffFFF8E1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xffFFE082)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline,
                  color: Color(0xffFF9800), size: 20),
              SizedBox(width: 8.w),
              TextTranslated(
                'Как оплатить',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF201D2A),
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          _StepItem(
              number: '1',
              text: 'Свяжитесь с менеджером в WhatsApp или Telegram',
              isDark: isDark),
          SizedBox(height: 6.h),
          _StepItem(
              number: '2',
              text: 'Получите реквизиты для перевода',
              isDark: isDark),
          SizedBox(height: 6.h),
          _StepItem(
              number: '3',
              text: 'Оплатите и отправьте чек менеджеру',
              isDark: isDark),
          SizedBox(height: 6.h),
          _StepItem(
              number: '4',
              text: 'Баланс будет зачислен после проверки',
              isDark: isDark),
        ],
      ),
    );
  }
}

class _StepItem extends StatelessWidget {
  final String number;
  final String text;
  final bool isDark;

  const _StepItem({
    required this.number,
    required this.text,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: const Color(0xffFF9800),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: TextTranslated(
            text,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white70 : const Color(0xFF201D2A),
            ),
          ),
        ),
      ],
    );
  }
}

class _ContactButtons extends StatelessWidget {
  final VoidCallback onWhatsApp;
  final VoidCallback onTelegram;

  const _ContactButtons({
    required this.onWhatsApp,
    required this.onTelegram,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 48.h,
          child: ElevatedButton.icon(
            onPressed: onWhatsApp,
            icon: const Icon(Icons.chat, size: 20),
            label: const TextTranslated(
              'Написать в WhatsApp',
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
        SizedBox(height: 10.h),
        SizedBox(
          width: double.infinity,
          height: 48.h,
          child: ElevatedButton.icon(
            onPressed: onTelegram,
            icon: const Icon(Icons.send, size: 20),
            label: const TextTranslated(
              'Написать в Telegram',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff0088CC),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 2,
            ),
          ),
        ),
      ],
    );
  }
}

class _AfterPaymentNote extends StatelessWidget {
  final bool isDark;

  const _AfterPaymentNote({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : const Color(0xffE8F5E9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xff81C784)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Color(0xff4CAF50), size: 22),
          SizedBox(width: 10.w),
          Expanded(
            child: TextTranslated(
              'Баланс будет зачислен в течение 5-15 минут после проверки',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white70 : const Color(0xFF201D2A),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
