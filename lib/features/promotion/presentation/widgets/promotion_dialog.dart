import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:optombai/core/di/injection.dart';
import 'package:optombai/core/theme_notifier.dart';
import 'package:optombai/features/promotion/domain/repository/promotion_repository.dart';
import 'package:optombai/features/promotion/presentation/logic/promotion_cubit.dart';
import 'package:optombai/features/promotion/presentation/widgets/insufficient_balance_dialog.dart';
import 'package:optombai/widgets/translation/text_translated.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PromotionDialog extends StatelessWidget {
  final String postId;
  final String productName;
  final SharedPreferences preferences;
  final bool isAlreadyPromoted;
  final DateTime? promoEndAt;

  const PromotionDialog({
    super.key,
    required this.postId,
    required this.productName,
    required this.preferences,
    this.isAlreadyPromoted = false,
    this.promoEndAt,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String postId,
    required String productName,
    required SharedPreferences preferences,
    bool isAlreadyPromoted = false,
    DateTime? promoEndAt,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => BlocProvider(
        create: (_) => PromotionCubit(
          repository: getIt<PromotionRepository>(),
          preferences: getIt<SharedPreferences>(),
        )..loadForPost(
            postId,
            isAlreadyPromoted: isAlreadyPromoted,
            promoEndAt: promoEndAt,
          ),
        child: PromotionDialog(
          postId: postId,
          productName: productName,
          preferences: preferences,
          isAlreadyPromoted: isAlreadyPromoted,
          promoEndAt: promoEndAt,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.select((ThemeNotifier n) => n.isDarkMode);

    return BlocConsumer<PromotionCubit, PromotionState>(
      listener: (context, state) {
        if (state.status == PromotionStatus.insufficientBalance &&
            state.packages.isNotEmpty) {
          Navigator.pop(context, false);
          InsufficientBalanceDialog.show(context,
              requiredAmount: state.totalPrice);
        }
      },
      builder: (context, state) {
        if (state.status == PromotionStatus.loading && state.packages.isEmpty) {
          return _PromotionLoadingDialog(isDark: isDark);
        }

        if (state.packages.isEmpty) {
          return _PromotionErrorDialog(
            isDark: isDark,
            error: state.errorMessage,
          );
        }

        if (!state.canPromote) {
          return _AlreadyPromotingDialog(isDark: isDark, state: state);
        }

        return _PromotionMainDialog(
          isDark: isDark,
          state: state,
          postId: postId,
          productName: productName,
        );
      },
    );
  }

}

// -- Private helper functions shared across promotion widgets --

String _getDaysWord(int days) {
  if (days % 10 == 1 && days % 100 != 11) {
    return 'день';
  } else if ([2, 3, 4].contains(days % 10) &&
      ![12, 13, 14].contains(days % 100)) {
    return 'дня';
  } else {
    return 'дней';
  }
}

String _formatDate(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
}

String _formatNumber(int number) {
  if (number >= 1000) {
    return '${(number / 1000).toStringAsFixed(1)}K';
  }
  return number.toString();
}

class _PromotionLoadingDialog extends StatelessWidget {
  final bool isDark;

  const _PromotionLoadingDialog({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: isDark ? const Color(0xff192536) : Colors.white,
      child: const Padding(
        padding: EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Color(0xff0095D5)),
            SizedBox(height: 16),
            TextTranslated('Загрузка...'),
          ],
        ),
      ),
    );
  }
}

class _PromotionErrorDialog extends StatelessWidget {
  final bool isDark;
  final String? error;

  const _PromotionErrorDialog({
    required this.isDark,
    required this.error,
  });

  @override
  Widget build(BuildContext context) {
    final isInsufficientBalance = (error != null &&
            (error!.contains('Недостаточно средств') ||
                error!.contains('insufficient') ||
                error!.toLowerCase().contains('balance'))) ||
        context.read<PromotionCubit>().state.status ==
            PromotionStatus.insufficientBalance;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: isDark ? const Color(0xff192536) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isInsufficientBalance
                  ? Icons.account_balance_wallet
                  : Icons.error_outline,
              size: 48,
              color: isInsufficientBalance ? Colors.orange : Colors.red,
            ),
            const SizedBox(height: 16),
            TextTranslated(
              error ?? 'Не удалось загрузить данные',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            if (isInsufficientBalance) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, false);
                    InsufficientBalanceDialog.show(context, requiredAmount: 0);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff0095D5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const TextTranslated(
                    'Пополнить баланс',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context, false),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const TextTranslated('Закрыть'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlreadyPromotingDialog extends StatelessWidget {
  final bool isDark;
  final PromotionState state;

  const _AlreadyPromotingDialog({
    required this.isDark,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final campaign = state.activeCampaignForCurrentPost!;
    final daysLeft = campaign.daysRemaining;

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
                Icons.trending_up,
                size: 48,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 16),
            TextTranslated(
              'Товар уже продвигается',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            TextTranslated(
              'Осталось $daysLeft ${_getDaysWord(daysLeft)}',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white70 : Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'До ${_formatDate(campaign.endedAt)}',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white54 : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context, false),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const TextTranslated('Понятно'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PromotionMainDialog extends StatelessWidget {
  final bool isDark;
  final PromotionState state;
  final String postId;
  final String productName;

  const _PromotionMainDialog({
    required this.isDark,
    required this.state,
    required this.postId,
    required this.productName,
  });

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PromotionCubit>();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: isDark ? const Color(0xff192536) : Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xff0095D5).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.trending_up,
                      color: Color(0xff0095D5),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextTranslated(
                          'Выберите план продвижения',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          productName.length > 30
                              ? '${productName.substring(0, 30)}...'
                              : productName,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.white54 : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context, false),
                    icon: Icon(
                      Icons.close,
                      color: isDark ? Colors.white54 : Colors.grey,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.blue.withValues(alpha: 0.1)
                      : Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 20,
                      color:
                          isDark ? Colors.blue.shade300 : Colors.blue.shade700,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextTranslated(
                        'Товар будет показываться во всех разделах: топы категорий, главная, поиск',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? Colors.blue.shade200
                              : Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              TextTranslated(
                'Доступные планы:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: state.packages.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final package = state.packages[index];
                  final isSelected = state.selectedPackage?.id == package.id;

                  return _PackageCard(
                    package: package,
                    isSelected: isSelected,
                    isDark: isDark,
                    onTap: () => cubit.selectPackage(package),
                  );
                },
              ),
              const SizedBox(height: 24),
              if (state.selectedPackage != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xff0095D5).withValues(alpha: 0.15)
                        : const Color(0xff0095D5).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xff0095D5).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextTranslated(
                            'К оплате:',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                          Text(
                            '${state.selectedPackage!.priceTotal.toStringAsFixed(0)} ${state.selectedPackage!.currency}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xff0095D5),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextTranslated(
                            'Ожидаемый охват:',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.white54 : Colors.grey,
                            ),
                          ),
                          Text(
                            '${_formatNumber(state.selectedPackage!.reachMin)} - ${_formatNumber(state.selectedPackage!.reachMax)}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
              // Display error if present
              if (state.status == PromotionStatus.error &&
                  state.errorMessage != null) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.red.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 20,
                        color: Colors.red.shade600,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextTranslated(
                          state.errorMessage!,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.red.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: state.isLoading
                          ? null
                          : () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(
                          color: isDark ? Colors.white24 : Colors.grey.shade400,
                        ),
                      ),
                      child: TextTranslated(
                        'Отмена',
                        style: TextStyle(
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed:
                          state.isLoading || state.selectedPackage == null
                              ? null
                              : () async {
                                  final success =
                                      await cubit.createCampaign(postId);
                                  // The success toast is shown by the caller
                                  // after this dialog's route is fully gone —
                                  // showing it here, on the context of the
                                  // route being popped, left it stuck.
                                  if (success && context.mounted) {
                                    Navigator.pop(context, true);
                                  }
                                },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff0095D5),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: state.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const TextTranslated(
                              'Продвинуть',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PackageCard extends StatelessWidget {
  final dynamic package;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _PackageCard({
    required this.package,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xff0095D5).withValues(alpha: 0.1)
              : isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.grey.shade50,
          border: Border.all(
            color: isSelected
                ? const Color(0xff0095D5)
                : isDark
                    ? Colors.white24
                    : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        package.name,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      if (package.description != null &&
                          (package.description as String).isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            package.description,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white54 : Colors.grey,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xff0095D5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${package.priceTotal.toStringAsFixed(0)} ${package.currency}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: isDark ? Colors.white54 : Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${package.days} ${_getDaysWord(package.days)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Icon(
                      Icons.visibility,
                      size: 16,
                      color: Colors.green.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${_formatNumber(package.reachMin)}-${_formatNumber(package.reachMax)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
