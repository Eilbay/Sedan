import 'package:flutter/material.dart';
import 'package:optombai/configs/app_color.dart';
import 'package:optombai/core/appColors.dart';
import 'package:optombai/l10n/tr.dart';

/*
class AppBottomBar extends StatelessWidget {
  final int currentIndex;
  final int profileIndex;
  final bool isDark;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onAddProduct;
  static const double barHeight = 60;
  static const double fabOverflow = 32;
  static const double totalHeight = barHeight + fabOverflow;

  const AppBottomBar({
    super.key,
    required this.currentIndex,
    required this.profileIndex,
    required this.isDark,
    required this.onTabSelected,
    required this.onAddProduct,
  });

  static const _fabGradient = LinearGradient(
    colors: [Color(0xFF9D4EDD), Color(0xFF7B2FF2)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const double _barHeight = 60;
  static const double _iconSize = 24;
  static const double _fabSize = 54;

  @override
  Widget build(BuildContext context) {
    final double bottomInset = MediaQuery.paddingOf(context).bottom;
    final Color barColor = isDark ? const Color(0xFF1A1A1A) : Colors.white;

    return SizedBox(
      height: _barHeight + 32 + bottomInset,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: _barHeight + bottomInset,
              padding: EdgeInsets.only(bottom: bottomInset),
              decoration: BoxDecoration(
                color: barColor,
                boxShadow: isDark
                    ? null
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 12,
                          offset: const Offset(0, -2),
                        ),
                      ],
              ),
              child: Row(
                children: [
                  _tab(
                    context,
                    icon: Icons.home,
                    labelKey: 'nav_home',
                    active: currentIndex == 0,
                    onTap: () => onTabSelected(0),
                  ),
                  _tab(
                    context,
                    icon: Icons.grid_view_rounded,
                    labelKey: 'nav_categories',
                    active: currentIndex == 1,
                    onTap: () => onTabSelected(1),
                  ),
                  _centerLabelSlot(context),
                  _tab(
                    context,
                    icon: Icons.live_tv,
                    labelKey: 'nav_streams',
                    active: currentIndex == 2,
                    onTap: () => onTabSelected(2),
                  ),
                  _tab(
                    context,
                    icon: Icons.person,
                    labelKey: 'nav_profile',
                    active: currentIndex == profileIndex,
                    onTap: () => onTabSelected(profileIndex),
                  ),
                ],
              ),
            ),
          ),

          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.only(bottom: bottomInset + 28),
              child: _fab(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tab(
    BuildContext context, {
    required IconData icon,
    required String labelKey,
    required bool active,
    required VoidCallback onTap,
  }) {
    final Color selected = isDark ? Colors.white : activeColorLight;
    final Color color = active ? selected : Colors.grey;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: _iconSize),
            const SizedBox(height: 4),
            Text(
              tr(context, labelKey),
              style: TextStyle(fontSize: 11, color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _centerLabelSlot(BuildContext context) {
    final bool active = currentIndex == 3;
    final Color color = active ? const Color(0xFF7B2FF2) : Colors.grey;
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: _iconSize),
          const SizedBox(height: 4),
          Text(
            tr(context, 'nav_add'),
            style: TextStyle(fontSize: 11, color: color),
          ),
        ],
      ),
    );
  }

  Widget _fab() {
    return GestureDetector(
      onTap: onAddProduct,
      child: Container(
        width: _fabSize,
        height: _fabSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: _fabGradient,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7B2FF2).withValues(alpha: 0.40),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
    );
  }
}
*/
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:optombai/features/notifications/presentation/logic/notifications_cubit.dart';
import 'package:optombai/l10n/tr.dart';

class AppBottomBar extends StatelessWidget {
  final int currentIndex;
  final int profileIndex;
  final bool isDark;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onAddProduct;
  final VoidCallback onMessages;

  const AppBottomBar({
    super.key,
    required this.currentIndex,
    required this.profileIndex,
    required this.isDark,
    required this.onTabSelected,
    required this.onAddProduct,
    required this.onMessages,
  });

  static const double _barHeight = 58;
  static const double _iconSize = 24;
  static const double _fabSize = 40;

  static const int messagesIndex = 100;

  static const Color _selected = Color(0xFF2F80ED);

  static const _fabGradient = LinearGradient(
    colors: [Color(0xFF5B9DF5), Color(0xFF2F80ED)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  Widget build(BuildContext context) {
    final double bottomInset = MediaQuery.paddingOf(context).bottom;
    final Color barColor = isDark ? const Color(0xFF1A1A1A) : Colors.white;

    return Container(
      height: _barHeight + bottomInset,
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: BoxDecoration(
        color: barColor,
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, -2),
                ),
              ],
      ),
      child: Row(
        children: [
          _tab(
            context,
            icon: Icons.home,
            labelKey: 'nav_home',
            active: currentIndex == 0,
            onTap: () => onTabSelected(0),
          ),
          _tab(
            context,
            icon: Icons.slideshow,
            labelKey: 'nav_streams',
            active: currentIndex == 2,
            onTap: () => onTabSelected(2),
          ),
          _addTab(context),
          _messagesTab(context),
          _tab(
            context,
            icon: Icons.person,
            labelKey: 'nav_profile',
            active: currentIndex == profileIndex,
            onTap: () => onTabSelected(profileIndex),
          ),
        ],
      ),
    );
  }

  Widget _tab(
    BuildContext context, {
    required IconData icon,
    required String labelKey,
    required bool active,
    required VoidCallback onTap,
    Widget? iconOverride,
  }) {
    final Color color = active ? _selected : Colors.grey;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            iconOverride ?? Icon(icon, color: color, size: _iconSize),
            const SizedBox(height: 3),
            Text(
              tr(context, labelKey),
              style: TextStyle(fontSize: 10, color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _messagesTab(BuildContext context) {
    final bool active = currentIndex == messagesIndex;
    final Color color = active ? _selected : Colors.grey;

    final int unread = context.select<NotificationsCubit, int>(
      (cubit) => cubit.state.unreadCount,
    );

    return _tab(
      context,
      icon: Icons.chat_outlined,
      labelKey: 'nav_active',
      active: active,
      onTap: onMessages,
      iconOverride: _IconWithBadge(
        icon: Icons.chat_outlined,
        color: color,
        count: unread,
      ),
    );
  }

  Widget _addTab(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onAddProduct,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: _fabSize,
              height: _fabSize,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: _fabGradient,
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 3),
            Text(
              tr(context, 'nav_add'),
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconWithBadge extends StatelessWidget {
  const _IconWithBadge({
    required this.icon,
    required this.color,
    required this.count,
  });

  final IconData icon;
  final Color color;
  final int count;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 34,
      height: 26,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          if (count > 0)
            Positioned(
              top: -6,
              right: -2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                constraints: const BoxConstraints(minWidth: 18),
                decoration: BoxDecoration(
                  color: const Color(0xFFE53170),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: Text(
                  count > 99 ? '99+' : '$count',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
