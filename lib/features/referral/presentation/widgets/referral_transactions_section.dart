import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:optombai/bloc/user_bloc/user_bloc.dart';
import 'package:optombai/data/models/currency/currency_model.dart';
import 'package:optombai/features/referral/data/models/referral_transaction_model.dart';

import 'package:optombai/features/referral/presentation/widgets/referral_card.dart';

class ReferralTransactionsSection extends StatelessWidget {
  const ReferralTransactionsSection({
    super.key,
    required this.transactions,
    this.currencies = const [],
  });

  final List<ReferralTransactionModel> transactions;
  final List<CurrencyModel> currencies;

  String _typeToReadable(String type) {
    switch (type) {
      case 'subscription':
        return 'покупка подписки';
      case 'ad_wallet':
        return 'пополнение рекламного кошелька';
      default:
        return type;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Color primary = isDark ? Colors.white : Colors.black87;
    final Color secondary = isDark ? Colors.white70 : Colors.black54;
    final Color dateColor = isDark ? Colors.white60 : Colors.black45;
    const Color positive = Color(0xFF22C55E);

    final userFlag = context.read<UserBloc>().state.user.country?.square_flag;

    final currencyName = currencies
            .where((c) => c.squareFlag == userFlag)
            .map((c) => c.name)
            .cast<String?>()
            .firstWhere((e) => e != null, orElse: () => '') ??
        '';

    if (transactions.isEmpty) {
      return ReferralCard(
        child: Text(
          'Начислений пока нет',
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
            'История начислений',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: primary,
            ),
          ),
          const SizedBox(height: 12),
          ...transactions.map(
            (t) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${t.walletUsername} — ${_typeToReadable(t.type)}',
                          style: TextStyle(
                            color: primary,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          t.createdAt.split(' ').first,
                          style: TextStyle(
                            color: dateColor,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '+${t.amount} ${currencyName.toLowerCase()}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: positive,
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
