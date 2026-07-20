import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:optombai/features/referral/data/models/referral_profile_model.dart';
import 'package:share_plus/share_plus.dart';

import 'package:optombai/features/referral/presentation/widgets/referral_card.dart';

class ReferralProfileCard extends StatelessWidget {
  const ReferralProfileCard({
    super.key,
    required this.profile,
  });

  final ReferralProfileModel profile;

  String _buildAppReferralLink() {
    final code = Uri.encodeComponent(profile.promocode.trim());
    return 'optombai://register?referral_code=$code';
  }

  String _buildShareText() {
    final webLink = profile.referralLink.trim();
    final appLink = _buildAppReferralLink();
    return 'Присоединяйся по моей ссылке:\n$webLink\n\nЕсли приложение уже установлено:\n$appLink';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Color primaryText = isDark ? Colors.white : Colors.black87;
    final Color secondaryText = isDark ? Colors.white70 : Colors.black54;
    final Color mutedText = isDark ? Colors.white60 : Colors.black45;
    final Color iconColor = secondaryText;

    return ReferralCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ваш промокод',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: secondaryText,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SelectableText(
                profile.promocode,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: primaryText,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () async {
                  await Clipboard.setData(
                    ClipboardData(text: profile.promocode),
                  );
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Промокод скопирован')),
                  );
                },
                child: Icon(
                  Icons.copy,
                  size: 18,
                  color: iconColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Реферальная ссылка',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: mutedText,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: SelectableText(
                  profile.referralLink,
                  style: TextStyle(
                    fontSize: 13,
                    color: primaryText,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () async {
                  await Clipboard.setData(
                    ClipboardData(text: profile.referralLink),
                  );
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Ссылка скопирована')),
                  );
                },
                child: Icon(
                  Icons.copy,
                  size: 18,
                  color: iconColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              FilledButton(
                onPressed: () {
                  SharePlus.instance
                      .share(ShareParams(text: _buildShareText()));
                },
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF8146FF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                child: const Text(
                  'Поделиться ссылкой',
                  style: TextStyle(fontSize: 13),
                ),
              ),
              const Spacer(),
              Text(
                'Приглашено: ${profile.followersCount}',
                style: TextStyle(
                  fontSize: 12,
                  color: secondaryText,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
