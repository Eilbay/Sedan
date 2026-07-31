import 'package:auto_route/auto_route.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:optombai/app/router/app_router.dart';

import 'package:optombai/bloc/language_bloc/extensions/translation_context_extension.dart';
import 'package:optombai/bloc/pit_bloc/pit_bloc.dart';
import 'package:optombai/bloc/pit_bloc/pit_event.dart';
import 'package:optombai/bloc/pit_bloc/pit_state.dart';
import 'package:optombai/core/appColors.dart';
import 'package:optombai/core/dark/dark_background.dart';
import 'package:optombai/core/import_links.dart';
import 'package:optombai/data/mock/sedan_mock_listings.dart';
import 'package:optombai/data/models/account/user/socials/social_owner.dart';
import 'package:optombai/data/models/account/user/socials/social_type.dart';
import 'package:optombai/features/notifications/presentation/widgets/notification_bell_icon.dart';
import 'package:optombai/widgets/product/market_product_card.dart';
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

  // DEMO MODE: "promoting" a listing is simulated locally for showcase
  static const double _promoCost = 100;
  static const Duration _promoDuration = Duration(days: 7);
  final Map<String, DateTime> _promotedListings = {};
  bool _promoteLoading = false;

  Future<void> _handleRefresh() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
  }

  Future<void> _handlePromote(
      BuildContext context, SedanMockListing listing) async {
    if (_promotedListings.containsKey(listing.title) || _promoteLoading) {
      return;
    }

    final balance = context.read<PitBloc>().state.balance;
    if (balance < _promoCost) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'Нужно ${_promoCost.toStringAsFixed(0)} сом на балансе',
            ),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Пополнить',
              textColor: Colors.white,
              onPressed: () async {
                await context.router.push(const PitRoute());
                if (!context.mounted) return;
                _handlePromote(context, listing);
              },
            ),
          ),
        );
      return;
    }

    setState(() => _promoteLoading = true);
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    context.read<PitBloc>().add(const MockDebitPitEvent(amount: _promoCost));
    setState(() {
      _promoteLoading = false;
      _promotedListings[listing.title] = DateTime.now().add(_promoDuration);
    });

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        const SnackBar(
          content: Text('Объявление продвинуто!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  void _confirmStopPromotion(BuildContext context, SedanMockListing listing) {
    showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Остановить продвижение?'),
        content: const Text(
          'Товар перестанет показываться в рекламных местах.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Остановить'),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed != true || !mounted) return;
      setState(() => _promotedListings.remove(listing.title));
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(
            content: Text('Продвижение остановлено'),
            behavior: SnackBarBehavior.floating,
          ),
        );
    });
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
      postsCount: 2,
      rating: 5,
      reviewsCount: 3,
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
                        if (isCurrentUser) ...[
                          SizedBox(height: 12.h),
                          _WalletCard(isDark: isDark),
                        ],
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
      final listings = sedanMockListings.take(2).toList();
      final isDark = context.select((ThemeNotifier n) => n.isDarkMode);
      return Padding(
        padding: EdgeInsets.only(top: 14.h),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: listings.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12.h,
            crossAxisSpacing: 12.w,
            mainAxisExtent: 340.h,
          ),
          itemBuilder: (context, index) => _mockProductCard(
            context,
            listings[index],
            isDarkMode: isDark,
            isCompact: true,
          ),
        ),
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
      return const Column(
        children: [
          SizedBox(height: 14),
          _MockProfileReviewCard(
            name: 'Бакыт',
            rating: 5,
            text:
                'Быстро ответили, помогли подобрать машину и всё подробно объяснили.',
          ),
          SizedBox(height: 10),
          _MockProfileReviewCard(
            name: 'Айдана',
            rating: 5,
            text:
                'Автомобиль в отличном состоянии. Документы подготовили без задержек.',
          ),
          SizedBox(height: 10),
          _MockProfileReviewCard(
            name: 'Нурбек',
            rating: 5,
            text: 'Хороший автосалон, цены понятные, менеджер всегда на связи.',
          ),
        ],
      );
    }
    return const SizedBox();
  }

  Widget _mockProductCard(
    BuildContext context,
    SedanMockListing listing, {
    required bool isDarkMode,
    bool isCompact = false,
  }) {
    final cardColor = isDarkMode ? _darkCard : Colors.white;
    final borderColor =
        (isDarkMode ? Colors.white : Colors.black).withValues(alpha: 0.08);
    final subColor = isDarkMode ? Colors.white60 : Colors.black54;

    final year = listing.specs.isNotEmpty ? listing.specs.first.value : '';
    final engine = listing.specs.length > 1 ? listing.specs[1].value : '';

    if (isCompact) {
      final promoEndAt = _promotedListings[listing.title];
      final isPromoted = promoEndAt != null;
      const purple = Color(0xFF7B2FF2);

      void openDetails() {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => _MockListingDetailsPage(listing: listing),
          ),
        );
      }

      return Material(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 5,
                child: GestureDetector(
                  onTap: openDetails,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        listing.imageAsset,
                        fit: BoxFit.cover,
                      ),
                      Positioned(
                        left: 8,
                        bottom: 8,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.remove_red_eye,
                                size: 15, color: Colors.white),
                            const SizedBox(width: 4),
                            Text(
                              '${listing.views}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                shadows: [
                                  Shadow(blurRadius: 4, color: Colors.black54),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isPromoted)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: () =>
                                _confirmStopPromotion(context, listing),
                            child: const VipBadgeNew(),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if (!isPromoted) ...[
                Container(height: 1, color: borderColor),
                InkWell(
                  onTap: () => _handlePromote(context, listing),
                  child: SizedBox(
                    height: 38.h,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.campaign, size: 16, color: purple),
                        SizedBox(width: 6),
                        Text(
                          'Запустить рекламу',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: purple,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              Expanded(
                flex: 5,
                child: InkWell(
                  onTap: openDetails,
                  child: Padding(
                    padding: EdgeInsets.all(10.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          listing.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            height: 1.15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          [year, engine]
                              .where((value) => value.isNotEmpty)
                              .join(' · '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: subColor, fontSize: 12),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          listing.condition,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: subColor,
                            fontSize: 12,
                            height: 1.25,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          listing.price,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF2F80ED),
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Material(
      color: cardColor,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => _MockListingDetailsPage(listing: listing),
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 128.w,
                height: 118.h,
                child: Image.asset(
                  listing.imageAsset,
                  fit: BoxFit.cover,
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(12.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        listing.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 7.h),
                      Text(
                        [year, engine]
                            .where((value) => value.isNotEmpty)
                            .join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: subColor, fontSize: 12),
                      ),
                      SizedBox(height: 10.h),
                      Text(
                        listing.price,
                        style: const TextStyle(
                          color: Color(0xFF2F80ED),
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: 45.h, right: 10.w),
                child: Icon(
                  Icons.chevron_right,
                  color: subColor,
                  size: 24,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// DEMO MODE: shows the mock advertising wallet balance right on the profile
class _WalletCard extends StatelessWidget {
  const _WalletCard({required this.isDark});

  final bool isDark;

  static const _purple = Color(0xFF7B2FF2);
  static const _green = Color(0xFF2EB872);

  static String _formatThousands(num value) {
    final text = value.round().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < text.length; i++) {
      if (i > 0 && (text.length - i) % 3 == 0) buffer.write(' ');
      buffer.write(text[i]);
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PitBloc, PitState>(
      buildWhen: (p, c) => p.balance != c.balance,
      builder: (context, state) {
        return Container(
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            color: isDark ? _ProfileScreenState._darkCard : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: (isDark ? Colors.white : Colors.black)
                  .withValues(alpha: 0.06),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: _purple.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.account_balance_wallet,
                    color: _purple, size: 24),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Рекламный кошелек',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      '${_formatThousands(state.balance)} сом',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 30.h,
                child: ElevatedButton(
                  onPressed: () async {
                    await context.router.push(const PitRoute());
                    if (context.mounted) {
                      context.read<PitBloc>().add(const LoadPitEvent());
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _green,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: EdgeInsets.symmetric(horizontal: 12.w),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Пополнить',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MockListingDetailsPage extends StatefulWidget {
  const _MockListingDetailsPage({required this.listing});

  final SedanMockListing listing;

  @override
  State<_MockListingDetailsPage> createState() =>
      _MockListingDetailsPageState();
}

class _MockListingDetailsPageState extends State<_MockListingDetailsPage> {
  bool _isSaved = false;
  int _financeIndex = 0;
  double _termMonths = 36;

  // DEMO MODE: same simulated promotion as the "Мои объявления" grid card —
  static const double _promoCost = 100;
  static const Duration _promoDuration = Duration(days: 7);
  DateTime? _promoEndAt;
  bool _promoting = false;

  Future<void> _handlePromote() async {
    if (_promoEndAt != null || _promoting) return;

    final balance = context.read<PitBloc>().state.balance;
    if (balance < _promoCost) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'Нужно ${_promoCost.toStringAsFixed(0)} сом на балансе',
            ),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Пополнить',
              textColor: Colors.white,
              onPressed: () async {
                await context.router.push(const PitRoute());
                if (!context.mounted) return;
                _handlePromote();
              },
            ),
          ),
        );
      return;
    }

    setState(() => _promoting = true);
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    context.read<PitBloc>().add(const MockDebitPitEvent(amount: _promoCost));
    setState(() {
      _promoting = false;
      _promoEndAt = DateTime.now().add(_promoDuration);
    });

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        const SnackBar(
          content: Text('Объявление продвинуто!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  void _confirmStopPromotion() {
    showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Остановить продвижение?'),
        content: const Text(
          'Товар перестанет показываться в рекламных местах.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Остановить'),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed != true || !mounted) return;
      setState(() => _promoEndAt = null);
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(
            content: Text('Продвижение остановлено'),
            behavior: SnackBarBehavior.floating,
          ),
        );
    });
  }

  String get _usdPrice => widget.listing.price;

  String get _somPrice {
    final raw = widget.listing.price.replaceAll(RegExp(r'[^0-9]'), '').trim();
    final usd = int.tryParse(raw) ?? 0;
    if (usd == 0) return widget.listing.price;
    return '${_formatNumber(usd * 89)} сом';
  }

  int get _monthlyPayment {
    final raw = widget.listing.price.replaceAll(RegExp(r'[^0-9]'), '').trim();
    final usd = int.tryParse(raw) ?? 0;
    if (usd == 0) return 0;
    return (usd / _termMonths).round();
  }

  static String _formatNumber(num value) {
    final text = value.round().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < text.length; i++) {
      if (i > 0 && (text.length - i) % 3 == 0) buffer.write(' ');
      buffer.write(text[i]);
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    const bg = Colors.black;
    final listing = widget.listing;
    final categoryTitle = sedanMockCategoryTitleForKey(listing.categoryKey);

    return Scaffold(
      backgroundColor: bg,
      bottomNavigationBar:
          const BottomNav(currentIndexOverride: -1, passive: true),
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 0),
                child: _MockDetailsTopBar(
                  title: listing.title,
                  isSaved: _isSaved,
                  isPromoted: _promoEndAt != null,
                  onBack: () => Navigator.of(context).maybePop(),
                  onSavedTap: () => setState(() => _isSaved = !_isSaved),
                  onMenuAction: (action) {
                    if (action == 'promote') _handlePromote();
                    if (action == 'stop') _confirmStopPromotion();
                  },
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(15.w, 18.h, 15.w, 0),
              sliver: SliverList(
                delegate: SliverChildListDelegate(
                  [
                    _MockDetailsHero(listing: listing),
                    SizedBox(height: 14.h),
                    _MockDetailsPriceRow(
                      somPrice: _somPrice,
                      usdPrice: _usdPrice,
                      views: 128,
                    ),
                    SizedBox(height: 14.h),
                    Text(
                      listing.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                    SizedBox(height: 14.h),
                    const _MockSellerCard(),
                    SizedBox(height: 24.h),
                    const _MockSectionTitle('Описание'),
                    SizedBox(height: 10.h),
                    Text(
                      listing.condition,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 15,
                        height: 1.45,
                      ),
                    ),
                    SizedBox(height: 26.h),
                    const _MockSectionTitle('Кредит и финансирование'),
                    SizedBox(height: 12.h),
                    _MockFinanceTabs(
                      selectedIndex: _financeIndex,
                      onChanged: (index) => setState(() {
                        _financeIndex = index;
                      }),
                    ),
                    SizedBox(height: 12.h),
                    const _MockFinanceInfoCard(),
                    SizedBox(height: 14.h),
                    _MockFinanceCalculator(
                      price: _usdPrice,
                      termMonths: _termMonths,
                      monthlyPayment: _monthlyPayment,
                      onTermChanged: (value) => setState(() {
                        _termMonths = value;
                      }),
                    ),
                    SizedBox(height: 24.h),
                    const _MockSectionTitle('О товаре'),
                    SizedBox(height: 16.h),
                    _MockDetailsInfoRow(
                        label: 'Название', value: listing.title),
                    _MockDetailsInfoRow(
                      label: 'Категория',
                      value: categoryTitle,
                      valueColor: const Color(0xFF2F80ED),
                    ),
                    for (final spec in listing.specs)
                      _MockDetailsInfoRow(
                        label: spec.label,
                        value: spec.value,
                      ),
                    SizedBox(height: 28.h),
                    const Center(
                      child: Text(
                        'Авторизуйтесь чтобы оставить отзыв!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    SizedBox(
                      height: kBottomNavigationBarHeight +
                          MediaQuery.viewPaddingOf(context).bottom +
                          28.h,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MockDetailsTopBar extends StatelessWidget {
  const _MockDetailsTopBar({
    required this.title,
    required this.isSaved,
    required this.isPromoted,
    required this.onBack,
    required this.onSavedTap,
    required this.onMenuAction,
  });

  final String title;
  final bool isSaved;
  final bool isPromoted;
  final VoidCallback onBack;
  final VoidCallback onSavedTap;
  final ValueChanged<String> onMenuAction;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54.h,
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              title.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
          ),
          IconButton(
            onPressed: onSavedTap,
            icon: Icon(
              isSaved ? Icons.bookmark : Icons.bookmark_border,
              color: Colors.white,
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.share, color: Colors.white),
          ),
          PopupMenuButton<String>(
            color: const Color(0xff192536),
            onSelected: onMenuAction,
            icon: const Icon(Icons.more_vert, color: Colors.white),
            itemBuilder: (_) => [
              if (!isPromoted)
                const PopupMenuItem<String>(
                  value: 'promote',
                  child: Row(
                    children: [
                      Icon(Icons.trending_up, color: Color(0xff0095D5)),
                      SizedBox(width: 8),
                      Text('Продвинуть', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                )
              else
                const PopupMenuItem<String>(
                  value: 'stop',
                  child: Row(
                    children: [
                      Icon(Icons.trending_down, color: Colors.orange),
                      SizedBox(width: 8),
                      Text('Остановить продвижение',
                          style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MockDetailsHero extends StatelessWidget {
  const _MockDetailsHero({required this.listing});

  final SedanMockListing listing;

  @override
  Widget build(BuildContext context) {
    final specs = listing.specs;
    final year = specs.isNotEmpty ? specs.first.value : '-';
    final engine = specs.length > 1 ? specs[1].value : '-';
    final category = sedanMockCategoryTitleForKey(listing.categoryKey);

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: AspectRatio(
        aspectRatio: 1.05,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(listing.imageAsset, fit: BoxFit.cover),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.08),
                      Colors.black.withValues(alpha: 0.72),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 16.w,
              right: 16.w,
              bottom: 20.h,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _HeroSpec(value: year, label: 'ГОД'),
                  _HeroSpec(value: engine, label: 'ДВИГАТЕЛЬ'),
                  _HeroSpec(value: category, label: 'КАТЕГОРИЯ'),
                ],
              ),
            ),
            Positioned(
              bottom: 8.h,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF2F80ED),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroSpec extends StatelessWidget {
  const _HeroSpec({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$value\n',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            TextSpan(
              text: label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                height: 1.1,
              ),
            ),
          ],
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _MockDetailsPriceRow extends StatelessWidget {
  const _MockDetailsPriceRow({
    required this.somPrice,
    required this.usdPrice,
    required this.views,
  });

  final String somPrice;
  final String usdPrice;
  final int views;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 9.h),
          decoration: BoxDecoration(
            color: const Color(0xFF2F80ED),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            somPrice,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
        ),
        SizedBox(width: 12.w),
        Text(
          usdPrice,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
        const Spacer(),
        const Icon(Icons.remove_red_eye_outlined, color: Colors.white70),
        SizedBox(width: 4.w),
        Text(
          views.toString(),
          style: const TextStyle(color: Colors.white70),
        ),
      ],
    );
  }
}

class _MockSellerCard extends StatelessWidget {
  const _MockSellerCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: const Color(0xFF14181F),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 24,
            backgroundImage: AssetImage('assets/icons/support_agent.jpg'),
          ),
          SizedBox(width: 12.w),
          const Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    'Aibek.Auto',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                SizedBox(width: 6),
                Icon(Icons.verified, color: Color(0xFF2F80ED), size: 18),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.white60),
        ],
      ),
    );
  }
}

class _MockSectionTitle extends StatelessWidget {
  const _MockSectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _MockFinanceTabs extends StatelessWidget {
  const _MockFinanceTabs({
    required this.selectedIndex,
    required this.onChanged,
  });

  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    const labels = ['Кредит', 'Лизинг', 'Рассрочка'];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF14181F),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: List.generate(labels.length, (index) {
          final selected = selectedIndex == index;
          return Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => onChanged(index),
              child: Container(
                alignment: Alignment.center,
                padding: EdgeInsets.symmetric(vertical: 10.h),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: selected
                      ? Border.all(color: const Color(0xFF2F80ED), width: 1.5)
                      : null,
                ),
                child: Text(
                  labels[index],
                  style: TextStyle(
                    color: selected ? const Color(0xFF2F80ED) : Colors.white70,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _MockFinanceInfoCard extends StatelessWidget {
  const _MockFinanceInfoCard();

  @override
  Widget build(BuildContext context) {
    const items = [
      'Быстрое предварительное одобрение',
      'Первоначальный взнос от 30%',
      'Прозрачные условия',
      'Срок финансирования до 60 месяцев',
    ];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color(0xFF14181F),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Финансирование автомобиля',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 12.h),
          for (final item in items)
            Padding(
              padding: EdgeInsets.only(bottom: 7.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check, color: Color(0xFF2EB872), size: 18),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        height: 1.25,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _MockFinanceCalculator extends StatelessWidget {
  const _MockFinanceCalculator({
    required this.price,
    required this.termMonths,
    required this.monthlyPayment,
    required this.onTermChanged,
  });

  final String price;
  final double termMonths;
  final int monthlyPayment;
  final ValueChanged<double> onTermChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color(0xFF14181F),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Expanded(
                child: Text(
                  'Калькулятор',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Icon(Icons.edit_outlined, color: Colors.white60, size: 18),
            ],
          ),
          SizedBox(height: 14.h),
          Row(
            children: [
              Expanded(
                child: _CalculatorValue(label: 'Стоимость', value: price),
              ),
              const Expanded(
                child: _CalculatorValue(
                  label: 'Первоначальный взнос',
                  value: '30%',
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Ежемесячный платёж',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
                Text(
                  '$monthlyPayment \$',
                  style: const TextStyle(
                    color: Color(0xFF2F80ED),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),
          const Text(
            'Срок, месяцы',
            style: TextStyle(color: Colors.white54),
          ),
          Slider(
            min: 12,
            max: 60,
            divisions: 4,
            value: termMonths,
            activeColor: const Color(0xFF2F80ED),
            onChanged: onTermChanged,
          ),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('12 мес.', style: TextStyle(color: Colors.white54)),
              Text('60 мес.', style: TextStyle(color: Colors.white54)),
            ],
          ),
          SizedBox(height: 16.h),
          Container(
            width: double.infinity,
            alignment: Alignment.center,
            padding: EdgeInsets.symmetric(vertical: 15.h),
            decoration: BoxDecoration(
              color: const Color(0xFF2F80ED).withValues(alpha: 0.28),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Text(
              'Подать заявку',
              style: TextStyle(
                color: Colors.white54,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CalculatorValue extends StatelessWidget {
  const _CalculatorValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$label\n',
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          TextSpan(
            text: value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              height: 1.8,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _MockDetailsInfoRow extends StatelessWidget {
  const _MockDetailsInfoRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 13.h),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
        ),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
            TextSpan(
              text: value,
              style: TextStyle(color: valueColor ?? Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}

class _MockProfileReviewCard extends StatelessWidget {
  const _MockProfileReviewCard({
    required this.name,
    required this.rating,
    required this.text,
  });

  final String name;
  final int rating;
  final String text;

  @override
  Widget build(BuildContext context) {
    final isDark = context.select((ThemeNotifier n) => n.isDarkMode);
    final cardColor = isDark ? _ProfileScreenState._darkCard : Colors.white;
    final borderColor =
        (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08);
    final subColor = isDark ? Colors.white70 : Colors.black54;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor:
                    const Color(0xFF2F80ED).withValues(alpha: 0.18),
                child: Text(
                  name.characters.first,
                  style: const TextStyle(
                    color: Color(0xFF2F80ED),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              Row(
                children: List.generate(
                  5,
                  (index) => Icon(
                    index < rating ? Icons.star : Icons.star_border,
                    color: const Color(0xFFFFB300),
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Text(
            text,
            style: TextStyle(color: subColor, height: 1.35),
          ),
        ],
      ),
    );
  }
}

