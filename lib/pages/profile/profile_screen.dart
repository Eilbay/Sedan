import 'package:auto_route/auto_route.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:optombai/app/router/app_router.dart';
import 'package:optombai/bloc/auth_bloc/auth_cubit.dart';

import 'package:optombai/bloc/language_bloc/extensions/translation_context_extension.dart';
import 'package:optombai/core/appColors.dart';
import 'package:optombai/core/dark/dark_background.dart';
import 'package:optombai/core/import_links.dart';
import 'package:optombai/data/models/account/user/socials/social_owner.dart';
import 'package:optombai/data/models/account/user/socials/social_type.dart';
import 'package:optombai/features/notifications/presentation/widgets/notification_bell_icon.dart';
import 'package:optombai/widgets/bottom_nav.dart';
import 'package:optombai/widgets/profile/about_us/about_us_card.dart';
import 'package:optombai/widgets/profile/profile_header.dart';
import 'package:optombai/widgets/translation/text_translated.dart';

@RoutePage()
class ProfileScreen extends StatefulWidget {
  const ProfileScreen(
      {super.key, required this.username, required this.userId});

  final String username;
  final String userId;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const _green = Color(0xFF2EB872);
  static const _darkCard = Color(0xFF14181F);
  static const _mockProfileDescription =
      'Автосалон «Aibek.Auto» — большой выбор автомобилей на любой вкус и бюджет!';
  static const _mockProfileAboutUs = '''
🚘 Автосалон «Aibek.Auto» — большой выбор автомобилей на любой вкус и бюджет!

💰 Выгодные цены
🔄 Обмен (Trade-in)
💳 Кредит и рассрочка
📄 Полное оформление документов
''';
  static const _mockProfilePhone = '0555506311';
  static const _mockProfileWhatsApp = '996555506311';

  int currentIndex = 0;
  final ScrollController _controller = ScrollController();

  Future<void> _handleRefresh() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
  }

  void _handleBack(BuildContext context) async {
    debugPrint(
      '[PROFILE] back pressed userId=${widget.userId} username=${widget.username}',
    );
    final popped = await context.router.maybePop();
    if (popped) return;

    if (!mounted) return;
    BottomNav.of(context)?.setTab(0);
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  User _mockProfileUser() {
    final mocked = User(
      id: 'mock-aibek-auto',
      username: 'Aibek.Auto',
      description: _mockProfileDescription,
      about_us: _mockProfileAboutUs.trim(),
      phone_number: _mockProfilePhone,
      userType: 'auto_salon',
      image: null,
      postsCount: 0,
      rating: 0,
      reviewsCount: 0,
      is_active: true,
      is_verified: true,
    );

    mocked.socials = const [
      SocialOwner(
        id: -1,
        owner: 'mock-aibek-auto',
        link: _mockProfileWhatsApp,
        socialType: SocialType(
          id: -1,
          title: 'WhatsApp',
          domainUrl: 'https://wa.me/',
          logo: 'assets/icons/socials_dark/whatsapp_dark.png',
        ),
      ),
    ];

    return mocked;
  }

  Widget _topBar(BuildContext context, bool isDark, bool isCurrentUser,
      String id, User currentUser) {
    return Padding(
      padding: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 4.h),
      child: Row(
        children: [
          _circleButton(
            isDark: isDark,
            child: Icon(Icons.arrow_back_ios_new,
                size: 18, color: isDark ? Colors.white : Colors.black87),
            onTap: () => _handleBack(context),
          ),
          const Spacer(),
          if (isCurrentUser)
            _circleButton(
              isDark: isDark,
              child: Icon(Icons.edit_outlined,
                  size: 20, color: isDark ? Colors.white : Colors.black87),
              onTap: () =>
                  context.router.push(ProfileEditRoute(user: currentUser)),
            )
          else
            _circleButton(
              isDark: isDark,
              child: NotificationBellIcon(
                iconColor: isDark ? Colors.white : Colors.black87,
              ),
              onTap: null,
            ),
          SizedBox(width: 10.w),
          if (!isCurrentUser)
            _circleButton(
              isDark: isDark,
              child: Icon(Icons.more_horiz,
                  size: 22, color: isDark ? Colors.white : Colors.black87),
              onTap: () => _showOptionsSheet(
                  context, isDark, isCurrentUser, id, currentUser),
            ),
          SizedBox(width: 10.w),
          _circleButton(
            isDark: isDark,
            child: Icon(Icons.menu,
                size: 22, color: isDark ? Colors.white : Colors.black87),
            onTap: () => context.router.push(const SettingsRoute()),
          ),
        ],
      ),
    );
  }

  Widget _circleButton({
    required bool isDark,
    required Widget child,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isDark ? _darkCard : Colors.white,
          shape: BoxShape.circle,
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        child: child,
      ),
    );
  }

  void _showOptionsSheet(BuildContext context, bool isDark, bool isCurrentUser,
      String id, User currentUser) {
    if (!isCurrentUser) {
      showModalBottomSheet(
        context: context,
        backgroundColor: isDark ? _darkCard : Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
        ),
        builder: (sheetCtx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.flag_outlined),
                title: const TextTranslated('Пожаловаться'),
                onTap: () => Navigator.pop(sheetCtx),
              ),
            ],
          ),
        ),
      );
      return;
    }

    /* final bool isRegister = context.read<ThemeNotifier>().isRegister;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? _darkCard : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (sheetCtx) {
        return SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: EdgeInsets.only(top: 10.h, bottom: 6.h),
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
                _drawerTile(sheetCtx,
                    icon: Icons.bookmark_border,
                    title: 'Сохранённые публикации',
                    onTap: () => context.router.push(const FavoriteRoute())),
                _drawerTile(sheetCtx,
                    image: 'assets/icons/drawer_icons/buyer.png',
                    title: 'Пользователям',
                    onTap: () => context.router.push(const UsersRoute())),
                _drawerTile(sheetCtx,
                    image: 'assets/icons/drawer_icons/fullfilment.png',
                    title: 'Фулфилмент',
                    onTap: () => context.router.push(const FulfilmentRoute())),
                ButtonVisibleGate(
                  child: _drawerTile(sheetCtx,
                      image: 'assets/icons/drawer_icons/premium.png',
                      title: 'Тарифы',
                      onTap: () =>
                          context.router.push(const ProAccountsRoute())),
                ),
                _drawerTile(sheetCtx,
                    image: 'assets/pro2.png',
                    title: 'О платформе ',
                    onTap: () => context.router.push(const AboutUsRoute())),
                _drawerTile(sheetCtx,
                    image: 'assets/icons/drawer_icons/legal.png',
                    title: 'О нас',
                    onTap: () => context.router.push(const LawDataRoute())),
                _drawerTile(sheetCtx,
                    image: 'assets/icons/drawer_icons/more.png',
                    title: 'Пользовательское соглашение',
                    onTap: () => context.router.push(const PrimaryRoute())),
                _drawerTile(sheetCtx,
                    image: 'assets/polite.png',
                    title: 'Политика конфиденциальности',
                    onTap: () => context.router.push(const PoliticsRoute())),
                _drawerTile(sheetCtx,
                    image: 'assets/icons/drawer_icons/shopping.png',
                    title: 'Публичная оферта',
                    onTap: () => context.router.push(const OfertaRoute())),
                if (isRegister)
                  _drawerTile(sheetCtx,
                      image: 'assets/icons/drawer_icons/more.png',
                      title: 'Заблокированные пользователи',
                      onTap: () =>
                          context.router.push(const BlockedUsersRoute())),
                Divider(
                  height: 8.h,
                  color: (isDark ? Colors.white : Colors.black)
                      .withValues(alpha: 0.08),
                ),
                _drawerTile(sheetCtx,
                    icon: Icons.logout,
                    iconColor: Colors.red,
                    titleColor: Colors.red,
                    title: 'Выйти',
                    onTap: () => _confirmLogout(context, id)),
                SizedBox(height: 8.h),
              ],
            ),
          ),
        );
      },
    );*/
  }

  Widget _drawerTile(
    BuildContext sheetCtx, {
    IconData? icon,
    String? image,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
    Color? titleColor,
  }) {
    final bool isDark = sheetCtx.read<ThemeNotifier>().isDarkMode;
    final accent = iconColor ??
        (isDark ? const Color(0xff75CEFF) : const Color(0xff006199));

    return ListTile(
      leading: icon != null
          ? Icon(icon, color: accent, size: 26)
          : Image.asset(image!, color: accent, width: 26, height: 26),
      title: TextTranslated(
        title,
        style: titleColor != null ? TextStyle(color: titleColor) : null,
      ),
      onTap: () {
        Navigator.pop(sheetCtx);
        onTap();
      },
    );
  }

  void _confirmLogout(BuildContext context, String id) {
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
                    debugPrint('[AUTH] logout from profile screen');
                    await context.read<AuthCubit>().clear(id);
                    if (!context.mounted) return;
                    context.read<ThemeNotifier>().setRegistrationStatus(false);
                    context.router.replaceAll([
                      const SignInRoute(),
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

  @override
  Widget build(BuildContext context) {
    final bool isDark = context.select((ThemeNotifier n) => n.isDarkMode);
    final bool isRegister = context.select((ThemeNotifier n) => n.isRegister);
    var bloc = context.select((UserBloc b) => b.state);
    const bool isCurrentUser = true;
    User currentUser = _mockProfileUser();
    final id = bloc.user.id;
    debugPrint(
      '[PROFILE] build isRegister=$isRegister isCurrentUser=$isCurrentUser '
      'userId=${widget.userId} currentUserId=$id',
    );

    return DefaultTabController(
      length: 3,
      child: _buildScaffold(context, isDark, isCurrentUser, currentUser, id),
    );
  }

  Widget _buildScaffold(BuildContext context, bool isDark, bool isCurrentUser,
      User currentUser, String id) {
    final scaffold = Scaffold(
      backgroundColor: isDark ? AppColors.black : AppColors.lightBackground,
      body: SafeArea(
        top: true,
        bottom: false,
        child: Column(
          children: [
            _topBar(context, isDark, isCurrentUser, id, currentUser),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _handleRefresh,
                child: SingleChildScrollView(
                  controller: _controller,
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: Column(
                      children: [
                        SizedBox(height: 8.h),
                        ProfileHeader(
                          postCounts: currentUser.postsCount,
                          isCurrentUser: isCurrentUser,
                          currentUser: currentUser,
                          showInlineMenu: false,
                        ),
                        SizedBox(height: 16.h),
                        _logoutButton(context, isDark, id),
                        SizedBox(height: 10.h),
                        _tabBar(context),
                        _tabContent(context),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
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

  Widget _logoutButton(BuildContext context, bool isDark, String id) {
    return InkWell(
      borderRadius: BorderRadius.circular(14.r),
      onTap: () => _confirmLogout(context, id),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: isDark ? _darkCard : Colors.white,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: Colors.red.withValues(alpha: isDark ? 0.45 : 0.22),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.logout, color: Colors.red),
            SizedBox(width: 10.w),
            TextTranslated(
              'Выход',
              style: TextStyle(
                color: Colors.red,
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tabBar(BuildContext context) {
    return FutureBuilder<List<String>>(
      future: Future.wait([
        context.translateText("Объявления"),
        context.translateText("О нас"),
        context.translateText("Отзывы"),
      ]),
      builder: (context, snapshot) {
        String t0 = "Объявления";
        String t1 = "О нас";
        String t2 = "Отзывы";
        if (snapshot.hasData) {
          t0 = snapshot.data![0];
          t1 = snapshot.data![1];
          t2 = snapshot.data![2];
        }
        return TabBar(
          dividerColor: Colors.transparent,
          labelColor: _green,
          unselectedLabelColor: Colors.grey,
          overlayColor: WidgetStateProperty.all(Colors.transparent),
          indicatorColor: _green,
          indicatorSize: TabBarIndicatorSize.tab,
          onTap: (index) => setState(() => currentIndex = index),
          tabs: [Tab(text: t0), Tab(text: t1), Tab(text: t2)],
        );
      },
    );
  }

  Widget _tabContent(BuildContext context) {
    if (currentIndex == 0) {
      return Column(
        children: [
          SizedBox(height: 55.h),
          CustomButton(
            title: 'Добавить товар +',
            onPressed: () async {
              await BottomNav.of(context)?.openAddProduct();
            },
            borderRadius: 10,
          ),
        ],
      );
    } else if (currentIndex == 1) {
      const bool isCurrentUser = true;
      final currentUser = _mockProfileUser();
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const TextTranslated(
              "О нас",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 19.h),
            AboutUsCard(user: currentUser, isCurrentUser: isCurrentUser),
            const SizedBox(height: 12),
            RequisitesCard(user: currentUser, isCurrentUser: isCurrentUser),
          ],
        ),
      );
    } else if (currentIndex == 2) {
      return Padding(
        padding: EdgeInsets.only(top: 40.h),
        child: const Center(
          child: TextTranslated('Отзывов пока нет'),
        ),
      );
    }
    return const SizedBox();
  }
}
