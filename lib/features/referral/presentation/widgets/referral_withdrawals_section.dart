import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:optombai/bloc/user_bloc/user_bloc.dart';
import 'package:optombai/data/models/currency/currency_model.dart';
import 'package:optombai/features/referral/data/models/referral_withdrawal_model.dart';
import 'package:optombai/features/referral/presentation/widgets/referral_card.dart';

class ReferralWithdrawalsSection extends StatelessWidget {
  const ReferralWithdrawalsSection({
    super.key,
    required this.withdrawals,
    this.currencies = const [],
  });

  final List<ReferralWithdrawalModel> withdrawals;
  final List<CurrencyModel> currencies;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color secondary = isDark ? Colors.white70 : Colors.black54;

    if (withdrawals.isEmpty) {
      return ReferralCard(
        child: Text(
          'Вы ещё не оформляли заявки на вывод',
          style: TextStyle(
            color: secondary,
            fontSize: 13,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...withdrawals.map(
          (w) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: _WithdrawalHistoryItem(withdrawal: w, currencies: currencies),
          ),
        ),
      ],
    );
  }
}

class _WithdrawalHistoryItem extends StatelessWidget {
  const _WithdrawalHistoryItem({
    required this.withdrawal,
    this.currencies = const [],
  });

  final ReferralWithdrawalModel withdrawal;
  final List<CurrencyModel> currencies;

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'done':
        return const Color(0xFF22C55E);

      case 'processing':
        return const Color(0xFF3B82F6);

      case 'requested':
        return const Color(0xFFF59E0B);

      case 'cancelled':
        return const Color(0xFFEF4444);

      default:
        return const Color(0xFF9CA3AF);
    }
  }

  String _statusText(String status) {
    switch (status.toLowerCase()) {
      case 'done':
        return 'Выплачено';

      case 'requested':
        return 'Запрошено';

      case 'processing':
        return 'В обработке';

      case 'cancelled':
        return 'Отменено';

      default:
        return 'Неизвестно';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Color cardBg = isDark ? const Color(0xFF141026) : const Color(0xFFF6F7FF);
    final Color borderColor = isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.08);

    final Color primary = isDark ? Colors.white : Colors.black87;
    final Color dateColor = isDark ? Colors.white70 : Colors.black54;
    final Color iconMuted = isDark ? Colors.white38 : Colors.black38;

    final statusColor = _statusColor(withdrawal.status);

    final userFlag = context.read<UserBloc>().state.user.country?.square_flag;

    final currencyName = currencies
            .where((c) => c.squareFlag == userFlag)
            .map((c) => c.name)
            .cast<String?>()
            .firstWhere((e) => e != null, orElse: () => '') ??
        '';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.circle,
                size: 9,
                color: Color(0xFFFACC15),
              ),
              const SizedBox(width: 8),
              Text(
                withdrawal.createdAt,
                style: TextStyle(
                  color: dateColor,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '•',
                style: TextStyle(color: iconMuted),
              ),
              const SizedBox(width: 6),
              Text(
                '${withdrawal.amount.toStringAsFixed(0)} ${currencyName.toLowerCase()}',
                style: TextStyle(
                  color: primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: iconMuted,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _statusText(withdrawal.status),
            style: TextStyle(
              color: statusColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
