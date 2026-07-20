import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:optombai/features/live_stream/presentation/logic/stream_ban_cubit.dart';

class BanUserBottomSheet extends StatelessWidget {
  const BanUserBottomSheet({
    super.key,
    required this.username,
    required this.userId,
    required this.onBanned,
  });

  final String username;
  final String userId;
  final void Function(String banLabel) onBanned;

  static const _durations = [
    (label: '1 час', minutes: 60),
    (label: '24 часа', minutes: 1440),
    (label: 'Навсегда', minutes: null),
  ];

  static Future<void> show(
    BuildContext context, {
    required String username,
    required String userId,
    required ScaffoldMessengerState messenger,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (_) => BlocProvider.value(
        value: context.read<StreamBanCubit>(),
        child: BanUserBottomSheet(
          username: username,
          userId: userId,
          onBanned: (label) {
            messenger.showSnackBar(
              SnackBar(
                content: Text(
                  '@$username заблокирован на $label',
                  style: const TextStyle(color: Colors.white),
                ),
                backgroundColor: const Color(0xFF1C1C1E),
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 3),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _ban(BuildContext context, int? minutes, String label) async {
    final cubit = context.read<StreamBanCubit>();
    await cubit.banUser(userId, minutes: minutes);
    if (context.mounted) {
      Navigator.of(context).pop();
      onBanned(label);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final border = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.07);
    final handle = isDark
        ? Colors.white.withValues(alpha: 0.15)
        : Colors.black.withValues(alpha: 0.12);
    final textPrimary = isDark ? Colors.white : const Color(0xFF111827);
    final textSecondary = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
    final divider = isDark
        ? Colors.white.withValues(alpha: 0.07)
        : Colors.black.withValues(alpha: 0.06);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: border),
          boxShadow: [
            BoxShadow(
              blurRadius: 24,
              offset: const Offset(0, 8),
              color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            // Drag handle
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: handle,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF004D).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.block_rounded,
                      color: Color(0xFFFF004D),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Заблокировать @$username',
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Выбери длительность блокировки',
                          style: TextStyle(
                            color: textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Divider(height: 1, color: divider),

            // Duration buttons — tap = immediate ban
            BlocBuilder<StreamBanCubit, StreamBanState>(
              buildWhen: (prev, curr) => prev.isLoading != curr.isLoading,
              builder: (ctx, state) {
                if (state.isLoading) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: CircularProgressIndicator(
                      color: Color(0xFFFF004D),
                      strokeWidth: 2.5,
                    ),
                  );
                }
                return Column(
                  children: _durations.map((d) {
                    return _DurationTile(
                      label: d.label,
                      textPrimary: textPrimary,
                      divider: divider,
                      isLast: d == _durations.last,
                      onTap: () => _ban(ctx, d.minutes, d.label),
                    );
                  }).toList(),
                );
              },
            ),

            // Error
            BlocBuilder<StreamBanCubit, StreamBanState>(
              buildWhen: (prev, curr) => prev.error != curr.error,
              builder: (ctx, state) {
                if (state.error == null) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: Text(
                    'Ошибка: ${state.error}',
                    style: const TextStyle(
                        color: Color(0xFFEF4444), fontSize: 12),
                  ),
                );
              },
            ),

            // Cancel
            Divider(height: 1, color: divider),
            InkWell(
              onTap: () => Navigator.of(context).pop(),
              borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(18)),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(
                    'Отмена',
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DurationTile extends StatelessWidget {
  const _DurationTile({
    required this.label,
    required this.textPrimary,
    required this.divider,
    required this.isLast,
    required this.onTap,
  });

  final String label;
  final Color textPrimary;
  final Color divider;
  final bool isLast;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: label == 'Навсегда'
                          ? const Color(0xFFFF004D)
                          : textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: textPrimary.withValues(alpha: 0.3),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        if (!isLast) Divider(height: 1, color: divider, indent: 20),
      ],
    );
  }
}
