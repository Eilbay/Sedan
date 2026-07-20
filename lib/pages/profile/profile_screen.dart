import 'package:auto_route/auto_route.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:optombai/app/router/app_router.dart';
import 'package:optombai/bloc/auth_bloc/auth_cubit.dart';
// TODO: temporarily hidden — promotion campaigns card

import 'package:optombai/bloc/image_bloc/image_bloc.dart';
import 'package:optombai/bloc/language_bloc/extensions/translation_context_extension.dart';
import 'package:optombai/bloc/store_review_bloc/store_review_bloc.dart';
import 'package:optombai/core/appColors.dart';
import 'package:optombai/core/dark/dark_background.dart';
import 'package:optombai/core/di/injection.dart';
import 'package:optombai/core/import_links.dart';
import 'package:optombai/features/notifications/presentation/widgets/notification_bell_icon.dart';
import 'package:optombai/features/promotion/domain/repository/promotion_repository.dart';
import 'package:optombai/features/promotion/presentation/logic/promotion_cubit.dart';
import 'package:optombai/features/promotion/presentation/widgets/promotion_dialog.dart';
import 'package:optombai/pages/profile/edit/widgets/media_tile.dart';
import 'package:optombai/widgets/bottom_nav.dart';
import 'package:optombai/widgets/product/market_product_card.dart';
import 'package:optombai/widgets/profile/about_us/profile_about_us.dart';
import 'package:optombai/widgets/profile/profile_header.dart';
import 'package:optombai/widgets/shimmer/shimmer_profile_grid.dart';
import 'package:optombai/widgets/translation/text_translated.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  int currentIndex = 0;
  final ScrollController _controller = ScrollController();

  Future<void> _handleRefresh() async {
    final productBloc = context.read<ProductBloc>();
    productBloc.add(
      GetProfileProductsEvent(widget.username, forceRefresh: true),
    );
    context.read<StoreReviewBloc>().add(AllStoreReviewEvent(widget.userId));
    context.read<ImageBloc>().add(GetAllImage(widget.userId));
    context.read<DocumentBloc>().add(GetAllDocumentImage(widget.userId));

    final currentUserId = context.read<UserBloc>().state.user.id;
    if (widget.userId == currentUserId) {
      context.read<UserBloc>().add(UserOwnerEvent());
    }

    // Wait for products to finish loading so RefreshIndicator stays visible
    await productBloc.stream.firstWhere((s) => !s.isLoading).timeout(
        const Duration(seconds: 10),
        onTimeout: () => productBloc.state);
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

  Future<void> _openPromotion(Product product) async {
    final result = await PromotionDialog.show(
      context,
      postId: product.id,
      productName: product.name,
      preferences: getIt<SharedPreferences>(),
      isAlreadyPromoted: _isProductPromoted(product),
      promoEndAt: product.promoEndAt,
    );

    if (result == true && mounted) {
      context
          .read<ProductBloc>()
          .add(RefreshSingleProduct(product.id, preserveLocalPromotion: true));
      context.read<PromotionCubit>().loadMyCampaigns();
    }
  }

  @override
  void initState() {
    super.initState();
    // Load unconditionally: the current user (UserOwnerEvent inside) must be
    // fetched even though `username`/`userId` arrive empty at launch (the
    // bottom nav builds this screen eagerly, before UserBloc is populated).
    // The identity-dependent product/header fetches simply no-op while empty
    // and are re-run from didUpdateWidget once the identity is populated.
    _loadProfileData();

    // Infinite-scroll pagination: when user nears the bottom of the
    // grid (within 200px) we fetch the next page. Mirrors the pattern
    // used in chat_list_screen.dart.
    _controller.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(covariant ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // `username`/`userId` start empty at app launch and get populated once
    // UserBloc loads the current user. initState already ran (with empty
    // values) by then, so re-run the load when the identity appears or
    // changes (e.g. account switch) — this is what fills the product grid.
    if (oldWidget.username != widget.username ||
        oldWidget.userId != widget.userId) {
      _loadProfileData();
    }
  }

  void _loadProfileData() {
    debugPrint(
      '[PROFILE] _loadProfileData userId=${widget.userId} '
      'username=${widget.username}',
    );
    context.read<ProductBloc>().add(GetProfileProductsEvent(widget.username));
    context.read<StoreReviewBloc>().add(AllStoreReviewEvent(widget.userId));
    context.read<ImageBloc>().add(GetAllImage(widget.userId));
    context.read<DocumentBloc>().add(GetAllDocumentImage(widget.userId));

    final currentUserId = context.read<UserBloc>().state.user.id;
    if (widget.userId == currentUserId) {
      debugPrint('[PROFILE] _loadProfileData -> UserOwnerEvent');
      context.read<UserBloc>().add(UserOwnerEvent());
    }
    debugPrint(
      '[PROFILE] _loadProfileData -> UserVisit currentUserId=$currentUserId',
    );
    context.read<UserBloc>().add(UserVisit(currentUserId));
  }

  void _onScroll() {
    if (!_controller.hasClients) return;
    if (_controller.position.pixels <
        _controller.position.maxScrollExtent - 200) {
      return;
    }
    final bloc = context.read<ProductBloc>();
    final s = bloc.state;
    if (s.isLoadingProfileMore || !s.hasMoreProfileProducts) return;
    debugPrint(
      '[PROFILE] _onScroll fetchMore userId=${widget.userId} '
      'pixels=${_controller.position.pixels} max=${_controller.position.maxScrollExtent}',
    );
    bloc.add(FetchMoreProfileProductsEvent(widget.username));
  }

  @override
  void dispose() {
    _controller.removeListener(_onScroll);
    _controller.dispose();
    super.dispose();
  }

  bool _isProductPromoted(
    Product p, [
    Set<String> activeCampaignPostIds = const <String>{},
  ]) {
    if (p.isPromoted == true) return true;
    if (activeCampaignPostIds.contains(p.id)) return true;
    if ((p.promoCampaignId ?? '').trim().isNotEmpty) return true;

    final end = p.promoEndAt;
    if (end != null && end.isAfter(DateTime.now())) return true;

    return false;
  }

  Set<String> _activeCampaignPostIds(PromotionState state) {
    return state.myCampaigns
        .where((campaign) => campaign.isActive)
        .map((campaign) => campaign.postId)
        .toSet();
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

  void showStopPromotionSheet(
    BuildContext context, {
    required Product product,
    required Future<bool> Function() onConfirm,
  }) {
    final isDark = context.read<ThemeNotifier>().isDarkMode;

    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (ctx) {
        final bg = isDark ? const Color(0xff0e1e33) : Colors.white;
        final border = isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.06);
        final textPrimary = isDark ? Colors.white : const Color(0xff111827);
        final textSecondary = isDark ? Colors.white70 : const Color(0xff6B7280);

        return Padding(
          padding: EdgeInsets.only(
            left: 12,
            right: 12,
            bottom: MediaQuery.viewInsetsOf(ctx).bottom + 12,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: border),
              boxShadow: [
                BoxShadow(
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                  color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.18),
                ),
              ],
            ),
            child: StatefulBuilder(
              builder: (ctx, setLocalState) {
                bool loading = false;

                Future<void> handleConfirm() async {
                  if (loading) return;
                  setLocalState(() => loading = true);

                  final ok = await onConfirm();

                  if (!ctx.mounted) return;
                  Navigator.pop(ctx);

                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(ok
                          ? 'Продвижение остановлено'
                          : 'Не удалось остановить продвижение'),
                    ),
                  );
                }

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 10),
                    Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: (isDark ? Colors.white : Colors.black)
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Column(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: const Color(0xff0095D5)
                                      .withValues(alpha: isDark ? 0.22 : 0.12),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Center(
                                  child: Text('🔥',
                                      style: TextStyle(fontSize: 18)),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Остановить продвижение?',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: textPrimary,
                                        height: 1.2,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Товар перестанет показываться в рекламных местах.',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: textSecondary,
                                        height: 1.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () => Navigator.pop(ctx),
                                icon: Icon(Icons.close, color: textSecondary),
                                splashRadius: 18,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.05)
                                  : const Color(0xffF7F7F9),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: (isDark ? Colors.white : Colors.black)
                                    .withValues(alpha: 0.06),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.campaign,
                                    size: 18, color: Color(0xff0095D5)),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    product.name.isEmpty
                                        ? 'Товар'
                                        : product.name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed:
                                      loading ? null : () => Navigator.pop(ctx),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    side: BorderSide(
                                      color:
                                          (isDark ? Colors.white : Colors.black)
                                              .withValues(alpha: 0.14),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: Text(
                                    'Отмена',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: textPrimary,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: loading ? null : handleConfirm,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xff0095D5),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: loading
                                      ? const SizedBox(
                                          height: 18,
                                          width: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Text(
                                          'Остановить',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  _showStopPromotionSheet(BuildContext context, Product product) {
    showStopPromotionSheet(
      context,
      product: product,
      onConfirm: () async {
        final promotionCubit = context.read<PromotionCubit>();
        final productBloc = context.read<ProductBloc>();
        final ok = await promotionCubit.cancelActiveForPost(product.id);
        if (ok) {
          productBloc.add(RefreshSingleProduct(product.id));
        }
        return ok;
      },
    );
  }

  Future<void> _openProductDetails(Product product) async {
    final changed = await context.router.push<bool>(
      StateUserProductDetailsRoute(id: product.id, results: product),
    );
    if (changed == true && context.mounted) {
      final bloc = context.read<ProductBloc>();
      final stillExists =
          bloc.state.profileProducts.any((p) => p.id == product.id);
      if (stillExists) {
        bloc.add(
            RefreshSingleProduct(product.id, preserveLocalPromotion: true));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = context.select((ThemeNotifier n) => n.isDarkMode);
    final bool isRegister = context.select((ThemeNotifier n) => n.isRegister);
    var bloc = context.select((UserBloc b) => b.state);
    bool isCurrentUser = widget.userId == bloc.user.id;
    User currentUser = !isCurrentUser ? bloc.otherUser : bloc.user;
    final id = bloc.user.id;
    debugPrint(
      '[PROFILE] build isRegister=$isRegister isCurrentUser=$isCurrentUser '
      'userId=${widget.userId} currentUserId=$id',
    );

    return BlocProvider(
      create: (_) => PromotionCubit(
        repository: getIt<PromotionRepository>(),
        preferences: getIt<SharedPreferences>(),
      )..loadMyCampaigns(),
      child: DefaultTabController(
        length: 3,
        child: _buildScaffold(context, isDark, isCurrentUser, currentUser, id),
      ),
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
                        BlocBuilder<ProductBloc, ProductState>(
                          buildWhen: (previous, current) =>
                              previous.profileProducts !=
                                  current.profileProducts ||
                              previous.profileProductsTotalCount !=
                                  current.profileProductsTotalCount,
                          builder: (context, productState) {
                            return ProfileHeader(
                              postCounts:
                                  productState.profileProductsTotalCount,
                              isCurrentUser: isCurrentUser,
                              currentUser: currentUser,
                              showInlineMenu: false,
                            );
                          },
                        ),
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
      return BlocBuilder<ProductBloc, ProductState>(
        buildWhen: (previous, current) =>
            previous.profileProducts != current.profileProducts ||
            (previous.isLoading != current.isLoading &&
                current.profileProducts.isEmpty),
        builder: (context, state) {
          if (state.isLoading && state.profileProducts.isEmpty) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: ShimmerProfileGrid(itemCount: 6),
            );
          }
          if (state.profileProducts.isEmpty) {
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
          }

          final ownerProducts = state.profileProducts;
          return BlocBuilder<PromotionCubit, PromotionState>(
            buildWhen: (previous, current) =>
                previous.myCampaigns != current.myCampaigns,
            builder: (context, promotionState) {
              final activePromotionPostIds =
                  _activeCampaignPostIds(promotionState);

              return Column(
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 18.h),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.72,
                      ),
                      itemCount: ownerProducts.length,
                      itemBuilder: (BuildContext ctx, index) {
                        final product = ownerProducts[index];
                        final promoted =
                            _isProductPromoted(product, activePromotionPostIds);
                        return _AdProductTile(
                          product: product,
                          promoted: promoted,
                          onOpen: () => _openProductDetails(product),
                          onPromote: () => _openPromotion(product),
                          onStop: () =>
                              _showStopPromotionSheet(context, product),
                        );
                      },
                    ),
                  ),
                  if (state.isLoadingProfileMore)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    ),
                ],
              );
            },
          );
        },
      );
    } else if (currentIndex == 1) {
      var bloc = context.read<UserBloc>().state;
      bool isCurrentUser = widget.userId == bloc.user.id;
      User currentUser = !isCurrentUser ? bloc.otherUser : bloc.user;
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
            AboutUsWidget(
              userId: widget.userId,
              isCurrentUser: isCurrentUser,
              user: currentUser,
            ),
          ],
        ),
      );
    } else if (currentIndex == 2) {
      return StoreComments(shopId: widget.userId);
    }
    return const SizedBox();
  }
}

class _AdProductTile extends StatelessWidget {
  final Product product;
  final bool promoted;
  final VoidCallback onOpen;
  final VoidCallback onPromote;
  final VoidCallback onStop;

  const _AdProductTile({
    required this.product,
    required this.promoted,
    required this.onOpen,
    required this.onPromote,
    required this.onStop,
  });

  static const _purple = Color(0xFF7B2FF2);

  @override
  Widget build(BuildContext context) {
    final bool isDark = context.select((ThemeNotifier n) => n.isDarkMode);
    final int views = product.views;

    final Color borderColor =
        isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE6E6E6);
    final Color cardColor = isDark ? const Color(0xFF14181F) : Colors.white;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: GestureDetector(
              onTap: onOpen,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  product.image_post.isNotEmpty
                      ? MediaTile(
                          url: product.image_post.first.image,
                          coverUrl: product.image_post.first.bestCoverUrl,
                        )
                      : const EmptyImageWidget(),
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
                          '$views',
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
                  if (promoted)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: onStop,
                        child: const VipBadgeNew(),
                      ),
                    ),
                ],
              ),
            ),
          ),
          // STORE_RELEASE_HIDDEN_START: START_PROMOTION
/*
if (!promoted) ...[
  Container(height: 1, color: borderColor),
  InkWell(
    onTap: onPromote,
    child: SizedBox(
      height: 38.h,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.campaign, size: 16, color: _purple),
          SizedBox(width: 6.w),
          const TextTranslated(
            'Запустить рекламу',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _purple,
            ),
          ),
        ],
      ),
    ),
  ),
],
*/
// STORE_RELEASE_HIDDEN_END: START_PROMOTION
        ],
      ),
    );
  }
}

class _VipPill extends StatelessWidget {
  const _VipPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFF2D55),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.workspace_premium, size: 14, color: Colors.white),
          SizedBox(width: 4),
          Text(
            'VIP',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
