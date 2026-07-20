import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:optombai/bloc/language_bloc/language_bloc.dart';
import 'package:optombai/bloc/language_bloc/language_event.dart';
import 'package:optombai/bloc/language_bloc/language_state.dart';

import 'package:optombai/core/appColors.dart';
import 'package:optombai/core/dark/dark_background.dart';
import 'package:optombai/core/theme_notifier.dart';

import 'package:auto_route/auto_route.dart';
import 'package:optombai/app/router/app_router.dart';
import 'package:optombai/widgets/drawer/drawer_widget.dart';
import 'package:optombai/widgets/translation/text_translated.dart';

import 'package:optombai/bloc/chat_bloc/chat_bloc.dart';
import 'package:optombai/features/notifications/presentation/widgets/notification_bell_icon.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.child,
    this.products = false,
    this.onRefresh,
    this.floatingActionButton,
    this.bottomNavigationBar,
  });

  final Widget child;
  final bool products;
  final Future<void> Function()? onRefresh;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = context.select((ThemeNotifier n) => n.isDarkMode);

    final scaffold = Scaffold(
      backgroundColor: isDarkMode ? AppColors.black : AppColors.lightBackground,
      extendBodyBehindAppBar: isDarkMode,
      floatingActionButton: floatingActionButton,
      drawer: const DrawerScreen(),
      bottomNavigationBar: bottomNavigationBar,
      appBar: AppBar(
        centerTitle: false,
        leadingWidth: 44,
        titleSpacing: 0,
        leading: products
            ? IconButton(
                onPressed: () => context.router.maybePop(),
                icon: const Icon(Icons.arrow_back),
              )
            : null,
        iconTheme: Theme.of(context).iconTheme,
        elevation: 0,
        backgroundColor: isDarkMode
            ? Colors.black.withValues(alpha: 0.10)
            : AppColors.lightBackground,
        flexibleSpace: isDarkMode
            ? null
            : Container(
                color: AppColors.lightBackground,
              ),
        title: GestureDetector(
          onTap: () {
            context.router.replaceAll([BottomNavRoute()]);
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                isDarkMode
                    ? 'assets/logo_light.png'
                    : 'assets/logo_bazarlar.png',
                height: 32.h,
                fit: BoxFit.contain,
              ),
              SizedBox(width: 10.w),
              // Flexible + ellipsis prevents the title Row from overflowing
              // when actions take most of the AppBar width (caught a
              // RenderFlex 11px overflow on small screens).
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "",
                      style: Theme.of(context).textTheme.titleMedium,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    TextTranslated(
                      "Оптом. Рынки. Заказы.",
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontSize: 10.sp,
                          ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildLanguageSwitcher(context),
              IconButton(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                constraints: const BoxConstraints(),
                onPressed: () {
                  context.read<ThemeNotifier>().toggleTheme();
                },
                icon: Icon(
                  isDarkMode ? Icons.wb_sunny : Icons.nights_stay,
                  size: 20.sp,
                  color: isDarkMode ? Colors.white : AppColors.lightBottomIcons,
                ),
              ),
              NotificationBellIcon(
                iconColor:
                    isDarkMode ? Colors.white : AppColors.lightBottomIcons,
              ),
              BlocBuilder<ChatBloc, ChatState>(
                buildWhen: (previous, current) {
                  return previous.chats != current.chats;
                },
                builder: (context, chatState) {
                  final totalUnread = chatState.chats
                      .fold<int>(0, (sum, chat) => sum + chat.unreadCount);
                  // `isAgree` was historically a terms-of-service ack flag,
                  // but backend stores `false` for the vast majority of
                  // production users (only newer ones flipped it). Gating
                  // on it locks all legacy accounts out of chat — the
                  // viewer just needs to be logged in.
                  final isRegister = context.read<ThemeNotifier>().isRegister;
                  final isAuthorized = isRegister;
                  debugPrint(
                    '[APP_SCAFFOLD] chat icon build isAuthorized=$isAuthorized '
                    'isRegister=$isRegister unread=$totalUnread',
                  );

                  return Stack(
                    children: [
                      IconButton(
                        padding: EdgeInsets.symmetric(horizontal: 4.w),
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          if (isAuthorized) {
                            context.router.push(const ChatListRoute());
                          } else {
                            context.router.push(const SignInRoute());
                          }
                        },
                        icon: Icon(
                          Icons.send,
                          size: 20.sp,
                          color: isDarkMode
                              ? Colors.white
                              : AppColors.lightBottomIcons,
                        ),
                      ),
                      if (isAuthorized && totalUnread > 0)
                        Positioned(
                          right: 4.w,
                          bottom: 4.w,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 4.w,
                              vertical: 1.5.w,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              totalUnread > 99 ? '99+' : totalUnread.toString(),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        top: true,
        bottom: false,
        child: child,
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

  Widget _buildLanguageSwitcher(BuildContext context) {
    final languages = [
      {'flag': '🇷🇺', 'code': 'ru', 'name': 'Русский'},
      {'flag': '🇺🇸', 'code': 'en', 'name': 'English'},
      {'flag': '🇩🇪', 'code': 'de', 'name': 'Deutsch'},
      {'flag': '🇹🇷', 'code': 'tr', 'name': 'Türkçe'},
      {'flag': '🇨🇳', 'code': 'zh-cn', 'name': '中文'},
      {'flag': '🇰🇬', 'code': 'ky', 'name': 'Кыргызча'},
    ];

    final selectedLanguage = context.select<LanguageBloc, String>((bloc) {
      final state = bloc.state;
      return state is LanguageChangedState ? state.language : 'ru';
    });

    return DropdownButtonHideUnderline(
      child: DropdownButton2<String>(
        value: selectedLanguage,
        iconStyleData: const IconStyleData(icon: SizedBox.shrink()),
        dropdownStyleData: DropdownStyleData(
          width: 150.w,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        buttonStyleData: const ButtonStyleData(
          padding: EdgeInsets.symmetric(horizontal: 8),
        ),
        style: const TextStyle(fontSize: 16, color: Colors.black),
        selectedItemBuilder: (BuildContext context) {
          return languages.map((language) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  language['flag']!,
                  style: const TextStyle(fontSize: 18, color: Colors.black),
                ),
              ],
            );
          }).toList();
        },
        items: languages.map((language) {
          return DropdownMenuItem<String>(
            value: language['code']!,
            child: Row(
              children: [
                Text(
                  language['flag']!,
                  style: const TextStyle(fontSize: 24, color: Colors.black),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    language['name']!,
                    style: const TextStyle(fontSize: 14, color: Colors.black),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
        onChanged: (String? newValue) {
          if (newValue != null) {
            context.read<LanguageBloc>().add(ChangeLanguageEvent(newValue));
          }
        },
      ),
    );
  }
}
