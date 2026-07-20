import 'package:auto_route/auto_route.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:optombai/app/router/app_router.dart';
import 'package:optombai/core/import_links.dart';
import 'package:optombai/data/models/question/question_model.dart';
import 'package:optombai/widgets/profile/premium_badge.dart';
import 'package:optombai/widgets/translation/text_translated.dart';
import 'package:optombai/bloc/auth_bloc/auth_cubit.dart';
import 'package:optombai/bloc/button_visible_bloc/gate/button_visible_gate.dart';

class DrawerScreen extends StatefulWidget {
  const DrawerScreen({super.key});

  @override
  State<DrawerScreen> createState() => _DrawerScreenState();
}

class _DrawerScreenState extends State<DrawerScreen> {
  int? dropdownValue;
  bool stateSwitch = false;
  final QuestionModel question = QuestionModel();
  double usdRate = 1.0;
  double selectedRate = 1.0;
  String selectedCurrency = 'USD';

  List<Map<String, String>> currencies = [
    {'code': 'USD', 'icon': 'assets/flags/america.png'},
    {'code': 'KGZ', 'icon': 'assets/flags/kyrgyzstan.png'},
    {'code': 'KAZ', 'icon': 'assets/flags/kaz.png'},
    {'code': 'RUS', 'icon': 'assets/flags/russia.png'},
  ];

  @override
  void initState() {
    super.initState();
    stateSwitch = context.read<ThemeNotifier>().isDarkMode;
  }

  routingPage(PageRouteInfo route) {
    context.router.maybePop();
    context.router.push(route);
  }

  @override
  Widget build(BuildContext context) {
    bool stateSwitch = context.select((ThemeNotifier n) => n.isDarkMode);
    var id = context.select((UserBloc b) => b.state.user.id);
    bool isRegister = context.select((ThemeNotifier n) => n.isRegister);

    return Drawer(
        width: MediaQuery.sizeOf(context).width * 0.82,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 30),
          child: SingleChildScrollView(
            child: Column(children: [
              SizedBox(height: 35.h),
              if (isRegister)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _DrawerProfileHeader(),
                )
              else
                const SizedBox.shrink(),
              SizedBox(height: 12.h),
              Container(
                color: const Color(0x0f8c8989),
                child: CustomDrawerList(
                    icon: Icons.bookmark_border,
                    title: 'Сохранённые публикации',
                    onPressed: () => routingPage(const FavoriteRoute())),
              ),
              SizedBox(height: 15.h),
              Container(
                color: const Color(0x0f8c8989),
                child: CustomDrawerList(
                    image: 'assets/icons/drawer_icons/buyer.png',
                    title: 'Пользователям',
                    onPressed: () => routingPage(const UsersRoute())),
              ),
              SizedBox(
                height: 15.h,
              ),
              Container(
                color: const Color(0x0f8c8989),
                child: CustomDrawerList(
                    image: 'assets/icons/drawer_icons/fullfilment.png',
                    title: 'Фулфилмент',
                    onPressed: () => routingPage(const FulfilmentRoute())),
              ),
              SizedBox(
                height: 15.h,
              ),
              ButtonVisibleGate(
                child: Column(
                  children: [
                    Container(
                      color: const Color(0x0f8c8989),
                      child: CustomDrawerList(
                        image: 'assets/icons/drawer_icons/premium.png',
                        title: 'Тарифы',
                        onPressed: () {
                          routingPage(const ProAccountsRoute());
                        },
                      ),
                    ),
                    SizedBox(height: 15.h),
                  ],
                ),
              ),
              Container(
                color: const Color(0x0f8c8989),
                child: CustomDrawerList(
                  image: stateSwitch
                      ? 'assets/logo_light.png'
                      : 'assets/logo_bazarlar.png',
                  onPressed: () => routingPage(const AboutUsRoute()),
                  title: 'О платформе ',
                ),
              ),
              SizedBox(
                height: 15.h,
              ),
              Container(
                color: const Color(0x0f8c8989),
                child: CustomDrawerList(
                  image: 'assets/icons/drawer_icons/legal.png',
                  onPressed: () => routingPage(const LawDataRoute()),
                  title: 'О нас',
                ),
              ),
              SizedBox(
                height: 15.h,
              ),
              Container(
                color: const Color(0x0f8c8989),
                child: CustomDrawerList(
                  image: 'assets/icons/drawer_icons/more.png',
                  onPressed: () => routingPage(const PrimaryRoute()),
                  title: 'Пользовательское соглашение',
                ),
              ),
              SizedBox(
                height: 15.h,
              ),
              Container(
                color: const Color(0x0f8c8989),
                child: CustomDrawerList(
                  image: 'assets/polite.png',
                  onPressed: () => routingPage(const PoliticsRoute()),
                  title: 'Политика конфиденциальности',
                ),
              ),
              SizedBox(
                height: 15.h,
              ),
              Container(
                color: const Color(0x0f8c8989),
                child: CustomDrawerList(
                  image: 'assets/icons/drawer_icons/shopping.png',
                  onPressed: () => routingPage(const OfertaRoute()),
                  title: 'Публичная оферта',
                ),
              ),
              SizedBox(
                height: 15.h,
              ),
              if (isRegister) ...[
                Container(
                  color: const Color(0x0f8c8989),
                  child: CustomDrawerList(
                    image: 'assets/icons/drawer_icons/more.png',
                    onPressed: () => routingPage(const BlockedUsersRoute()),
                    title: 'Заблокированные пользователи',
                  ),
                ),
                SizedBox(height: 15.h),
              ],
              Container(
                color: const Color(0x0f8c8989),
                child: CustomDrawerList(
                  image: 'assets/icons/drawer_icons/exit.png',
                  title: 'Выйти',
                  onPressed: () => showDialog(
                    context: context,
                    builder: (BuildContext dialogContext) {
                      return Center(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          height: 150.h,
                          width: double.infinity,
                          decoration: BoxDecoration(
                              color: stateSwitch
                                  ? const Color(0xff061324)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(14)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    onPressed: () {
                                      Navigator.pop(dialogContext);
                                    },
                                    icon: const Icon(Icons.close),
                                    iconSize: 20,
                                  ),
                                ],
                              ),
                              const TextTranslated(
                                'Вы действительно хотите выйти?',
                                style: TextStyle(fontSize: 16),
                              ),
                              SizedBox(
                                height: 15.h,
                              ),
                              CustomButton(
                                title: 'Выйти',
                                onPressed: () async {
                                  Navigator.pop(dialogContext);
                                  debugPrint('[AUTH] logout from drawer');
                                  await context.read<AuthCubit>().clear(id);
                                  if (!context.mounted) return;
                                  context
                                      .read<ThemeNotifier>()
                                      .setRegistrationStatus(false);
                                  // Wipe per-user caches so the next sign-in
                                  // doesn't briefly render the previous
                                  // account's feed/profile/postModel before
                                  // its own data arrives.
                                  context
                                      .read<ProductBloc>()
                                      .add(ClearProductsEvent());
                                  context
                                      .read<ThemeNotifier>()
                                      .setRegistrationStatus(false);
                                  context.router
                                      .replaceAll([const SignInRoute()]);
                                },
                                borderRadius: 20,
                              )
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              )
            ]),
          ),
        ));
  }
}

class CustomDrawerList extends StatelessWidget {
  const CustomDrawerList({
    super.key,
    this.image,
    this.icon,
    required this.title,
    this.onPressed,
  }) : assert(image != null || icon != null,
            'CustomDrawerList needs either an image asset or an icon');

  /// PNG asset path (tinted with the theme accent). Mutually exclusive with
  /// [icon]; provide [icon] for items that have no dedicated asset.
  final String? image;
  final IconData? icon;
  final String title;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    bool stateSwitch = context.select((ThemeNotifier n) => n.isDarkMode);
    final accent =
        stateSwitch ? const Color(0xff75CEFF) : const Color(0xff006199);
    return InkWell(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                if (icon != null)
                  Icon(icon, color: accent, size: 30.w)
                else if (image!.contains("pro"))
                  Image(
                    image: AssetImage(image!),
                    color: accent,
                    width: 28.w,
                    height: 28.h,
                  )
                else
                  Image(
                    image: AssetImage(image!),
                    color: accent,
                    width: 30.w,
                    height: 34.h,
                  ),
                SizedBox(
                  width: 7.w,
                ),
                Column(
                  children: [
                    TextTranslated(
                      title,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(
              height: 7.h,
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerProfileHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = context.select((ThemeNotifier n) => n.isDarkMode);
    final user = context.select((UserBloc b) => b.state.user);

    final isVerified = user.is_verified ?? false;

    const bool isOnline = true;
    final bool isBusiness =
        (user.isPremium ?? false) || (user.userStatus?.isPremium ?? false);

    final nameColor = isDark ? Colors.white : const Color(0xFF0B1220);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        context.router.maybePop();
        context.router.push(ProfileEditRoute(user: user));
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF102A44) : const Color(0xFFEAF2FF),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: isDark
                      ? const Color(0xFF1B3A57)
                      : const Color(0xFFD9E6FF),
                  backgroundImage:
                      (user.image != null && user.image!.isNotEmpty)
                          ? CachedNetworkImageProvider(user.image!)
                          : null,
                  child: (user.image == null || user.image!.isEmpty)
                      ? Icon(Icons.person,
                          size: 30,
                          color: isDark ? Colors.white70 : Colors.black45)
                      : null,
                ),
                if (isVerified)
                  Positioned(
                    right: -4,
                    bottom: -4,
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color:
                              isDark ? const Color(0xFF102A44) : Colors.white,
                          width: 2,
                        ),
                      ),
                      child: Container(
                        margin: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Color(0xFF52B95B),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.username,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: nameColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (isBusiness)
                        ButtonVisibleGate(child: _BusinessBadge()),
                      const SizedBox(width: 10),
                      const _OnlineStatusPill(isOnline: isOnline),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BusinessBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.router.push(const ProAccountsRoute()),
      child: const PremiumBadge(),
    );
  }
}

class _OnlineStatusPill extends StatelessWidget {
  final bool isOnline;

  const _OnlineStatusPill({required this.isOnline});

  @override
  Widget build(BuildContext context) {
    final isDark = context.select((ThemeNotifier n) => n.isDarkMode);

    return _Pill(
      bg: isDark ? const Color(0xFF0B1B2A) : const Color(0xFFEFF3FF),
      textColor: isDark ? const Color(0xFFB7C4D6) : const Color(0xFF2A4B7C),
      leading: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: isOnline ? Colors.green : Colors.grey,
          shape: BoxShape.circle,
        ),
      ),
      text: isOnline ? 'в сети' : 'офлайн',
    );
  }
}

class _Pill extends StatelessWidget {
  final Color bg;
  final Color textColor;
  final Widget leading;
  final String text;

  const _Pill({
    required this.bg,
    required this.textColor,
    required this.leading,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          leading,
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
