import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:optombai/app/router/app_router.dart';
import 'package:optombai/core/appColors.dart';
import 'package:optombai/core/dark/dark_background.dart';
import 'package:optombai/core/import_links.dart';
import 'package:optombai/core/theme_notifier.dart';
import 'package:optombai/bloc/chat_bloc/chat_bloc.dart';
import 'package:optombai/pages/settings/settings_screen.dart';
import 'package:optombai/widgets/drawer/drawer_widget.dart';

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
      // Two surface levels in light theme: this slightly grey page background
      // sits behind the white product cards so they read as separate blocks.
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
      padding: EdgeInsets.fromLTRB(6.w, 0, 12.w, 2.h),
      child: Row(
        children: [
          if (showBack)
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () => context.router.maybePop(),
              icon: Icon(Icons.arrow_back_ios_new, size: 20.sp, color: fg),
            )
          else
            Builder(
              builder: (context) {
                return IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  visualDensity: VisualDensity.compact,
                  onPressed: () => Scaffold.of(context).openDrawer(),
                  icon: Icon(Icons.menu, size: 24.sp, color: fg),
                );
              },
            ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Brand title on the home header gets the gradient treatment;
                // page titles (showBack == true) stay a plain solid color.
                if (!showBack)
                  const _BrandTitle()
                else
                  Text(
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
                if (!showBack)
                  const Text(
                    'Онлайн базар Кыргызстан',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
              ],
            ),
          ),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            visualDensity: VisualDensity.compact,
            onPressed: () => context.read<ThemeNotifier>().toggleTheme(),
            icon: Icon(
              isDark ? Icons.wb_sunny_outlined : Icons.nights_stay_outlined,
              size: 24.sp,
              color: fg,
            ),
          ),
          SizedBox(width: 10.w),
          _ChatIconWithBadge(color: fg),
        ],
      ),
    );
  }
}

class _ChatIconWithBadge extends StatelessWidget {
  const _ChatIconWithBadge({required this.color});

  final Color color;

  void _onTap(BuildContext context) {
    final bool isRegister = context.read<ThemeNotifier>().isRegister;
    if (!isRegister) {
      debugPrint('[AUTH] header chats gate -> sign in');
      context.router.push(const SignInRoute());
      return;
    }
    context.router.push(const ChatListRoute());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChatBloc, ChatState>(
      buildWhen: (previous, current) => previous.chats != current.chats,
      builder: (context, chatState) {
        final totalUnread =
            chatState.chats.fold<int>(0, (sum, chat) => sum + chat.unreadCount);
        final bool isRegister = context.read<ThemeNotifier>().isRegister;
        final bool showBadge = isRegister && totalUnread > 0;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              visualDensity: VisualDensity.compact,
              onPressed: () => _onTap(context),
              icon: Icon(Icons.forum_outlined, size: 24.sp, color: color),
            ),
            if (showBadge)
              Positioned(
                right: -6,
                top: -8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 1,
                  ),
                  constraints: const BoxConstraints(minWidth: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7B2FF2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    totalUnread > 99 ? '99+' : totalUnread.toString(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// The "Bazarlar" wordmark. Uses a ShaderMask so the gradient maps exactly to
/// the text bounds (a fixed-rect Paint shader made the word look almost white,
/// because the purple end fell outside the glyphs). Gradient is theme-aware:
/// light → lilac on dark bg; dark → purple on light bg. A verified badge sits
/// after the wordmark, matching the reference.
class _BrandTitle extends StatelessWidget {
  const _BrandTitle();

  @override
  Widget build(BuildContext context) {
    final isDark = context.select((ThemeNotifier n) => n.isDarkMode);

    final Widget wordmark = isDark
        // Dark theme: white → lilac → purple gradient over the wordmark.
        ? ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (bounds) => const LinearGradient(
              colors: [
                Color(0xFFFFFFFF),
                Color(0xFFE5D8FF),
                Color(0xFF9B5CFF),
              ],
            ).createShader(bounds),
            child: Text(
              'Китайдан',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'SF Pro Display',
                fontSize: 26.sp,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.8,
                height: 1.05,
                color: Colors.white,
              ),
            ),
          )
        // Light theme: plain dark wordmark.
        : Text(
            'Китайдан',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'SF Pro Display',
              fontSize: 26.sp,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.8,
              height: 1.05,
              color: const Color(0xFF14141C),
            ),
          );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(child: wordmark),
        SizedBox(width: 5.w),
        Icon(
          Icons.verified,
          size: 18.sp,
          color: const Color(0xFF7B2FF2),
        ),
      ],
    );
  }
}
