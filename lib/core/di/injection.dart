import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:optombai/core/update/app_update_checker.dart';

// Interfaces
import 'package:optombai/data/repositories/i_product_repository.dart';
import 'package:optombai/data/repositories/i_user_repository.dart';
import 'package:optombai/data/repositories/i_auth_repository.dart';
import 'package:optombai/data/repositories/i_category_repository.dart';
import 'package:optombai/data/repositories/i_chat_repository.dart';
import 'package:optombai/data/repositories/i_comment_repository.dart';
import 'package:optombai/data/repositories/i_favorite_repository.dart';
import 'package:optombai/data/repositories/i_market_repository.dart';
import 'package:optombai/data/repositories/i_pmt_repository.dart';
import 'package:optombai/data/repositories/i_review_repository.dart';
import 'package:optombai/data/repositories/i_reel_repository.dart';
import 'package:optombai/data/repositories/i_subscription_repository.dart';
import 'package:optombai/data/repositories/i_image_repository.dart';
import 'package:optombai/data/repositories/i_settings_repository.dart';
import 'package:optombai/data/repositories/i_pit_repository.dart';
import 'package:optombai/data/repositories/i_iap_repository.dart';
import 'package:optombai/data/repositories/i_store_review_repository.dart';
import 'package:optombai/data/repositories/i_support_repository.dart';
import 'package:optombai/data/repositories/i_admin_request_repository.dart';
import 'package:optombai/data/repositories/i_block_repository.dart';
import 'package:optombai/data/repositories/i_report_repository.dart';

// Implementations
import 'package:optombai/data/repositories/product_repository.dart';
import 'package:optombai/data/repositories/user_repository.dart';
import 'package:optombai/data/repositories/auth_request.dart';
import 'package:optombai/data/repositories/category_repository.dart';
import 'package:optombai/data/repositories/chat_repository.dart';
import 'package:optombai/data/repositories/comment_repository.dart';
import 'package:optombai/data/repositories/favorite_repository.dart';
import 'package:optombai/data/repositories/market_repository.dart';
import 'package:optombai/data/repositories/pmt_repository.dart';
import 'package:optombai/data/repositories/review_repository.dart';
import 'package:optombai/data/repositories/reel_repository.dart';
import 'package:optombai/data/repositories/subscription_repository.dart';
import 'package:optombai/data/repositories/image_repository.dart';
import 'package:optombai/data/repositories/settings_repository.dart';
import 'package:optombai/data/repositories/pit_repository.dart';
import 'package:optombai/data/repositories/iap_repository.dart';
import 'package:optombai/data/repositories/store_review_repository.dart';
import 'package:optombai/data/repositories/support_repository.dart';
import 'package:optombai/data/repositories/admin_request_repository.dart';
import 'package:optombai/data/repositories/block_repository.dart';
import 'package:optombai/data/repositories/report_repository.dart';

// Feature repositories
import 'package:optombai/features/promotion/domain/repository/promotion_repository.dart';
import 'package:optombai/features/promotion/data/repository/promotion_repository_impl.dart';
import 'package:optombai/features/promotion/data/data_sources/promotion_remote_data_source.dart';
import 'package:optombai/features/referral/domain/repository/referral_repository.dart';
import 'package:optombai/features/referral/data/repository/referral_repository_impl.dart';
import 'package:optombai/features/referral/data/data_sources/referral_remote_data_source.dart';
import 'package:optombai/features/notifications/data/data_sources/device_remote_data_source.dart';
import 'package:optombai/features/notifications/data/data_sources/notifications_remote_data_source.dart';
import 'package:optombai/services/push/push_notification_service.dart';
import 'package:optombai/services/chat/chat_resolver.dart';

// Service interfaces
import 'package:optombai/services/i_video_pre_buffer_service.dart';
import 'package:optombai/services/i_player_factory.dart';
import 'package:optombai/services/video_player_factory.dart';
import 'package:optombai/services/reel_metadata_cache.dart';
import 'package:optombai/services/connectivity_aware_config.dart';

// Services
import 'package:optombai/data/api_client.dart';
import 'package:optombai/services/cart_storage_service.dart';
import 'package:optombai/services/chat_auth_guard.dart';
import 'package:optombai/services/video_pre_buffer_service.dart';
import 'package:optombai/services/analytics/i_analytics_service.dart';
import 'package:optombai/services/analytics/firebase_analytics_service.dart';

final getIt = GetIt.instance;

/// Registers all dependencies in the service locator.
///
/// Must be called once during app startup, after [SharedPreferences] is ready.
void configureDependencies(SharedPreferences preferences) {
  // ── Core ──────────────────────────────────────────────────────────────
  getIt.registerSingleton<SharedPreferences>(preferences);

  // ── Repositories (lazy singletons: interface -> concrete) ─────────────
  getIt.registerLazySingleton<IProductRepository>(
    () => ProductRepository(),
  );
  getIt.registerLazySingleton<IUserRepository>(
    () => UserRepository(),
  );
  getIt.registerLazySingleton<IAuthRepository>(
    () => AuthRepository(),
  );
  getIt.registerLazySingleton<ICategoryRepository>(
    () => CategoryRepository(),
  );
  getIt.registerLazySingleton<IChatRepository>(
    () => ChatRepository(),
  );
  getIt.registerLazySingleton<ICommentRepository>(
    () => CommentRepository(),
  );
  getIt.registerLazySingleton<IFavoriteRepository>(
    () => FavoriteRepository(),
  );
  getIt.registerLazySingleton<IMarketRepository>(
    () => MarketRepository(),
  );
  getIt.registerLazySingleton<IPmtRepository>(
    () => PmtRepository(),
  );
  getIt.registerLazySingleton<IReviewRepository>(
    () => ReviewRepository(),
  );
  getIt.registerLazySingleton<IReelRepository>(
    () => ReelRepository(),
  );
  getIt.registerLazySingleton<ISubscriptionRepository>(
    () => SubscriptionRepository(),
  );
  getIt.registerLazySingleton<IImageRepository>(
    () => ImageRepository(),
  );
  getIt.registerLazySingleton<ISettingsRepository>(
    () => SettingsRepository(),
  );
  getIt.registerLazySingleton<IPitRepository>(
    () => PitRepository(),
  );
  getIt.registerLazySingleton<IIapRepository>(
    () => IAPRepository(),
  );
  getIt.registerLazySingleton<IStoreReviewRepository>(
    () => StoreReviewRepository(),
  );
  getIt.registerLazySingleton<ISupportRepository>(
    () => SupportRepository(),
  );
  getIt.registerLazySingleton<IAdminRequestRepository>(
    () => AdminRequestRepository(),
  );
  getIt.registerLazySingleton<IBlockRepository>(
    () => BlockRepository(),
  );
  getIt.registerLazySingleton<IReportRepository>(
    () => ReportRepository(),
  );

  // ── Feature repositories ─────────────────────────────────────────────
  getIt.registerLazySingleton<PromotionRepository>(
    () => PromotionRepositoryImpl(
      PromotionRemoteDataSource(ApiClient.I.dio, preferences),
    ),
  );
  getIt.registerLazySingleton<ReferralRepository>(
    () => ReferralRepositoryImpl(
      ReferralRemoteDataSource(ApiClient.I.dio, preferences),
    ),
  );

  // ── Services ──────────────────────────────────────────────────────────
  getIt.registerLazySingleton<CartStorageService>(
    () => CartStorageService(),
  );
  getIt.registerLazySingleton<ChatAuthGuard>(
    () => ChatAuthGuard(preferences),
  );
  getIt.registerLazySingleton<IPlayerFactory>(
    () => VideoPlayerFactory(),
  );
  getIt.registerLazySingleton<IVideoPreBufferService>(
    () => VideoPreBufferService(playerFactory: getIt<IPlayerFactory>()),
  );
  getIt.registerLazySingleton<IReelMetadataCache>(
    () => ReelMetadataCache(prefs: preferences),
  );
  getIt.registerLazySingleton<IConnectivityConfig>(
    () => ConnectivityConfig(),
  );
  getIt.registerLazySingleton<IAnalyticsService>(
    () => FirebaseAnalyticsService(),
  );

  // ── Notifications & push ─────────────────────────────────────────────
  getIt.registerLazySingleton<DeviceRemoteDataSource>(
    () => DeviceRemoteDataSource(ApiClient.I.dio, preferences),
  );
  getIt.registerLazySingleton<NotificationsRemoteDataSource>(
    () => NotificationsRemoteDataSource(ApiClient.I.dio, preferences),
  );
  getIt.registerLazySingleton<PushNotificationService>(
    () => PushNotificationService(
      deviceDataSource: getIt<DeviceRemoteDataSource>(),
    ),
  );
  getIt.registerLazySingleton<ChatResolver>(
    () => ChatResolver(getIt<IChatRepository>()),
  );
  getIt.registerLazySingleton<AppUpdateChecker>(
    () => AppUpdateChecker(),
  );
}
