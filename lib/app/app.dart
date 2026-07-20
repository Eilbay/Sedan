import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:optombai/bloc/pit_bloc/pit_bloc.dart';
import 'package:optombai/bloc/admin_request_bloc/admin_request_bloc.dart';
import 'package:optombai/bloc/auth_bloc/auth_cubit.dart';
import 'package:optombai/bloc/banner_bloc/banner_bloc.dart';
import 'package:optombai/bloc/block_bloc/block_bloc.dart';
import 'package:optombai/bloc/button_visible_bloc/button_visible_bloc.dart';
import 'package:optombai/bloc/feature_flags_cubit/feature_flags_cubit.dart';
import 'package:optombai/bloc/chat_bloc/chat_bloc.dart';
import 'package:optombai/bloc/comment_bloc/comment_cubit.dart';
import 'package:optombai/bloc/currency_bloc/currency_bloc.dart';
import 'package:optombai/bloc/document_bloc/document_bloc.dart';
import 'package:optombai/bloc/favorite_bloc/favorite_bloc.dart';
import 'package:optombai/bloc/image_bloc/image_bloc.dart';
import 'package:optombai/bloc/language_bloc/language_bloc.dart';
import 'package:optombai/bloc/message_bloc/message_bloc.dart';
import 'package:optombai/bloc/market_bloc/supplier_market_bloc.dart';

import 'package:optombai/bloc/pmt_bloc/pmt_bloc.dart';
import 'package:optombai/bloc/product_bloc/product_bloc.dart';
import 'package:optombai/bloc/upload_cubit/upload_cubit.dart';
import 'package:optombai/core/route_observer.dart';
import 'package:optombai/core/update/app_update_checker.dart';
import 'package:optombai/core/update/update_cubit.dart';
import 'package:optombai/widgets/update/update_gate_overlay.dart';
import 'package:optombai/services/media/media_processor.dart';
import 'package:optombai/bloc/question_bloc/question_bloc.dart';
import 'package:optombai/bloc/reel_bloc/reel_bloc.dart';
import 'package:optombai/bloc/report_bloc/report_cubit.dart';
import 'package:optombai/core/deep_link/deep_link_parser.dart';
import 'package:optombai/data/api_client.dart';
import 'package:optombai/data/models/reel/reel_model.dart';
import 'package:optombai/features/live_stream/data/data_sources/stream_remote_data_source.dart';
import 'package:optombai/features/live_stream/data/repositories/live_stream_repository_impl.dart';
import 'package:optombai/features/live_stream/presentation/logic/stream_cubit.dart';
import 'package:optombai/bloc/review_bloc/review_bloc.dart';
import 'package:optombai/bloc/store_review_bloc/store_review_bloc.dart';
import 'package:optombai/bloc/subscription_bloc/subscription_bloc.dart';
import 'package:optombai/bloc/support_bloc/support_bloc.dart';
import 'package:optombai/bloc/user_bloc/user_bloc.dart';
import 'package:optombai/features/referral/domain/repository/referral_repository.dart';
import 'package:optombai/features/referral/presentation/logic/referral_cubit.dart';
// Cart BLoC imports
import 'package:optombai/bloc/cart_bloc/cart_bloc.dart';
import 'package:optombai/bloc/order_bloc/order_bloc.dart';
import 'package:optombai/app/router/app_router.dart';
import 'package:optombai/services/chat_auth_guard.dart';
import 'package:optombai/widgets/debug/debug_floating_bubble.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:optombai/tour/controller/tour_controller.dart';
import 'package:optombai/tour/model/tour_step.dart';
import 'package:optombai/tour/tour_keys.dart';
import 'package:optombai/widgets/bottom_nav.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showcaseview/showcaseview.dart';

import 'package:optombai/bloc/category_bloc/category_bloc.dart';
import 'package:optombai/bloc/country_bloc/country_bloc.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:optombai/core/di/injection.dart';
import 'package:optombai/services/chat/chat_resolver.dart';
import 'package:optombai/core/theme_notifier.dart';
import 'package:optombai/data/repositories/i_pit_repository.dart';
import 'package:optombai/data/repositories/i_admin_request_repository.dart';
import 'package:optombai/data/repositories/i_auth_repository.dart';
import 'package:optombai/data/repositories/i_block_repository.dart';
import 'package:optombai/data/repositories/i_category_repository.dart';
import 'package:optombai/data/repositories/i_chat_repository.dart';
import 'package:optombai/data/repositories/i_comment_repository.dart';
import 'package:optombai/data/repositories/i_favorite_repository.dart';
import 'package:optombai/data/repositories/i_image_repository.dart';
import 'package:optombai/data/repositories/i_market_repository.dart';
import 'package:optombai/data/repositories/i_pmt_repository.dart';
import 'package:optombai/data/repositories/i_product_repository.dart';
import 'package:optombai/data/repositories/i_reel_repository.dart';
import 'package:optombai/data/repositories/i_report_repository.dart';
import 'package:optombai/data/repositories/i_review_repository.dart';
import 'package:optombai/data/repositories/i_settings_repository.dart';
import 'package:optombai/data/repositories/i_store_review_repository.dart';
import 'package:optombai/data/repositories/i_subscription_repository.dart';
import 'package:optombai/data/repositories/i_support_repository.dart';
import 'package:optombai/data/repositories/i_user_repository.dart';
import 'package:optombai/firebase/service.dart';
import 'package:optombai/data/models/chat/chat_model.dart';
import 'package:optombai/features/notifications/data/data_sources/notifications_remote_data_source.dart';
import 'package:optombai/features/notifications/data/models/notification_item.dart';
import 'package:optombai/features/notifications/presentation/logic/notifications_cubit.dart';
import 'package:optombai/services/cart_storage_service.dart';
import 'package:optombai/services/push/push_notification_service.dart';
import 'package:optombai/services/push/push_payload.dart';
import 'package:optombai/services/reel_metadata_cache.dart';

class MyApp extends StatefulWidget {
  final SharedPreferences preferences;

  const MyApp({super.key, required this.preferences});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _appRouter = AppRouter();
  StreamSubscription? _sub;
  late ProductBloc productBloc;
  late final TourController _tourController = TourController([
    const TourStep(tabIndex: 0, showcaseKeys: []),
    const TourStep(tabIndex: 0, showcaseKeys: []),
    const TourStep(tabIndex: 0, showcaseKeys: []),
    TourStep(tabIndex: 0, showcaseKeys: [TourKeys.navStreams]),
    TourStep(tabIndex: 0, showcaseKeys: [TourKeys.navAdd]),
    TourStep(
      tabIndex: 0,
      showcaseKeys: const [],
      onEnter: (ctx) async {
        final bn = BottomNav.of(ctx);
        if (bn == null) return;
        debugPrint('[TOUR] navAAdd ctx=${bn.navAAdd.currentContext}');
        await WidgetsBinding.instance.endOfFrame;
        await WidgetsBinding.instance.endOfFrame;
        ShowcaseView.get().startShowCase([bn.navAStreams]);
      },
    ),
    TourStep(
      tabIndex: 0,
      showcaseKeys: const [],
      onEnter: (ctx) async {
        final bn = BottomNav.of(ctx);
        if (bn == null) return;
        await WidgetsBinding.instance.endOfFrame;
        await WidgetsBinding.instance.endOfFrame;
        ShowcaseView.get().startShowCase([bn.navAAdd]);
      },
    ),
    TourStep(
      tabIndex: 0,
      showcaseKeys: const [],
      onEnter: (ctx) async {
        final bn = BottomNav.of(ctx);
        if (bn == null) return;
        await WidgetsBinding.instance.endOfFrame;
        await WidgetsBinding.instance.endOfFrame;
        ShowcaseView.get().startShowCase([bn.navAProfile]);
      },
    ),
  ]);

  final AppLinks _appLinks = AppLinks();

  static const String _kReferralCodeKey = 'referral_code';

  bool _showcaseRegistered = false;
  bool _wasRegistered = false;

  @override
  void initState() {
    super.initState();
    productBloc = ProductBloc(
      repository: getIt<IProductRepository>(),
      preferences: getIt<SharedPreferences>(),
    );

    _registerShowcase();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      debugPrint('[INIT] postFrame: starting');
      await _handleInitialAppLink();
      debugPrint('[INIT] postFrame: initial deep link done');
      _handleDeepLinks();
      debugPrint('[INIT] postFrame: deep links listener attached');
      await _initPushNotifications();
      debugPrint('[INIT] postFrame: push init returned');
    });
  }

  Future<void> _initPushNotifications() async {
    debugPrint('[PUSH] _initPushNotifications: entry');
    final push = getIt<PushNotificationService>();
    debugPrint(
        '[PUSH] _initPushNotifications: got service, calling initialize');
    try {
      await push.initialize(onTap: _navigateFromPush);
      debugPrint('[PUSH] _initPushNotifications: initialize done');
    } catch (e) {
      debugPrint('[PUSH] init failed: $e');
      return;
    }

    if (!mounted) return;
    final themeNotifier = context.read<ThemeNotifier>();
    _wasRegistered = themeNotifier.isRegister;
    debugPrint('[PUSH] _initPushNotifications: isRegister=$_wasRegistered');
    if (_wasRegistered) {
      await push.registerCurrentDevice();
    }
    themeNotifier.addListener(_onRegistrationStateChanged);
  }

  void _onRegistrationStateChanged() {
    if (!mounted) return;
    final isRegistered = context.read<ThemeNotifier>().isRegister;
    if (isRegistered == _wasRegistered) return;

    final push = getIt<PushNotificationService>();
    debugPrint(
      '[PUSH] registration state changed: $_wasRegistered -> $isRegistered',
    );
    if (isRegistered) {
      push.registerCurrentDevice();
    } else {
      push.unregisterCurrentDevice();
    }
    _wasRegistered = isRegistered;
  }

  void _navigateFromPush(PushPayload payload) {
    switch (payload.type) {
      case NotificationType.message:
        _openChatFromPush(payload.chatId);
        break;
      case NotificationType.like:
      case NotificationType.comment:
      case NotificationType.unknown:
        _appRouter.push(const NotificationsRoute());
        break;
    }
  }

  Future<void> _openChatFromPush(String? chatId) async {
    if (chatId == null || chatId.isEmpty) {
      _appRouter.push(const NotificationsRoute());
      return;
    }

    final ctx = _scaffoldContext();
    final chatBloc = ctx?.read<ChatBloc>();
    final authGuard = getIt<ChatAuthGuard>();
    Chat? chat;
    try {
      final token = await authGuard.requireToken();
      chat = await getIt<ChatResolver>().resolveById(
        chatId: chatId,
        token: token,
        cached: chatBloc?.state.chats ?? const <Chat>[],
      );
    } catch (_) {}
    if (!mounted) return;

    // Build a back stack: chat list under the conversation so "back" goes
    // conversation → chat list → home.
    _appRouter.push(const ChatListRoute());
    if (chat != null) {
      _appRouter.push(ChatConversationRoute(chat: chat));
    }
  }

  BuildContext? _scaffoldContext() {
    final navState = _appRouter.navigatorKey.currentState;
    return navState?.context;
  }

  void _registerShowcase() {
    if (_showcaseRegistered) return;
    _showcaseRegistered = true;

    ShowcaseView.register(
      blurValue: 0,
      onDismiss: (key) {
        debugPrint('[SHOWCASE] dismissed at $key');
        _tourController.next();
      },
      onComplete: (index, key) {
        debugPrint('[SHOWCASE] complete index=$index key=$key');
        _tourController.next();
      },
    );
  }

  Future<void> _handleInitialAppLink() async {
    try {
      final uri = await _appLinks.getInitialLink();
      if (uri == null) return;

      await _processDeepLink(uri);
    } catch (_) {}
  }

  bool _isReferralRegisterLink(Uri uri) =>
      DeepLinkParser.isReferralRegisterLink(uri);

  Future<void> _trySaveReferralCode(Uri uri) async {
    final code = DeepLinkParser.extractReferralCode(uri);
    if (code != null) {
      await getIt<SharedPreferences>().setString(_kReferralCodeKey, code);
      debugPrint('Referral saved ✅ $code');
    }
  }

  void _handleDeepLinks() {
    try {
      _sub = _appLinks.uriLinkStream.listen((Uri? uri) async {
        if (uri == null) return;

        await _processDeepLink(uri);
      }, onError: (err) {
        debugPrint('Error processing deep link: $err');
      });
    } catch (e) {
      debugPrint('Error initializing deep link: $e');
    }
  }

  Future<void> _processDeepLink(Uri uri) async {
    await _trySaveReferralCode(uri);

    if (_isReferralRegisterLink(uri)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _appRouter.push(const SignUpRoute());
      });
      return;
    }

    final productId = _extractProductId(uri);
    if (productId != null) {
      await _openProductDeepLink(productId, uri);
      return;
    }

    final reelId = _extractReelId(uri);
    if (reelId != null) {
      await _openReelDeepLink(reelId, uri);
    }
  }

  String? _extractProductId(Uri uri) => DeepLinkParser.extractProductId(uri);

  String? _extractReelId(Uri uri) => DeepLinkParser.extractReelId(uri);

  Future<void> _openProductDeepLink(String productId, Uri uri) async {
    debugPrint('Product deep link received: $uri');
    productBloc.add(GetProductInfo(productId));

    StreamSubscription<ProductState>? subscription;
    subscription = productBloc.stream.listen((state) async {
      if (state.isLoading) return;

      if (state.isSuccess) {
        if (mounted) {
          _appRouter.push(ProductDetailsRoute(results: state.product));
        }
        await subscription?.cancel();
        return;
      }

      if (state.errors.isNotEmpty) {
        _showDeepLinkError('Не удалось открыть товар');
        await subscription?.cancel();
      }
    });
  }

  Future<void> _openReelDeepLink(String reelId, Uri uri) async {
    debugPrint('Reel deep link received: $uri');

    try {
      final resolved = await _resolveReelDeepLink(reelId);
      if (!mounted) return;

      if (resolved == null) {
        _showDeepLinkError('Видео не найдено');
        return;
      }

      _appRouter.push(
        ReelsViewerRoute(
          reels: resolved.reels,
          initialIndex: resolved.initialIndex,
        ),
      );
    } catch (e) {
      debugPrint('Failed to open reel deep link: $e');
      _showDeepLinkError('Не удалось открыть видео');
    }
  }

  Future<_ResolvedReelLink?> _resolveReelDeepLink(String reelId) async {
    final reelBloc = context.read<ReelBloc>();
    final cachedReels = reelBloc.state.reels;
    final cachedIndex = _findReelIndex(cachedReels, reelId);
    if (cachedIndex != -1) {
      return _ResolvedReelLink(
        reels: cachedReels,
        initialIndex: cachedIndex,
      );
    }

    final repository = getIt<IReelRepository>();
    final token = reelBloc.getToken();
    final collected = <ReelModel>[];
    final seenIds = <String>{};

    // The reels-feed is cyclic — `next` is NEVER null (it loops back to the
    // start). So we can't stop on `next == null`; instead we stop once a page
    // brings no new reels (we've walked the whole feed once) or after a safety
    // cap. Without this, a deep link to a missing/foreign reel id would page
    // forever and hang the app.
    const maxPages = 25;
    var page = await repository.fetchReels(token);
    var foundIndex = -1;
    var pages = 0;
    while (true) {
      final beforeCount = seenIds.length;
      for (final reel in page.results) {
        if (seenIds.add(reel.id)) collected.add(reel);
      }
      foundIndex = _findReelIndex(collected, reelId);
      if (foundIndex != -1) break;

      pages++;
      final broughtNew = seenIds.length > beforeCount;
      if (!broughtNew || pages >= maxPages || page.next == null) break;

      page = await repository.fetchMoreReels(page.next!, token);
    }

    if (foundIndex == -1) return null;

    return _ResolvedReelLink(
      reels: List<ReelModel>.unmodifiable(collected),
      initialIndex: foundIndex,
    );
  }

  int _findReelIndex(List<ReelModel> reels, String reelId) {
    for (var i = 0; i < reels.length; i++) {
      final reel = reels[i];
      if (reel.id == reelId || reel.slug == reelId) {
        return i;
      }
    }
    return -1;
  }

  void _showDeepLinkError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    unawaited(productBloc.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
            create: (_) => AuthCubit(
                  repository: getIt<IAuthRepository>(),
                  preferences: getIt<SharedPreferences>(),
                )),
        BlocProvider(
            create: (_) => UserBloc(
                  repository: getIt<IUserRepository>(),
                  preferences: getIt<SharedPreferences>(),
                )),
        BlocProvider(
            create: (_) => CategoryBloc(
                  repository: getIt<ICategoryRepository>(),
                )),
        BlocProvider.value(value: productBloc),
        BlocProvider(
            create: (_) => UploadCubit(
                  repository: getIt<IProductRepository>(),
                  preferences: getIt<SharedPreferences>(),
                  mediaProcessor: MediaProcessor(),
                )),
        BlocProvider(
            create: (_) => FavoriteBloc(
                  repository: getIt<IFavoriteRepository>(),
                  preferences: getIt<SharedPreferences>(),
                )),
        BlocProvider(
            create: (_) => ReviewBloc(
                  repository: getIt<IReviewRepository>(),
                  preferences: getIt<SharedPreferences>(),
                )),
        BlocProvider(
            create: (_) => StoreReviewBloc(
                  repository: getIt<IStoreReviewRepository>(),
                  preferences: getIt<SharedPreferences>(),
                )),
        BlocProvider(
            create: (_) => SubscriptionBloc(
                  repository: getIt<ISubscriptionRepository>(),
                  preferences: getIt<SharedPreferences>(),
                )),
        BlocProvider(
          create: (_) => CurrencyBloc(
            repository: getIt<ISettingsRepository>(),
            preferences: getIt<SharedPreferences>(),
          )..add(CurrencyAllEvent()),
        ),
        BlocProvider(
            create: (_) => BannerBloc(
                  repository: getIt<ISettingsRepository>(),
                  preferences: getIt<SharedPreferences>(),
                )),
        BlocProvider(
            create: (_) => QuestionBloc(
                  repository: getIt<ISettingsRepository>(),
                  preferences: getIt<SharedPreferences>(),
                )),
        BlocProvider(
            create: (_) => CountryBloc(
                  repository: getIt<ISettingsRepository>(),
                  preferences: getIt<SharedPreferences>(),
                )),
        BlocProvider(
            create: (_) => ImageBloc(
                  repository: getIt<IImageRepository>(),
                  preferences: getIt<SharedPreferences>(),
                )),
        BlocProvider(
            create: (_) => DocumentBloc(
                  repository: getIt<IImageRepository>(),
                  preferences: getIt<SharedPreferences>(),
                )),
        BlocProvider(
            create: (_) => PmtBloc(
                  repository: getIt<IPmtRepository>(),
                  preferences: getIt<SharedPreferences>(),
                )),
        BlocProvider(
            create: (_) => AdminRequestBloc(
                  repository: getIt<IAdminRequestRepository>(),
                  preferences: getIt<SharedPreferences>(),
                )),
        BlocProvider(create: (_) => LanguageBloc(getIt<SharedPreferences>())),
        BlocProvider(
          create: (context) => ButtonVisibleBloc(
            FirebaseService(),
            context.read<UserBloc>(),
          )..add(LoadButtonVisible()),
        ),
        BlocProvider(
          create: (_) => FeatureFlagsCubit(FirebaseService())..load(),
        ),
        BlocProvider(
            create: (_) => ChatBloc(
                  repository: getIt<IChatRepository>(),
                  preferences: getIt<SharedPreferences>(),
                )),
        BlocProvider(
            create: (_) => CommentCubit(
                  repository: getIt<ICommentRepository>(),
                  preferences: getIt<SharedPreferences>(),
                )),
        BlocProvider(
            create: (_) => MessageBloc(
                  repository: getIt<IChatRepository>(),
                  preferences: getIt<SharedPreferences>(),
                )),
        BlocProvider(
            create: (_) => SupportBloc(
                  repository: getIt<ISupportRepository>(),
                  preferences: getIt<SharedPreferences>(),
                )),
        BlocProvider(
            create: (_) => SupplierMarketBloc(
                  repository: getIt<IMarketRepository>(),
                  preferences: getIt<SharedPreferences>(),
                )),
        BlocProvider(
            create: (_) => ReelBloc(
                  repository: getIt<IReelRepository>(),
                  metadataCache: getIt<IReelMetadataCache>(),
                  preferences: getIt<SharedPreferences>(),
                )),
        BlocProvider(
          create: (_) => ReferralCubit(
            repository: getIt<ReferralRepository>(),
            preferences: getIt<SharedPreferences>(),
          )..load(),
        ),
        BlocProvider(
            create: (_) => PitBloc(
                  repository: getIt<IPitRepository>(),
                  preferences: getIt<SharedPreferences>(),
                )),
        BlocProvider(create: (_) => CartBloc(getIt<CartStorageService>())),
        BlocProvider(create: (_) => OrderBloc(getIt<CartStorageService>())),
        BlocProvider(
            create: (_) => BlockBloc(
                  repository: getIt<IBlockRepository>(),
                  preferences: getIt<SharedPreferences>(),
                )),
        BlocProvider(
            create: (_) => ReportCubit(
                  repository: getIt<IReportRepository>(),
                  preferences: getIt<SharedPreferences>(),
                )),
        BlocProvider(
          create: (_) => StreamCubit(
            preferences: getIt<SharedPreferences>(),
            repository: LiveStreamRepositoryImpl(
              remoteDataSource: StreamRemoteDataSource(dio: ApiClient.I.dio),
            ),
          )..endLeftoverBroadcast(),
        ),
        BlocProvider(
          create: (_) => NotificationsCubit(
            dataSource: getIt<NotificationsRemoteDataSource>(),
          ),
        ),
        BlocProvider(
          create: (_) => UpdateCubit(
            checker: getIt<AppUpdateChecker>(),
          )..check(),
        ),
      ],
      child: ScreenUtilInit(
        designSize: const Size(360, 690),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) {
          return ChangeNotifierProvider.value(
            value: _tourController,
            child: ScreenUtilInit(
              designSize: const Size(360, 690),
              builder: (context, child) {
                return MaterialApp.router(
                  routerConfig: _appRouter.config(
                    navigatorObservers: () => [
                      appRouteObserver,
                      FirebaseAnalyticsObserver(
                          analytics: FirebaseAnalytics.instance),
                    ],
                  ),
                  debugShowCheckedModeBanner: false,
                  title: '',
                  theme: context.watch<ThemeNotifier>().getTheme(),
                  builder: (context, router) {
                    return GestureDetector(
                      onTap: () {
                        final focus = FocusManager.instance.primaryFocus;
                        if (focus != null && focus.hasFocus) focus.unfocus();
                      },
                      behavior: HitTestBehavior.translucent,
                      child: Stack(
                        children: [
                          router ?? const SizedBox.shrink(),
                          const UpdateGateOverlay(),
                          DebugFloatingBubble(router: _appRouter),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _ResolvedReelLink {
  const _ResolvedReelLink({
    required this.reels,
    required this.initialIndex,
  });

  final List<ReelModel> reels;
  final int initialIndex;
}
