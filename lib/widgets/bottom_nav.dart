import 'dart:io';

// TODO: Restore when cart is re-enabled
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:optombai/core/route_observer.dart';
import 'package:optombai/pages/cart/cart_screen.dart';
import 'package:optombai/bloc/auth_bloc/auth_cubit.dart';
import 'package:optombai/bloc/block_bloc/block_bloc.dart';
import 'package:optombai/bloc/cart_bloc/cart_bloc.dart';
import 'package:optombai/bloc/chat_bloc/chat_bloc.dart';
import 'package:optombai/bloc/pmt_bloc/pmt_bloc.dart';
import 'package:optombai/bloc/pmt_bloc/pmt_event.dart';
import 'package:optombai/bloc/reel_bloc/reel_bloc.dart';
import 'package:optombai/bloc/subscription_bloc/subscription_bloc.dart';
import 'package:optombai/bloc/subscription_bloc/subscription_event.dart';
import 'package:optombai/core/appColors.dart';
import 'package:optombai/core/import_links.dart';
import 'package:optombai/configs/constrants.dart';
import 'package:optombai/core/di/injection.dart';
import 'package:optombai/services/iap_service.dart';
import 'package:optombai/features/live_stream/presentation/logic/stream_cubit.dart';
import 'package:optombai/features/live_stream/presentation/pages/stream_page.dart';
import 'package:optombai/l10n/tr.dart';
import 'package:auto_route/auto_route.dart';
import 'package:optombai/app/router/app_router.dart';
import 'package:optombai/tour/controller/tour_controller.dart';
import 'package:optombai/tour/prefs/tour_prefs.dart';
import 'package:optombai/tour/tour_actions.dart';
import 'package:optombai/tour/tour_keys.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:optombai/core/debug/debug_overlay_controller.dart';
import 'package:optombai/features/notifications/presentation/logic/notifications_cubit.dart';
import 'package:optombai/pages/main_screen/main_screen.dart';
import 'package:optombai/widgets/app_bottom_bar.dart';
import 'package:optombai/widgets/auth/inline_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

@RoutePage(name: 'BottomNavRoute')
class BottomNav extends StatefulWidget {
  final int? currentIndexOverride;
  final bool passive;
  final bool forceDarkTheme;

  final bool startTour;

  final int initialIndex;

  const BottomNav({
    super.key,
    this.currentIndexOverride,
    this.passive = false,
    this.forceDarkTheme = false,
    this.startTour = false,
    this.initialIndex = 0,
  });

  @override
  State<BottomNav> createState() => _BottomNavState();
  static BottomNavController? of(BuildContext context) =>
      context.findAncestorStateOfType<_BottomNavState>();
}

abstract class BottomNavController {
  void setTab(int index);
  Future<void> openAddProduct();
  void goProfileScreen();

  GlobalKey get navAStreams;
  GlobalKey get navAAdd;
  GlobalKey get navAProfile;
}

class _BottomNavState extends State<BottomNav>
    with WidgetsBindingObserver, RouteAware
    implements BottomNavController {
  // Holds the single active non-passive BottomNav so passive screens can
  // call setTab/openAddProduct after popping back to it.
  static _BottomNavState? _current;

  static const Set<int> _messagesOverrides = {-10, -11};

  bool? _prevShowCart;
  bool _tourTriggered = false;

  late User user = User();

  ProductPageEvent pageEvent = ProductPageEvent();

  int currentIndex = 0;

  SharedPreferences get _prefs => getIt<SharedPreferences>();

  bool _overlayRouteOpen = false;
  PageRoute<dynamic>? _subscribedRoute;
  TourController? _tourController;

  StreamSubscription<BlockState>? _blockSub;
  String _lastJustBlockedId = '';
  String _lastJustUnblockedId = '';
  Object? _lastLifecycleState;

  int? _lastShowcaseStartedStep;
  int _retryToken = 0;
  @override
  final GlobalKey navAStreams = TourKeys.navStreams;
  @override
  final GlobalKey navAAdd = TourKeys.navAdd;
  @override
  final GlobalKey navAProfile = TourKeys.navProfile;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final tc = context.read<TourController>();
    if (_tourController != tc) {
      _tourController?.removeListener(_onTourChanged);
      _tourController = tc;
      _tourController!.addListener(_onTourChanged);
    }

    final ModalRoute<dynamic>? route = ModalRoute.of(context);
    if (route is PageRoute<dynamic> && route != _subscribedRoute) {
      appRouteObserver.unsubscribe(this);
      appRouteObserver.subscribe(this, route);
      _subscribedRoute = route;
    }
  }

  @override
  void didPushNext() {
    if (mounted && !_overlayRouteOpen) {
      setState(() => _overlayRouteOpen = true);
    }
  }

  @override
  void didPopNext() {
    if (mounted && _overlayRouteOpen) {
      setState(() => _overlayRouteOpen = false);
    }
  }

  @override
  void dispose() {
    if (!widget.passive && _current == this) _current = null;
    appRouteObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    _tourController?.removeListener(_onTourChanged);
    _blockSub?.cancel();
    super.dispose();
  }

  void _loadGlobalData() {
    final bannerState = context.read<BannerBloc>().state;
    if (bannerState is! BannerSuccess && bannerState is! BannerLoading) {
      debugPrint('[PRELOAD] BottomNav: dispatching BannerAllEvent');
      context.read<BannerBloc>().add(const BannerAllEvent());
    }
  }

  void _loadAuthenticatedData() {
    final hasToken = context.read<AuthCubit>().getToken().isNotEmpty;
    if (!hasToken) return;

    final userId = context.read<UserBloc>().state.user.id;
    debugPrint('[PRELOAD] BottomNav: loading authenticated user data');

    context.read<FavoriteBloc>().add(FavoriteAllEvent());
    context.read<CartBloc>().add(const CartLoadEvent());
    _refreshUnreadBadges();
    context.read<BlockBloc>().add(const LoadBlocksEvent(forceRefresh: true));

    _setupRestoredPurchaseHandler();

    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      context.read<CurrencyBloc>().add(CurrencyAllEvent());
      context.read<SubscriptionBloc>().add(FetchSubscriptionEvent());
      context.read<PmtBloc>().add(const PmtHistoryEvent());
      if (userId.isNotEmpty) {
        context.read<DocumentBloc>().add(GetAllDocumentImage(userId));
      }
    });
  }

  void _refreshUnreadBadges() {
    if (widget.passive) return;
    if (context.read<AuthCubit>().getToken().isEmpty) return;

    context.read<ChatBloc>().add(FetchChatsEvent());
    context.read<NotificationsCubit>().refreshUnreadCount();
  }

  void _watchBlockEvents() {
    if (widget.passive) return;
    _blockSub = context.read<BlockBloc>().stream.listen((state) {
      final justBlocked = state.justBlockedUserId;
      if (justBlocked.isEmpty) {
        _lastJustBlockedId = '';
      } else if (justBlocked != _lastJustBlockedId) {
        _lastJustBlockedId = justBlocked;
        _refreshFeedAfterBlockChange();
      }

      final justUnblocked = state.justUnblockedUserId;
      if (justUnblocked.isEmpty) {
        _lastJustUnblockedId = '';
      } else if (justUnblocked != _lastJustUnblockedId) {
        _lastJustUnblockedId = justUnblocked;
        _refreshFeedAfterBlockChange();
      }
    });
  }

  void _refreshFeedAfterBlockChange() {
    if (!mounted) return;
    context.read<ProductBloc>().add(RefreshCurrentFilterEvent());
    context.read<ReelBloc>().add(FetchReelsEvent(forceRefresh: true));
  }

  void _setupRestoredPurchaseHandler() {
    final iapService = IAPService();
    final pmtBloc = context.read<PmtBloc>();
    final authCubit = context.read<AuthCubit>();
    final userBloc = context.read<UserBloc>();

    iapService.setRestoredPurchaseHandler((PurchaseDetails purchase) async {
      debugPrint(
        'BottomNav: Processing restored purchase: ${purchase.productID}',
      );

      final token = authCubit.getToken();
      if (token.isEmpty) {
        await iapService.finishPurchase(purchase);
        return;
      }

      final validation = await iapService.validatePurchase(
        purchase: purchase,
        token: token,
      );

      await iapService.finishPurchase(purchase);

      if (!validation.isValid) return;

      final premiumId =
          purchase.productID == IAPService.weeklySubscriptionId ? '1' : '2';
      final pmtMethod = Platform.isIOS ? 'apple_pay' : 'google_pay';
      pmtBloc.add(
        PmtStatusUpdateEvent(
          pmtId: purchase.purchaseID ?? '',
          amount: '0',
          pmtMethod: pmtMethod,
          premiumId: premiumId,
        ),
      );

      userBloc.add(UserOwnerEvent());
      debugPrint('BottomNav: Restored purchase processed successfully');
    });
  }

  void _onTourChanged() {
    final tour = _tourController;
    if (!mounted || tour == null || !tour.isRunning) return;

    final stepIndex = tour.stepIndex;
    final step = tour.steps[stepIndex];

    if (step.showcaseKeys.isEmpty) return;

    for (final k in step.showcaseKeys) {
      debugPrint('[TOUR][BN] key=$k ctx=${k.currentContext}');
    }

    if (_lastShowcaseStartedStep == stepIndex) return;

    final int token = ++_retryToken;
    Future<bool> isKeyReady(GlobalKey k) async {
      final ctx = k.currentContext;
      if (ctx == null) return false;
      final ro = ctx.findRenderObject();
      return ro is RenderBox && ro.attached && ro.hasSize;
    }

    void tryStart() async {
      if (!mounted || _tourController == null || !_tourController!.isRunning) {
        return;
      }
      if (_tourController!.stepIndex != stepIndex) return;
      if (token != _retryToken) return;

      await WidgetsBinding.instance.endOfFrame;
      await WidgetsBinding.instance.endOfFrame;

      final ready = await Future.wait(step.showcaseKeys.map(isKeyReady))
          .then((list) => list.every((e) => e));

      debugPrint('[TOUR][BN] step=$stepIndex ready=$ready');

      if (!ready) {
        WidgetsBinding.instance.addPostFrameCallback((_) => tryStart());
        return;
      }

      _lastShowcaseStartedStep = stepIndex;
      ShowcaseView.get().startShowCase(step.showcaseKeys);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => tryStart());
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    if (!widget.passive) _current = this;

    if (widget.currentIndexOverride != null) {
      currentIndex = widget.currentIndexOverride!;
    } else {
      currentIndex = widget.initialIndex;
    }
    if (currentIndex >= 0) {
      unawaited(_prefs.setInt(LAST_BOTTOM_TAB_KEY, currentIndex));
    }

    debugPrint(
      '[PRELOAD] BottomNav.initState passive=${widget.passive} '
      'override=${widget.currentIndexOverride} initialIndex=${widget.initialIndex} '
      'currentIndex=$currentIndex',
    );

    _loadGlobalData();
    _loadAuthenticatedData();
    _watchBlockEvents();

    context.read<StreamCubit>().getStreams();

    if (widget.startTour) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted || _tourTriggered) return;
        _tourTriggered = true;

        final done = await TourPrefs.isTourDone();
        if (!mounted || done) return;

        await TourPrefs.markTourDone();

        await Future.delayed(const Duration(milliseconds: 400));
        if (!mounted) return;

        context.read<TourController>().start(context);
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        (_lastLifecycleState == null ||
            _lastLifecycleState == AppLifecycleState.paused ||
            _lastLifecycleState == AppLifecycleState.hidden ||
            _lastLifecycleState == AppLifecycleState.inactive)) {
      _refreshUnreadBadges();
      unawaited(context.read<StreamCubit>().endLeftoverBroadcast());
    }
    _lastLifecycleState = state;
  }

  @override
  Future<void> openAddProduct() async {
    final hasToken = context.read<ThemeNotifier>().isRegister;
    debugPrint(
      '[BOTTOM_NAV] openAddProduct currentIndex=$currentIndex hasToken=$hasToken',
    );

    if (!hasToken) {
      debugPrint('[BOTTOM_NAV] openAddProduct -> SignInRoute');
      await context.router.push(const SignInRoute());
      return;
    }

    if (!mounted) return;
    setState(() => currentIndex = 3);
  }

  @override
  void setTab(int index) {
    if (!mounted) return;
    debugPrint(
      '[BOTTOM_NAV] setTab from=$currentIndex to=$index passive=${widget.passive} '
      'routeStack=${context.router.stack.map((r) => r.routeData.name).toList()}',
    );
    setState(() => currentIndex = index);
    if (index >= 0) {
      unawaited(_prefs.setInt(LAST_BOTTOM_TAB_KEY, index));
    }
  }

  @override
  void goProfileScreen() {
    debugPrint(
      '[BOTTOM_NAV] goProfileScreen from=$currentIndex passive=${widget.passive} '
      'routeStack=${context.router.stack.map((r) => r.routeData.name).toList()}',
    );
    setState(() {
      currentIndex = 5;
    });
  }

  @Deprecated('Use openAddProduct() instead')
  void goAddProductScreen() {
    openAddProduct();
  }

  void goProfileScreen2(bool showCart) {
    debugPrint(
      '[BOTTOM_NAV] goProfileScreen2 showCart=$showCart from=$currentIndex',
    );
    setState(() {
      currentIndex = showCart ? 5 : 4;
    });
  }

  @override
  Widget build(BuildContext context) {
    const showCart = false;

    _prevShowCart ??= showCart;

    if (_prevShowCart != showCart) {
      if (_prevShowCart == true && showCart == false) {
        if (currentIndex == 5) currentIndex = 4;
      }

      if (_prevShowCart == false && showCart == true) {
        if (currentIndex == 4) currentIndex = 5;
      }

      _prevShowCart = showCart;
    }

    final userId = context.select((UserBloc b) => b.state.user.id);
    final username = context.select((UserBloc b) => b.state.user.username);

    // Reactive to registration status (not a one-off read) so a successful
    // inline sign-in (see InlineSignIn) swaps the tab's content in place —
    // without it, this tab silently kept showing the sign-in form after
    // login until something else forced a rebuild.
    final bool hasToken = context.select((ThemeNotifier n) => n.isRegister);
    bool stateSwitch = widget.forceDarkTheme || currentIndex == 2
        ? true
        : context.select((ThemeNotifier n) => n.isDarkMode);

    debugPrint(
      '[BOTTOM_NAV] build currentIndex=$currentIndex hasToken=$hasToken '
      'forceDark=${widget.forceDarkTheme} passive=${widget.passive}',
    );
    debugPrint(
      '[BOTTOM_NAV] routeStack=${context.router.stack.map((r) => r.routeData.name).toList()}',
    );

    List<Widget> screens = [
      const HomePage(),
      const CategoryScreen(showBottomNav: false),
      StreamPage(
        userId: userId,
        isActive: currentIndex == 2 && !_overlayRouteOpen,
        keepLivePlayerAlive: currentIndex == 2 && _overlayRouteOpen,
      ),
      hasToken
          ? const AddProductScreen()
          : Scaffold(
              appBar: AppBar(title: const Text('Добавить товар')),
              body: const InlineSignIn(),
            ),
      // ignore: dead_code
      if (showCart) const CartScreen(),
      hasToken
          ? ProfileScreen(userId: userId, username: username)
          : Scaffold(
              appBar: AppBar(title: const Text('Профиль')),
              body: const InlineSignIn(),
            ),
    ];

    // ignore: dead_code
    const profileIndex = showCart ? 5 : 4;

    if (currentIndex >= screens.length) {
      debugPrint(
        '[BOTTOM_NAV] clamp currentIndex=$currentIndex -> $profileIndex',
      );
      currentIndex = profileIndex;
    }
    if (!showCart && currentIndex == 4) {
      debugPrint(
          '[BOTTOM_NAV] normalize currentIndex=4 -> profileIndex=$profileIndex');
      currentIndex = profileIndex;
    }

    if (currentIndex < 0) {
      final int? override = widget.currentIndexOverride;
      final bool isMessagesScreen = _messagesOverrides.contains(override);
      final int passiveActiveIndex =
          isMessagesScreen ? AppBottomBar.messagesIndex : -1;

      return AppBottomBar(
        currentIndex: passiveActiveIndex,
        profileIndex: profileIndex,
        isDark: stateSwitch,
        onTabSelected: (index) {
          if (override == -10) {
            // Pop the ChatList overlay and pass the target tab index back to
            // the main BottomNav so it can switch to the correct tab.
            context.router.pop(index);
            return;
          }
          // Any other deep screen: pop all routes back to BottomNav and
          // switch to the requested tab. If this passive bar was reached
          // through a full stack replace (e.g. SignInRoute after logout),
          // no BottomNavRoute exists to pop back to — push a fresh one
          // landing directly on the requested tab instead of no-op'ing.
          final router = context.router;
          final hasBottomNavRoute =
              router.stack.any((r) => r.routeData.name == BottomNavRoute.name);
          if (hasBottomNavRoute) {
            router.popUntilRouteWithName(BottomNavRoute.name);
            _BottomNavState._current?.setTab(index);
          } else {
            router.replaceAll([BottomNavRoute(initialIndex: index)]);
          }
        },
        onAddProduct: () {
          if (override == -10) {
            context.router.pop(3);
            return;
          }
          final router = context.router;
          final hasBottomNavRoute =
              router.stack.any((r) => r.routeData.name == BottomNavRoute.name);
          if (hasBottomNavRoute) {
            router.popUntilRouteWithName(BottomNavRoute.name);
            _BottomNavState._current?.openAddProduct();
          } else {
            router.replaceAll([BottomNavRoute(initialIndex: 3)]);
          }
        },
        onMessages: () {
          if (isMessagesScreen) return;

          if (!context.read<ThemeNotifier>().isRegister) {
            debugPrint('[AUTH] bottom nav activity gate -> sign in');
            context.router.push(const SignInRoute());
            return;
          }
          // Push on top of the current route — preserves the back stack so
          // the user can return to whatever screen they were on.
          context.router.push(const NotificationsRoute());
        },
      );
    }

    return Scaffold(
      backgroundColor: stateSwitch ? Colors.black : AppColors.lightBackground,
      body: IndexedStack(
        index: currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Stack(
        children: [
          AppBottomBar(
            currentIndex: currentIndex,
            profileIndex: profileIndex,
            isDark: stateSwitch,
            onTabSelected: (i) {
              DebugOverlayController.instance.registerTap();
              debugPrint(
                '[BOTTOM_NAV] bottomBar tap from=$currentIndex to=$i hasToken=$hasToken',
              );
              setState(() => currentIndex = i);
            },
            onAddProduct: () {
              DebugOverlayController.instance.registerTap();
              openAddProduct();
            },
            onMessages: () async {
              DebugOverlayController.instance.registerTap();

              if (!hasToken) {
                debugPrint('[AUTH] bottom nav activity gate -> sign in');
                await context.router.push(const SignInRoute());
                return;
              }
              setState(() => _overlayRouteOpen = true);
              await context.router.push(const NotificationsRoute());
              if (mounted) {
                setState(() => _overlayRouteOpen = false);
              }
            },
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.paddingOf(context).bottom,
                ),
                child: Row(
                  children: [
                    const Expanded(child: SizedBox()),
                    Expanded(
                      child: Showcase.withWidget(
                        key: navAStreams,
                        container: TourTooltipWidget(
                          text: tr(context, 'tour_screen6'),
                          totalInThisScreen: 1,
                        ),
                        child: const SizedBox.expand(),
                      ),
                    ),
                    Expanded(
                      child: Showcase.withWidget(
                        key: navAAdd,
                        container: TourTooltipWidget(
                          text: tr(context, 'tour_screen7'),
                          totalInThisScreen: 1,
                        ),
                        child: const SizedBox.expand(),
                      ),
                    ),
                    const Expanded(child: SizedBox()),
                    Expanded(
                      child: Showcase.withWidget(
                        key: navAProfile,
                        container: TourTooltipWidget(
                          text: tr(context, 'tour_screen4'),
                          totalInThisScreen: 1,
                        ),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
