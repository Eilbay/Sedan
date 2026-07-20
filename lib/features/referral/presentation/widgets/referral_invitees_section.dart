import 'package:flutter/material.dart';
import 'package:optombai/features/referral/data/models/referral_invitee_model.dart';
import 'package:optombai/widgets/translation/text_translated.dart';

import 'package:optombai/features/referral/presentation/widgets/referral_card.dart';

class ReferralInviteesSection extends StatelessWidget {
  const ReferralInviteesSection({
    super.key,
    required this.invitees,
  });

  final List<ReferralInviteeModel> invitees;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Color primary = isDark ? Colors.white : Colors.black87;
    final Color secondary = isDark ? Colors.white70 : Colors.black54;

    if (invitees.isEmpty) {
      return ReferralCard(
        child: Text(
          'Вы ещё никого не пригласили',
          style: TextStyle(
            color: secondary,
            fontSize: 13,
          ),
        ),
      );
    }

    return ReferralCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Приглашённые пользователи',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: primary,
            ),
          ),
          const SizedBox(height: 12),
          ...invitees.map(
            (i) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Text(
                          i.userName ?? i.user,
                          style: TextStyle(
                            color: primary,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 4),
                        if (i.userCountry?.isNotEmpty == true)
                          TextTranslated(
                            i.userCountry!,
                            style: const TextStyle(fontSize: 16),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'с ${i.createdAt.split(' ').first}',
                    style: TextStyle(
                      color: secondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
