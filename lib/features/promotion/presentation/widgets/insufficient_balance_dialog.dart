import 'package:flutter/material.dart';
import 'package:optombai/app/router/app_router.dart';
import 'package:optombai/widgets/translation/text_translated.dart';
import 'package:provider/provider.dart';
import 'package:optombai/core/theme_notifier.dart';
import 'package:auto_route/auto_route.dart';

class InsufficientBalanceDialog extends StatelessWidget {
  final double requiredAmount;

  const InsufficientBalanceDialog({
    super.key,
    required this.requiredAmount,
  });

  static Future<void> show(BuildContext context, {required double requiredAmount}) {
    return showDialog(
      context: context,
      builder: (_) => InsufficientBalanceDialog(requiredAmount: requiredAmount),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.select((ThemeNotifier n) => n.isDarkMode);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: isDark ? const Color(0xff192536) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.account_balance_wallet,
                size: 48,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 16),
            TextTranslated(
              'Недостаточно средств',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            TextTranslated(
              'Для продвижения необходимо ${requiredAmount.toStringAsFixed(0)} сом',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white70 : Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.router.push(const PitRoute());
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff0095D5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const TextTranslated(
                  'Пополнить баланс',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: TextTranslated(
                'Позже',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white54 : Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
