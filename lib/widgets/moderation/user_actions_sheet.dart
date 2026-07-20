import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:optombai/bloc/block_bloc/block_bloc.dart';
import 'package:optombai/core/theme_notifier.dart';
import 'package:optombai/data/models/report/report_target_type.dart';
import 'package:optombai/widgets/moderation/report_bottom_sheet.dart';
import 'package:optombai/widgets/translation/text_translated.dart';
import 'package:optombai/widgets/utils/message_show.dart';

/// Action sheet with moderation actions for a single target user / content
/// item. Composed of optional rows: Report, Block / Unblock.
///
/// Reuse via [UserActionsSheet.show] to keep callers concise.
class UserActionsSheet extends StatelessWidget {
  final String userId;
  final String username;
  final ReportTargetType reportTargetType;
  final String reportTargetId;

  /// Optional: host handles post-report removal itself (e.g. reels viewer
  /// drops the reel + advances, without leaving the screen). Forwarded to
  /// [ReportBottomSheet].
  final VoidCallback? onReported;

  const UserActionsSheet({
    super.key,
    required this.userId,
    required this.username,
    required this.reportTargetType,
    required this.reportTargetId,
    this.onReported,
  });

  /// Opens the sheet. [reportTargetId] is the id of the *content* being acted
  /// on (post id, stream id, message id). Pass [userId] for the user behind
  /// it — used by the "Block author" action and by the also_block toggle in
  /// the report sheet.
  static Future<void> show(
    BuildContext context, {
    required String userId,
    required String username,
    required ReportTargetType reportTargetType,
    required String reportTargetId,
    VoidCallback? onReported,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => UserActionsSheet(
        userId: userId,
        username: username,
        reportTargetType: reportTargetType,
        reportTargetId: reportTargetId,
        onReported: onReported,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.select((ThemeNotifier n) => n.isDarkMode);
    final bgColor = isDarkMode ? const Color(0xFF1A1A1A) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final isBlocked =
        context.select((BlockBloc b) => b.state.blockedIds.contains(userId));

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.white24 : Colors.black26,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            _ActionTile(
              icon: Icons.flag_outlined,
              label: 'Пожаловаться',
              textColor: textColor,
              onTap: () async {
                final navigator = context.router;
                final outerContext = context;
                navigator.maybePop();
                // Wait one frame so the action sheet finishes closing before
                // the report sheet appears — avoids two stacked modals.
                await Future<void>.delayed(const Duration(milliseconds: 50));
                if (!outerContext.mounted) return;
                ReportBottomSheet.show(
                  outerContext,
                  targetType: reportTargetType,
                  targetId: reportTargetId,
                  authorUserId: userId,
                  onReported: onReported,
                );
              },
            ),
            if (isBlocked)
              _ActionTile(
                icon: Icons.lock_open,
                label: 'Разблокировать пользователя',
                textColor: textColor,
                onTap: () {
                  context
                      .read<BlockBloc>()
                      .add(UnblockUserEvent(userId: userId));
                  context.router.maybePop();
                  showMessage(
                    context,
                    const ['Пользователь разблокирован'],
                    EnumStatusMessage.success,
                  );
                },
              )
            else
              _ActionTile(
                icon: Icons.block,
                label: 'Заблокировать пользователя',
                textColor: Colors.red,
                onTap: () {
                  context
                      .read<BlockBloc>()
                      .add(BlockUserEvent(userId: userId));
                  context.router.maybePop();
                  showMessage(
                    context,
                    const ['Пользователь заблокирован'],
                    EnumStatusMessage.success,
                  );
                },
              ),
            SizedBox(height: 8.h),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color textColor;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
        child: Row(
          children: [
            Icon(icon, color: textColor, size: 22),
            SizedBox(width: 14.w),
            Expanded(
              child: TextTranslated(
                label,
                style: TextStyle(
                  fontSize: 15.sp,
                  color: textColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
