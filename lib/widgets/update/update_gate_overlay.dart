import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:optombai/configs/app_color.dart';
import 'package:optombai/core/appColors.dart';
import 'package:optombai/core/theme_notifier.dart';
import 'package:optombai/core/update/update_cubit.dart';
import 'package:optombai/widgets/translation/text_translated.dart';

/// Renders above the whole app (mounted in the `MaterialApp.router` builder)
/// so neither normal navigation nor a deep link can bypass it. Soft update
/// is dismissible ("Позже" or tapping the scrim); hard update blocks the
/// app entirely until updated.
class UpdateGateOverlay extends StatelessWidget {
  const UpdateGateOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UpdateCubit, UpdateState>(
      buildWhen: (previous, current) =>
          previous.showHardGate != current.showHardGate ||
          previous.showSoftGate != current.showSoftGate,
      builder: (context, state) {
        if (state.showHardGate) {
          return PopScope(
            canPop: false,
            child: _UpdateScrim(
              dismissible: false,
              child: _UpdateSheet(
                showDragHandle: false,
                iconColor: Colors.red,
                title: 'Необходимо обновление',
                description:
                    'Пожалуйста, обновите приложение, чтобы продолжить работу',
                storeUrl: state.info.storeUrl,
                secondaryLabel: 'Закрыть приложение',
                onSecondaryPressed: () {
                  if (Platform.isAndroid) {
                    SystemNavigator.pop();
                  } else {
                    exit(0);
                  }
                },
              ),
            ),
          );
        }

        if (state.showSoftGate) {
          return _UpdateScrim(
            dismissible: true,
            onDismiss: () => context.read<UpdateCubit>().dismissSoft(),
            child: _UpdateSheet(
              title: 'Вышла новая версия приложения',
              description:
                  'Рекомендуем обновить приложение для стабильной работы',
              storeUrl: state.info.storeUrl,
              secondaryLabel: 'Позже',
              onSecondaryPressed: () =>
                  context.read<UpdateCubit>().dismissSoft(),
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}

class _UpdateScrim extends StatelessWidget {
  const _UpdateScrim({
    required this.child,
    required this.dismissible,
    this.onDismiss,
  });

  final Widget child;
  final bool dismissible;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: dismissible ? onDismiss : null,
              child: ColoredBox(color: Colors.black.withValues(alpha: 0.54)),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {},
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

class _UpdateSheet extends StatelessWidget {
  const _UpdateSheet({
    required this.title,
    required this.description,
    required this.secondaryLabel,
    required this.onSecondaryPressed,
    this.storeUrl,
    this.iconColor,
    this.showDragHandle = true,
  });

  final String title;
  final String description;
  final String secondaryLabel;
  final VoidCallback onSecondaryPressed;
  final String? storeUrl;
  final Color? iconColor;
  final bool showDragHandle;

  Future<void> _openStore() async {
    final url = storeUrl;
    if (url == null || url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = context.select((ThemeNotifier n) => n.isDarkMode);
    final Color background = isDark ? AppColors.black : const Color(0xFFF5F5F5);
    final Color fg = isDark ? Colors.white : Colors.black87;
    final Color sub = isDark ? Colors.white60 : const Color(0xFF6B6B6B);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showDragHandle)
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 8),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: fg.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: iconColor ?? activeColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.priority_high,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextTranslated(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: fg,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextTranslated(
                    description,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, color: sub, height: 1.3),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _openStore,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: activeColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: const TextTranslated(
                        'Обновить',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onSecondaryPressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: activeColor.withValues(alpha: 0.12),
                        foregroundColor: activeColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: TextTranslated(
                        secondaryLabel,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
