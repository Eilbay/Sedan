import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:optombai/app/router/app_router.dart';
import 'package:optombai/bloc/auth_bloc/auth_cubit.dart';
import 'package:optombai/bloc/language_bloc/language_bloc.dart';
import 'package:optombai/bloc/language_bloc/language_event.dart';
import 'package:optombai/bloc/language_bloc/language_state.dart';
import 'package:optombai/core/appColors.dart';
import 'package:optombai/core/dark/dark_background.dart';
import 'package:optombai/core/import_links.dart';
import 'package:optombai/widgets/translation/text_translated.dart';

@RoutePage()
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const _darkCard = Color(0xFF14181F);

  @override
  Widget build(BuildContext context) {
    final bool isDark = context.select((ThemeNotifier n) => n.isDarkMode);
    final bool isRegister = context.select((ThemeNotifier n) => n.isRegister);
    final user = context.select((UserBloc b) => b.state.user);
    final String lang = context.select<LanguageBloc, String>((b) {
      final s = b.state;
      return s is LanguageChangedState ? s.language : 'ru';
    });

    final Color bg = isDark ? AppColors.black : const Color(0xFFF1F2F4);
    final Color cardColor = isDark ? _darkCard : Colors.white;

    final scaffold = Scaffold(
      backgroundColor: isDark ? Colors.transparent : bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.close,
              color: isDark ? Colors.white : Colors.black87, size: 26),
          onPressed: () => context.router.maybePop(),
        ),
        title: TextTranslated(
          'Настройки',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 24.h),
        children: [
          _card(
            cardColor: cardColor,
            isDark: isDark,
            children: [
              _SettingsTile(
                title: 'Темная тема',
                isDark: isDark,
                showChevron: false,
                onTap: () => context.read<ThemeNotifier>().toggleTheme(),
                trailing: _PrettySwitch(
                  value: isDark,
                  onChanged: (_) => context.read<ThemeNotifier>().toggleTheme(),
                ),
              ),
              /*
              if (isRegister)
                _SettingsTile(
                  title: 'Страна',
                  value: user.country?.name ?? '—',
                  isDark: isDark,
                  onTap: () {},
                ),
                
              */
              if (isRegister)
                _SettingsTile(
                    title: 'Сохранённые публикации',
                    isDark: isDark,
                    onTap: () => context.router.push(const FavoriteRoute())),
              if (isRegister)
                _SettingsTile(
                    title: 'Заблокированные пользователи',
                    isDark: isDark,
                    onTap: () =>
                        context.router.push(const BlockedUsersRoute())),
              _SettingsTile(
                title: 'Язык',
                value: _languageName(lang),
                isDark: isDark,
                onTap: () => _showLanguageSheet(context, isDark, lang),
              ),

              /* _SettingsTile(
                title: 'Правовая информация',
                isDark: isDark,
                onTap: () => context.router.push(const LawDataRoute()),
              ),
              _SettingsTile(
                title: 'О платформе',
                isDark: isDark,
                onTap: () => context.router.push(const AboutUsRoute()),
              ),*/
              _SettingsTile(
                title: 'Реклама в приложении',
                isDark: isDark,
                onTap: () =>
                    context.router.push(const AdvertisingInfoRoute()),
              ),
              _SettingsTile(
                title: 'Пользовательское соглашение',
                isDark: isDark,
                onTap: () => context.router.push(const PrimaryRoute()),
              ),
              _SettingsTile(
                title: 'Политика конфиденциальности',
                isDark: isDark,
                onTap: () => context.router.push(const PoliticsRoute()),
              ),
              _SettingsTile(
                title: 'Публичная оферта',
                isDark: isDark,
                onTap: () => context.router.push(const OfertaRoute()),
              ),
              _SettingsTile(
                title: 'Сообщить о проблеме',
                isDark: isDark,
                onTap: () => context.router.push(const ReportIssueRoute()),
              ),
              if (isRegister)
                _SettingsTile(
                  title: 'Выход',
                  isDark: isDark,
                  titleColor: isDark ? Colors.white70 : const Color(0xFF6B7280),
                  leading: _circleIcon(Icons.logout, isDark),
                  onTap: () => _confirmLogout(context),
                )
              else
                _SettingsTile(
                  title: 'Войти',
                  isDark: isDark,
                  titleColor: const Color(0xFF7B2FF2),
                  leading: _circleIcon(Icons.login, isDark,
                      color: const Color(0xFF7B2FF2)),
                  onTap: () => context.router.push(const SignInRoute()),
                ),
            ],
          ),
        ],
      ),
    );

    if (isDark) {
      return Stack(
        fit: StackFit.expand,
        children: [
          const DarkBackground(child: SizedBox.expand()),
          scaffold,
        ],
      );
    }
    return scaffold;
  }

  static const List<Map<String, String>> _languages = [
    {'flag': '🇷🇺', 'code': 'ru', 'name': 'Русский'},
    {'flag': '🇺🇸', 'code': 'en', 'name': 'English'},
    {'flag': '🇩🇪', 'code': 'de', 'name': 'Deutsch'},
    {'flag': '🇹🇷', 'code': 'tr', 'name': 'Türkçe'},
    {'flag': '🇨🇳', 'code': 'zh-cn', 'name': '中文'},
    {'flag': '🇰🇬', 'code': 'ky', 'name': 'Кыргызча'},
  ];

  static String _languageName(String code) {
    for (final l in _languages) {
      if (l['code'] == code) return l['name']!;
    }
    return 'Русский';
  }

  void _showLanguageSheet(BuildContext context, bool isDark, String current) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? _darkCard : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (sheetCtx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.only(top: 10.h, bottom: 4.h),
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: (isDark ? Colors.white : Colors.black)
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              ..._languages.map((l) {
                final code = l['code']!;
                final active = code == current;
                return ListTile(
                  leading:
                      Text(l['flag']!, style: const TextStyle(fontSize: 22)),
                  title: Text(
                    l['name']!,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  trailing: active
                      ? const Icon(Icons.check_circle, color: Color(0xFF7B2FF2))
                      : null,
                  onTap: () {
                    context.read<LanguageBloc>().add(ChangeLanguageEvent(code));
                    Navigator.pop(sheetCtx);
                  },
                );
              }),
              SizedBox(height: 8.h),
            ],
          ),
        );
      },
    );
  }

  Widget _card({
    required Color cardColor,
    required bool isDark,
    required List<Widget> children,
  }) {
    final divided = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      divided.add(children[i]);
      if (i != children.length - 1) {
        divided.add(Divider(
          height: 1,
          thickness: 0.6,
          indent: 16.w,
          endIndent: 16.w,
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.07),
        ));
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(children: divided),
    );
  }

  Widget _circleIcon(IconData icon, bool isDark, {Color? color}) {
    final c = color ?? (isDark ? Colors.white70 : const Color(0xFF6B7280));
    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 18, color: c),
    );
  }

  void _confirmLogout(BuildContext context) {
    final bool isDark = context.read<ThemeNotifier>().isDarkMode;
    showDialog(
      context: context,
      builder: (dialogContext) {
        return Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            height: 150.h,
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xff061324) : Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      icon: const Icon(Icons.close),
                      iconSize: 20,
                    ),
                  ],
                ),
                const TextTranslated(
                  'Вы действительно хотите выйти?',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 10.h),
                CustomButton(
                  title: 'Выйти',
                  onPressed: () async {
                    Navigator.pop(dialogContext);
                    final id = context.read<UserBloc>().state.user.id;
                    debugPrint('[AUTH] logout from settings');
                    context.read<ThemeNotifier>().setRegistrationStatus(false);
                    await context.read<AuthCubit>().clear(id);
                    if (!context.mounted) return;
                    context.read<ProductBloc>().add(ClearProductsEvent());
                    context.read<ProductBloc>().add(FetchAllProductsEvent());
                    context.router.replaceAll([
                      BottomNavRoute(initialIndex: 4),
                    ]);
                  },
                  borderRadius: 20,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final String title;
  final String? value;
  final bool isDark;
  final VoidCallback? onTap;
  final Widget? leading;
  final Widget? trailing;
  final bool showChevron;
  final Color? titleColor;

  const _SettingsTile({
    required this.title,
    required this.isDark,
    this.value,
    this.onTap,
    this.leading,
    this.trailing,
    this.showChevron = true,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    final Color fg = titleColor ?? (isDark ? Colors.white : Colors.black87);
    final Color grey = isDark ? Colors.white54 : const Color(0xFF9AA0A6);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        child: Row(
          children: [
            if (leading != null) ...[
              leading!,
              SizedBox(width: 12.w),
            ],
            Expanded(
              child: TextTranslated(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: fg,
                ),
              ),
            ),
            if (value != null) ...[
              TextTranslated(
                value!,
                style: TextStyle(fontSize: 14, color: grey),
              ),
              SizedBox(width: 8.w),
            ],
            if (trailing != null)
              trailing!
            else if (showChevron)
              Icon(Icons.chevron_right, color: grey, size: 22),
          ],
        ),
      ),
    );
  }
}

class _PrettySwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _PrettySwitch({required this.value, required this.onChanged});

  static const Color _on = Color(0xFF7B2FF2);
  static const double _w = 52;
  static const double _h = 30;
  static const double _knob = 24;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        width: _w,
        height: _h,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          gradient: value
              ? const LinearGradient(
                  colors: [Color(0xFF9B4DFF), _on],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: value ? null : const Color(0xFFD9DCE1),
          borderRadius: BorderRadius.circular(_h),
          boxShadow: value
              ? [
                  BoxShadow(
                    color: _on.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: _knob,
            height: _knob,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: Icon(
              value ? Icons.dark_mode : Icons.light_mode,
              size: 14,
              color: value ? _on : const Color(0xFFB0B4BA),
            ),
          ),
        ),
      ),
    );
  }
}
