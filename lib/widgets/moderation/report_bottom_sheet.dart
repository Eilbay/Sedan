import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:optombai/bloc/block_bloc/block_bloc.dart';
import 'package:optombai/bloc/product_bloc/product_bloc.dart';
import 'package:optombai/bloc/reel_bloc/reel_bloc.dart';
import 'package:optombai/bloc/report_bloc/report_cubit.dart';
import 'package:optombai/configs/app_color.dart';
import 'package:optombai/core/theme_notifier.dart';
import 'package:optombai/data/api_client.dart';
import 'package:optombai/data/models/report/report_category.dart';
import 'package:optombai/data/models/report/report_target_type.dart';
import 'package:optombai/widgets/translation/text_translated.dart';
import 'package:optombai/widgets/utils/message_show.dart';

/// Modal sheet for filing a report against a piece of content.
///
/// Shows the list of [ReportCategory] values, an optional reason field, and a
/// toggle to also block the content author in the same call.
/// The "also block" toggle is hidden when [authorUserId] is null (e.g. when
/// the target itself IS the author — reporting a user directly).
class ReportBottomSheet extends StatefulWidget {
  final ReportTargetType targetType;
  final String targetId;
  final String? authorUserId;

  /// When provided, the host screen handles post-report removal itself (e.g.
  /// the reels viewer drops the reel and advances). In that case the sheet
  /// only closes itself (no host-screen pop) and skips the default
  /// ProductBloc/ReelBloc removal so behaviour isn't duplicated/conflicting.
  final VoidCallback? onReported;

  /// When false, the report is never sent to the backend — picking a reason
  /// just triggers [onReported] and closes the sheet. Used for targets with
  /// no server-side report support yet (e.g. live streams), where the report
  /// UI only needs to drive a local action (closing the stream for viewer).
  final bool submitToBackend;

  const ReportBottomSheet({
    super.key,
    required this.targetType,
    required this.targetId,
    this.authorUserId,
    this.onReported,
    this.submitToBackend = true,
  });

  /// Helper that opens the sheet with the project's standard configuration.
  static Future<void> show(
    BuildContext context, {
    required ReportTargetType targetType,
    required String targetId,
    String? authorUserId,
    VoidCallback? onReported,
    bool submitToBackend = true,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReportBottomSheet(
        targetType: targetType,
        targetId: targetId,
        authorUserId: authorUserId,
        onReported: onReported,
        submitToBackend: submitToBackend,
      ),
    );
  }

  @override
  State<ReportBottomSheet> createState() => _ReportBottomSheetState();
}

class _ReportBottomSheetState extends State<ReportBottomSheet> {
  ReportCategory? _selectedCategory;
  final TextEditingController _reasonController = TextEditingController();
  bool _alsoBlock = false;

  bool get _canSubmit {
    final category = _selectedCategory;
    if (category == null) return false;
    if (category.requiresReason && _reasonController.text.trim().isEmpty) {
      return false;
    }
    return true;
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _onSubmit() {
    final category = _selectedCategory;
    if (category == null) return;
    final reason = _reasonController.text.trim();

    // Mirror the also-block in BlockBloc state so feed/profile reacts
    // immediately without waiting for /blocks/ refetch.
    final authorId = widget.authorUserId;
    if (_alsoBlock && authorId != null && authorId.isNotEmpty) {
      context
          .read<BlockBloc>()
          .add(BlockUserEvent(userId: authorId, reason: reason));
    }

    if (!widget.submitToBackend) {
      widget.onReported?.call();
      context.router.maybePop();
      return;
    }

    context.read<ReportCubit>().submitReport(
          targetType: widget.targetType,
          targetId: widget.targetId,
          category: category,
          reason: reason.isEmpty ? null : reason,
          alsoBlock: _alsoBlock,
        );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.select((ThemeNotifier n) => n.isDarkMode);
    final bgColor = isDarkMode ? const Color(0xFF1A1A1A) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;
    final canShowBlockToggle = widget.authorUserId != null &&
        widget.authorUserId!.isNotEmpty &&
        widget.targetType != ReportTargetType.user;

    return BlocListener<ReportCubit, ReportState>(
      listenWhen: (prev, curr) =>
          prev.isSuccess != curr.isSuccess || prev.errors != curr.errors,
      listener: (ctx, state) {
        if (state.isSuccess) {
          showMessage(
            ctx,
            const ['Жалоба отправлена'],
            EnumStatusMessage.success,
          );
          ctx.read<ReportCubit>().reset();

          // Host-driven removal (e.g. reels viewer): let the caller remove
          // the item and advance, close only the sheet, and skip the default
          // bloc removal + host pop below (which would exit the viewer).
          if (widget.onReported != null) {
            widget.onReported!();
            unawaited(ApiClient.I.clearCache());
            ctx.router.maybePop();
            return;
          }

          // Drop the reported content from every loaded list so the
          // reporter isn't staring at it. Server already filters it on
          // the next refresh; the in-memory Dio cache is the reason
          // pull-to-refresh used to bring the item back.
          final isPost = widget.targetType == ReportTargetType.post;
          final isReel = widget.targetType == ReportTargetType.stream;
          debugPrint(
              '[REPORT] success type=${widget.targetType} id=${widget.targetId} '
              'isPost=$isPost isReel=$isReel — removing + clearing cache');
          if (isPost) {
            ctx
                .read<ProductBloc>()
                .add(OptimisticRemoveProductEvent(widget.targetId));
          }
          if (isReel) {
            ctx
                .read<ReelBloc>()
                .add(OptimisticRemoveReelEvent(widget.targetId));
          }
          if (isPost || isReel) {
            // Wipe cached GET responses so the next list fetch goes to
            // the network and gets the already-filtered server result.
            unawaited(ApiClient.I.clearCache());
          }

          // Close the sheet, then pop the host screen (product details /
          // reel viewer) so the reported content disappears from view.
          ctx.router.maybePop().then((_) {
            if (isPost && ctx.mounted) {
              ctx.router.maybePop();
            }
          });
        } else if (state.errors.isNotEmpty) {
          showMessage(ctx, state.errors, EnumStatusMessage.error);
        }
      },
      child: Padding(
        padding: EdgeInsets.only(bottom: keyboardInset),
        child: Container(
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
                _SheetHandle(isDarkMode: isDarkMode),
                _SheetHeader(textColor: textColor),
                Flexible(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final category in ReportCategory.values)
                          _CategoryTile(
                            category: category,
                            isSelected: _selectedCategory == category,
                            textColor: textColor,
                            onTap: () =>
                                setState(() => _selectedCategory = category),
                          ),
                        SizedBox(height: 12.h),
                        if (_selectedCategory?.requiresReason ?? false)
                          _ReasonField(
                            controller: _reasonController,
                            isDarkMode: isDarkMode,
                            onChanged: (_) => setState(() {}),
                          ),
                        if (canShowBlockToggle) ...[
                          SizedBox(height: 8.h),
                          _AlsoBlockToggle(
                            value: _alsoBlock,
                            textColor: textColor,
                            onChanged: (v) =>
                                setState(() => _alsoBlock = v ?? false),
                          ),
                        ],
                        SizedBox(height: 16.h),
                      ],
                    ),
                  ),
                ),
                _SubmitButton(
                  enabled: _canSubmit,
                  onPressed: _onSubmit,
                ),
                SizedBox(height: 16.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  final bool isDarkMode;

  const _SheetHandle({required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.white24 : Colors.black26,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  final Color textColor;

  const _SheetHeader({required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Align(
        alignment: Alignment.centerLeft,
        child: TextTranslated(
          'Пожаловаться',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final ReportCategory category;
  final bool isSelected;
  final Color textColor;
  final VoidCallback onTap;

  const _CategoryTile({
    required this.category,
    required this.isSelected,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              size: 22,
              color: isSelected ? activeColor : textColor.withOpacity(0.4),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: TextTranslated(
                category.label,
                style: TextStyle(fontSize: 15.sp, color: textColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReasonField extends StatelessWidget {
  final TextEditingController controller;
  final bool isDarkMode;
  final ValueChanged<String> onChanged;

  const _ReasonField({
    required this.controller,
    required this.isDarkMode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final fillColor =
        isDarkMode ? const Color(0xFF2A2A2A) : const Color(0xFFF2F4F7);
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    return TextField(
      controller: controller,
      maxLines: 4,
      minLines: 3,
      style: TextStyle(color: textColor, fontSize: 14.sp),
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: 'Опишите проблему',
        hintStyle: TextStyle(color: textColor.withOpacity(0.5)),
        filled: true,
        fillColor: fillColor,
        contentPadding:
            EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _AlsoBlockToggle extends StatelessWidget {
  final bool value;
  final Color textColor;
  final ValueChanged<bool?> onChanged;

  const _AlsoBlockToggle({
    required this.value,
    required this.textColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => onChanged(!value),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 4.h),
        child: Row(
          children: [
            Checkbox(
              value: value,
              activeColor: activeColor,
              onChanged: onChanged,
            ),
            Expanded(
              child: TextTranslated(
                'Также заблокировать автора',
                style: TextStyle(fontSize: 14.sp, color: textColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubmitButton extends StatelessWidget {
  final bool enabled;
  final VoidCallback onPressed;

  const _SubmitButton({required this.enabled, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final isSubmitting =
        context.select((ReportCubit c) => c.state.isSubmitting);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: SizedBox(
        width: double.infinity,
        height: 48.h,
        child: ElevatedButton(
          onPressed: (!enabled || isSubmitting) ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: activeColor,
            foregroundColor: Colors.white,
            disabledBackgroundColor: activeColor.withOpacity(0.4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                )
              : TextTranslated(
                  'Отправить',
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }
}
