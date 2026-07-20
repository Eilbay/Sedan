import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:optombai/app/router/app_router.dart';
import 'package:optombai/core/theme_notifier.dart';
import 'package:optombai/features/notifications/presentation/logic/notifications_cubit.dart';

/// Bell icon with a small purple dot when there are unread notifications.
/// Drop into any AppBar `actions:` list. Tap navigates to the
/// notifications screen — or to sign-in when the viewer is a guest.
class NotificationBellIcon extends StatelessWidget {
  const NotificationBellIcon({super.key, this.iconColor});

  final Color? iconColor;

  void _onTap(BuildContext context) {
    final bool isRegister = context.read<ThemeNotifier>().isRegister;
    if (!isRegister) {
      debugPrint('[AUTH] notifications gate -> sign in');
      context.router.push(const SignInRoute());
      return;
    }
    context.router.push(const NotificationsRoute());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificationsCubit, NotificationsState>(
      buildWhen: (p, c) => p.unreadCount != c.unreadCount,
      builder: (context, state) {
        return IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          visualDensity: VisualDensity.compact,
          onPressed: () => _onTap(context),
          icon: _BellWithDot(
            hasUnread: state.unreadCount > 0,
            iconColor: iconColor,
          ),
        );
      },
    );
  }
}

class _BellWithDot extends StatelessWidget {
  const _BellWithDot({required this.hasUnread, this.iconColor});

  final bool hasUnread;
  final Color? iconColor;

  static const Color _accent = Color(0xFF7B2FF2);

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(Icons.notifications_none, color: iconColor),
        if (hasUnread)
          Positioned(
            right: -1,
            top: -1,
            child: Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: _accent,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _accent.withValues(alpha: 0.65),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
