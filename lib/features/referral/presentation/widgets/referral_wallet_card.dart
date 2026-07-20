import 'package:auto_route/auto_route.dart';
import 'package:optombai/core/import_links.dart';
import 'package:optombai/app/router/app_router.dart';
import 'package:optombai/features/referral/data/models/referral_wallet_model.dart';

import 'package:optombai/features/referral/presentation/widgets/referral_card.dart';

class ReferralWalletCard extends StatelessWidget {
  const ReferralWalletCard({
    super.key,
    required this.wallet,
    this.currencies = const [],
  });

  final ReferralWalletModel wallet;
  final List<CurrencyModel> currencies;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Color primaryText = isDark ? Colors.white : Colors.black87;
    final Color secondaryText = isDark ? Colors.white70 : Colors.black54;
    final Color mutedText = isDark ? Colors.white70 : Colors.black54;

    final Color buttonBg = isDark ? const Color(0xFF2B2348) : const Color(0xFF1B1540);
    const Color buttonText = Colors.white;

    final userFlag = context.read<UserBloc>().state.user.country?.square_flag;

    final currencyName = currencies
            .where((c) => c.squareFlag == userFlag)
            .map((c) => c.name)
            .cast<String?>()
            .firstWhere((e) => e != null, orElse: () => '') ??
        '';

    return ReferralCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Реферальный баланс',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: secondaryText,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${wallet.balance} ${currencyName.toLowerCase()}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: primaryText,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Зарабатывайте 10% от всех приглашённых пользователей',
                  style: TextStyle(
                    fontSize: 12,
                    color: mutedText,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            height: 40,
            child: FilledButton(
              onPressed: () {
                context.router.push(const ReferralWithdrawlRoute());
              },
              style: FilledButton.styleFrom(
                backgroundColor: buttonBg,
                foregroundColor: buttonText,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: const Text(
                'Вывести',
                style: TextStyle(fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
