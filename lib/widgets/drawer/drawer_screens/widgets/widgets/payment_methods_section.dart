import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:optombai/widgets/drawer/premium_tariff.dart';
import 'package:optombai/widgets/translation/text_translated.dart';
import 'package:optombai/core/import_links.dart';

class PaymentMethodsSection extends StatelessWidget {
  final GlobalKey russiaKey;
  final GlobalKey globalCardKey;
  final GlobalKey kgKey;

  final VoidCallback onPay;

  final VoidCallback onPayRussia;

  final PremiumTariff selectedTariff;
  final ValueChanged<PremiumTariff> onTariffChanged;

  final VoidCallback onWhatsappTap;
  final VoidCallback onTelegramTap;
  final void Function(String url) onOpenUrl;

  final String Function(PremiumTariff tariff) priceLine;

  final String Function(PremiumTariff tariff) amountLine;

  final UserRegionUi regionUi;

  const PaymentMethodsSection({
    super.key,
    required this.selectedTariff,
    required this.onTariffChanged,
    required this.onWhatsappTap,
    required this.onTelegramTap,
    required this.onOpenUrl,
    required this.russiaKey,
    required this.globalCardKey,
    required this.kgKey,
    required this.onPay,
    required this.onPayRussia,
    required this.priceLine,
    required this.amountLine,
    required this.regionUi,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const TextTranslated(
          'Способ оплаты',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 12.h),
        if (regionUi == UserRegionUi.ru) ...[
          _RussiaPaymentCard(
            russiaKey: russiaKey,
            onWhatsappTap: onWhatsappTap,
            onTelegramTap: onTelegramTap,
          ),
        ] else if (regionUi == UserRegionUi.kg) ...[
          _KyrgyzstanFinikCard(
            kgKey: kgKey,
            priceLine: priceLine(selectedTariff),
            amountLine: amountLine(selectedTariff),
            onPay: onPay,
          ),
        ] else ...[
          _OtherFreedomCard(
            globalCardKey: globalCardKey,
            priceLine: priceLine(selectedTariff),
            amountLine: amountLine(selectedTariff),
            onPay: onPay,
          ),
        ],
      ],
    );
  }

}

class _PayButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const _PayButton({
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52.h,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            colors: [
              Color.fromARGB(255, 80, 104, 129),
              Color.fromRGBO(0, 4, 8, 1),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33007AFF),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          onPressed: onPressed,
          child: const Text(
                  'Оплатить',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
        ),
      ),
    );
  }
}

class _CopyRow extends StatelessWidget {
  final String text;
  final String copyValue;
  final String? label;
  final TextStyle? style;

  const _CopyRow({
    required this.text,
    required this.copyValue,
    this.label,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextTranslated(
            text,
            style: style ?? const TextStyle(fontSize: 13),
          ),
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          icon: const Icon(Icons.copy, size: 18),
          onPressed: () => _copy(context),
          tooltip: 'Копировать',
        ),
      ],
    );
  }

  void _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: copyValue));

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: TextTranslated(
          label == null ? 'Реквизиты скопированы' : '$label скопировано',
        ),
        duration: const Duration(milliseconds: 500),
      ),
    );
  }
}

class _KyrgyzstanFinikCard extends StatelessWidget {
  final GlobalKey kgKey;
  final String priceLine;
  final String amountLine;
  final VoidCallback onPay;

  const _KyrgyzstanFinikCard({
    required this.kgKey,
    required this.priceLine,
    required this.amountLine,
    required this.onPay,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      key: kgKey,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: const Color(0xffE9F7EF),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TextTranslated(
            'Оплата для граждан Кыргызстана 🇰🇬',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 8.h),
          const TextTranslated(
            'Оплата через Finik / QR / мобильные банковские приложения '
            '(MBank, Optima, Мой О! и другие). После оплаты подключение «Бизнес» автоматическое.',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 8.h),
          TextTranslated(
            'Текущий тариф: $priceLine',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 4.h),
          TextTranslated(
            'Сумма для оплаты: $amountLine',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.black54,
            ),
          ),
          SizedBox(height: 12.h),
          _PayButton(onPressed: onPay),
        ],
      ),
    );
  }
}

class _OtherFreedomCard extends StatelessWidget {
  final GlobalKey globalCardKey;
  final String priceLine;
  final String amountLine;
  final VoidCallback onPay;

  const _OtherFreedomCard({
    required this.globalCardKey,
    required this.priceLine,
    required this.amountLine,
    required this.onPay,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      key: globalCardKey,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: const Color(0xffF4F6FA),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TextTranslated(
            'Оплата для всех стран 🌎',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 8.h),
          const TextTranslated(
            'Оплачивайте подписку банковской картой через Freedom Pay. '
            'После оплаты подключение «Бизнес» автоматическое.',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 8.h),
          TextTranslated(
            'Текущий тариф: $priceLine',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 6.h),
          TextTranslated(
            'Сумма для списания: $amountLine',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.black54,
            ),
          ),
          SizedBox(height: 12.h),
          _PayButton(onPressed: onPay),
        ],
      ),
    );
  }
}

class _RussiaPaymentCard extends StatelessWidget {
  final GlobalKey russiaKey;
  final VoidCallback onWhatsappTap;
  final VoidCallback onTelegramTap;

  const _RussiaPaymentCard({
    required this.russiaKey,
    required this.onWhatsappTap,
    required this.onTelegramTap,
  });

  static const _gold = Color(0xFFD4AF37);
  static const _dark = Color(0xFF0B0F14);

  static const _titleStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: Colors.white,
  );

  static const _bodyStyle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: Color(0xFFC9CDD3),
  );

  static const _sectionStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: _gold,
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      key: russiaKey,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: _dark,
        border: Border.all(color: _gold.withValues(alpha: 0.35), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TextTranslated('Оплата для граждан России 🇷🇺', style: _titleStyle),
          SizedBox(height: 8.h),
          const TextTranslated(
            'В связи с санкциями автоматические платежи из России временно недоступны.',
            style: _bodyStyle,
          ),
          const TextTranslated(
            'Для активации подписки используйте безопасный способ оплаты через Сбербанк.',
            style: _bodyStyle,
          ),
          SizedBox(height: 12.h),
          const TextTranslated('💰 Тарифы', style: _sectionStyle),
          SizedBox(height: 6.h),
          const TextTranslated('• 922 ₽ — 7 дней', style: _bodyStyle),
          const TextTranslated('• 3072 ₽ — 30 дней', style: _bodyStyle),
          SizedBox(height: 12.h),
          const TextTranslated('📱 Оплата по номеру (Сбербанк)',
              style: _sectionStyle),
          const _CopyRow(
            text: '📞 +7 967 129 40 68',
            copyValue: '+79671294068',
            label: 'Номер телефона',
            style: _bodyStyle,
          ),
          SizedBox(height: 6.h),
          const TextTranslated('Получатель: Артур Азаматович А.', style: _bodyStyle),
          SizedBox(height: 12.h),
          const _CopyRow(
            text: '💳 2202 2084 1166 0096',
            copyValue: '2202208411660096',
            label: 'Номер карты',
            style: _bodyStyle,
          ),
          SizedBox(height: 6.h),
          const TextTranslated('Получатель: Артур Азаматович А.', style: _bodyStyle),
          SizedBox(height: 12.h),
          const TextTranslated('✔️ После оплаты отправьте администратору:',
              style: _sectionStyle),
          const TextTranslated('• Чек / скрин\n• Ваш логин или номер регистрации',
              style: _bodyStyle),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: onWhatsappTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff25D366),
                  ),
                  child: const TextTranslated(
                    '🟩 Отправить по WhatsApp',
                    maxLines: 2,
                    style: TextStyle(fontSize: 13, color: Colors.white),
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: ElevatedButton(
                  onPressed: onTelegramTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff0088CC),
                  ),
                  child: const TextTranslated(
                    '🔵 Отправить в Telegram',
                    maxLines: 2,
                    style: TextStyle(fontSize: 13, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

enum UserRegionUi { ru, kg, other }
