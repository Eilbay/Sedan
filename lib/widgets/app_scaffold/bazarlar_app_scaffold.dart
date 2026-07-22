import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:optombai/app/router/app_router.dart';
import 'package:optombai/core/appColors.dart';
import 'package:optombai/core/dark/dark_background.dart';
import 'package:optombai/core/import_links.dart';
import 'package:optombai/core/theme_notifier.dart';
import 'package:optombai/pages/settings/settings_screen.dart';
import 'package:optombai/widgets/drawer/drawer_widget.dart';

const Color _accent = Color(0xFF2F80ED);

class BazarlarAppScaffold extends StatelessWidget {
  const BazarlarAppScaffold({
    super.key,
    required this.child,
    this.onRefresh,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.products = false,
    this.title,
  });

  final Widget child;
  final Future<void> Function()? onRefresh;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final bool products;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = context.select((ThemeNotifier n) => n.isDarkMode);

    final scaffold = Scaffold(
      backgroundColor: isDarkMode ? AppColors.black : const Color(0xFFF2F2F7),
      drawer: products ? null : const SettingsScreen(),
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      body: SafeArea(
        top: true,
        bottom: false,
        child: Column(
          children: [
            BazarlarHeader(showBack: products, title: title),
            Expanded(child: child),
          ],
        ),
      ),
    );

    final root = isDarkMode
        ? Stack(
            fit: StackFit.expand,
            children: [
              const DarkBackground(child: SizedBox.expand()),
              scaffold,
            ],
          )
        : scaffold;

    return RefreshIndicator(
      onRefresh: onRefresh ?? () async {},
      child: root,
    );
  }
}

class BazarlarHeader extends StatelessWidget {
  const BazarlarHeader({
    super.key,
    this.showBack = false,
    this.title,
  });

  final bool showBack;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final isDark = context.select((ThemeNotifier n) => n.isDarkMode);
    final fg = isDark ? Colors.white : Colors.black;

    return Padding(
      padding: EdgeInsets.fromLTRB(12.w, 4.h, 8.w, 6.h),
      child: Row(
        children: [
          if (showBack) ...[
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () => context.router.maybePop(),
              icon: Icon(Icons.arrow_back_ios_new, size: 20.sp, color: fg),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                title ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w800,
                  height: 1.05,
                  color: fg,
                ),
              ),
            ),
          ] else ...[
            const _BrandLogo(),
            SizedBox(width: 10.w),
            const Expanded(child: _BrandTitle()),
            _HeaderIconButton(
              icon: Icons.notifications_none_rounded,
              color: fg,
              showDot: true,
              onTap: () {
                final isRegister = context.read<ThemeNotifier>().isRegister;
                if (!isRegister) {
                  context.router.push(const SignInRoute());
                  return;
                }
                context.router.push(const NotificationsRoute());
              },
            ),
            SizedBox(width: 4.w),
            _HeaderIconButton(
              icon:
                  isDark ? Icons.wb_sunny_outlined : Icons.nights_stay_outlined,
              color: fg,
              onTap: () => context.read<ThemeNotifier>().toggleTheme(),
            ),
            SizedBox(width: 4.w),
            Builder(
              builder: (context) => _HeaderIconButton(
                icon: Icons.menu,
                color: fg,
                onTap: () => Scaffold.of(context).openDrawer(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BrandLogo extends StatelessWidget {
  const _BrandLogo();

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.select((ThemeNotifier n) => n.isDarkMode);

    return Image.asset(
      isDarkMode ? 'assets/logo_light.png' : 'assets/logo_bazarlar.png',
      width: 42.w,
      height: 42.w,
      fit: BoxFit.contain,
    );
  }
}

class _BrandTitle extends StatelessWidget {
  const _BrandTitle();

  @override
  Widget build(BuildContext context) {
    final isDark = context.select((ThemeNotifier n) => n.isDarkMode);
    final fg = isDark ? Colors.white : const Color(0xFF14141C);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'Sedan',
                style: TextStyle(color: fg),
              ),
              const TextSpan(
                text: '.Kg',
                style: TextStyle(color: _accent),
              ),
            ],
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 24.sp,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            height: 1.05,
          ),
        ),
        Text(
          'Авто рынок Кыргызстана',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 11.sp, color: Colors.grey),
        ),
      ],
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.color,
    required this.onTap,
    this.showDot = false,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          visualDensity: VisualDensity.compact,
          onPressed: onTap,
          icon: Icon(icon, size: 24.sp, color: color),
        ),
        if (showDot)
          Positioned(
            right: 2,
            top: 0,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: _accent,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }
}
