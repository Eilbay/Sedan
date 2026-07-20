import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:optombai/widgets/translation/text_translated.dart';

enum PitPaymentMethod { finik, freedom, iap, manager }

class PitMethodSelector extends StatelessWidget {
  final PitPaymentMethod selectedMethod;
  final ValueChanged<PitPaymentMethod> onMethodSelected;
  final bool isDarkMode;
  final bool isHiddenMode;

  final Set<PitPaymentMethod> available;

  const PitMethodSelector({
    super.key,
    required this.selectedMethod,
    required this.onMethodSelected,
    required this.isDarkMode,
    required this.available,
    this.isHiddenMode = false,
  });

  bool _enabled(PitPaymentMethod m) => available.contains(m);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextTranslated(
          'Способ оплаты',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.white : const Color(0xFF201D2A),
          ),
        ),
        SizedBox(height: 10.h),
        // KG mobile-app + universal card payment are open to every user
        // (no `isHiddenMode` gating) — the backend itself accepts both flows
        // from any region, so hiding them by remote-config only obscures
        // the option without changing what the server allows.
        _PitMethodTile(
          title: 'Оплата через моб. приложения Кыргызстана 🇰🇬',
          subtitle: 'MBank, Optima, O!Bank и другие',
          icons: const [
            'assets/cards/mbank.png',
            'assets/cards/optimabank.png',
            'assets/cards/obank.png',
          ],
          isSelected: selectedMethod == PitPaymentMethod.finik,
          isDarkMode: isDarkMode,
          enabled: _enabled(PitPaymentMethod.finik),
          onTap: () => onMethodSelected(PitPaymentMethod.finik),
        ),
        SizedBox(height: 8.h),
        _PitMethodTile(
          title: 'Оплата для всех стран по карте 🌎',
          subtitle: 'Visa, Mastercard, Элкарт',
          icons: const [
            'assets/cards/visa.png',
            'assets/cards/mastercard2.png',
            'assets/cards/elcart.png',
          ],
          isSelected: selectedMethod == PitPaymentMethod.freedom,
          isDarkMode: isDarkMode,
          enabled: _enabled(PitPaymentMethod.freedom),
          onTap: () => onMethodSelected(PitPaymentMethod.freedom),
        ),
        SizedBox(height: 8.h),
        _PitMethodTile(
          title: 'App Store / Google Play',
          subtitle: 'Оплата через Apple Pay, Google Pay',
          icons: const [],
          isSelected: selectedMethod == PitPaymentMethod.iap,
          isDarkMode: isDarkMode,
          enabled: true,
          showSoonBadge: !_enabled(PitPaymentMethod.iap),
          onTap: () => onMethodSelected(PitPaymentMethod.iap),
          showIAPIcons: true,
        ),
        if (!isHiddenMode) ...[
          SizedBox(height: 8.h),
          _PitMethodTile(
            title: 'Через менеджера для России 🇷🇺',
            subtitle: 'Перевод + подтверждение',
            icons: const [],
            isSelected: selectedMethod == PitPaymentMethod.manager,
            isDarkMode: isDarkMode,
            enabled: true,
            onTap: () => onMethodSelected(PitPaymentMethod.manager),
            showManagerIcon: true,
          ),
        ],
      ],
    );
  }
}

class _PitMethodTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<String> icons;
  final bool isSelected;
  final bool isDarkMode;
  final VoidCallback onTap;

  final bool enabled;
  final bool showSoonBadge;

  final bool showManagerIcon;
  final bool showIAPIcons;

  const _PitMethodTile({
    required this.title,
    required this.subtitle,
    required this.icons,
    required this.isSelected,
    required this.isDarkMode,
    required this.onTap,
    required this.enabled,
    this.showSoonBadge = false,
    this.showManagerIcon = false,
    this.showIAPIcons = false,
  });

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xff0095D5);

    final borderColor = isSelected ? primary : (isDarkMode ? Colors.white24 : Colors.grey.shade300);

    final bgColor = isSelected
        ? primary.withValues(alpha: 0.06)
        : (isDarkMode ? Colors.white.withValues(alpha: 0.05) : Colors.white);

    final contentOpacity = enabled ? 1.0 : 0.45;

    return Stack(
      children: [
        Opacity(
          opacity: contentOpacity,
          child: InkWell(
            onTap: enabled ? onTap : null,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: bgColor,
                border: Border.all(color: borderColor, width: 1.3),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDarkMode ? Colors.white : const Color(0xFF201D2A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDarkMode ? Colors.white60 : const Color(0xFF77788A),
                          ),
                        ),
                        if (icons.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: icons.map((p) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: Container(
                                  width: 40,
                                  height: 26,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(6),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.04),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: Image.asset(p, fit: BoxFit.contain),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                        if (showIAPIcons) ...[
                          const SizedBox(height: 8),
                          const Row(
                            children: [
                              _ApplePayIcon(),
                              SizedBox(width: 6),
                              _GooglePayIcon(),
                            ],
                          ),
                        ],
                        if (showManagerIcon) ...[
                          const SizedBox(height: 8),
                          const Row(
                            children: [
                              _SberbankIcon(),
                              SizedBox(width: 6),
                              _WhatsAppIcon(),
                              SizedBox(width: 6),
                              _TelegramIcon(),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                    color: isSelected ? primary : (isDarkMode ? Colors.white38 : Colors.grey.shade400),
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (!enabled || showSoonBadge)
          Positioned(
            top: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Скоро',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _WhatsAppIcon extends StatelessWidget {
  const _WhatsAppIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: const Color(0xff25D366),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Icon(Icons.chat, color: Colors.white, size: 16),
    );
  }
}

class _TelegramIcon extends StatelessWidget {
  const _TelegramIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: const Color(0xff0088CC),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Icon(Icons.send, color: Colors.white, size: 16),
    );
  }
}

class _ApplePayIcon extends StatelessWidget {
  const _ApplePayIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 26,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Center(
        child: Icon(Icons.apple, color: Colors.white, size: 18),
      ),
    );
  }
}

class _GooglePayIcon extends StatelessWidget {
  const _GooglePayIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 26,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Center(
        child: Text(
          'G',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xff4285F4),
          ),
        ),
      ),
    );
  }
}

class _SberbankIcon extends StatelessWidget {
  const _SberbankIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: SvgPicture.asset(
          'assets/cards/sberbank.svg',
          fit: BoxFit.contain,
          colorFilter: const ColorFilter.mode(
            Color(0xff21A038),
            BlendMode.srcIn,
          ),
        ),
      ),
    );
  }
}
