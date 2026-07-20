import 'package:dio/dio.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:optombai/services/config_service.dart';

class ApiEndpoints {
  static String get baseApi => ConfigService.getApiUrl();

  /// Base API URL pinned to v2 — derived by swapping /api/v1 -> /api/v2
  /// in the dynamic base. Used for endpoints with v2-specific schemas
  /// (e.g. reels with HLS metadata).
  static String get baseApiV2 => baseApi.replaceFirst('/api/v1', '/api/v2');

  static String get accountsApi => '$baseApi/accounts';
  static String get categoriesApi => '$baseApi/categories/';
  static String get favoritesApi => '$baseApi/favorites/';
  static String get postTypesApi => '$baseApi/post_types';
  static String get postsApi => '$baseApi/posts/';

  /// v2 posts endpoint — reels list returns HLS manifest fields
  /// (hls_master_url, hls_ready, hls_renditions) alongside legacy video_url.
  static String get postsApiV2 => '$baseApiV2/posts/';

  /// v2 personalized reels feed — offset pagination, cyclic `next` (never null),
  /// `card_type` (organic/promo), `low_quality` (light 360p for first 4).
  static String get reelsFeed => '$baseApiV2/posts/reels-feed/';

  /// Marks a reel as watched so the feed resumes from the next one. Body:
  /// `{ "post_id": "<uuid>" }`. Response: `{ "ok": true }`.
  static String get reelsFeedProgress => '$baseApiV2/posts/reels-feed/progress/';

  /// v2 media upload endpoint — uploads file first, returns
  /// `{id, image, is_video}`. The id is then included in
  /// `media_ids: [...]` when calling POST /v2/posts/.
  static String get postMediaApiV2 => '$baseApiV2/post-media/';

  static String get postsImagesApi => '$baseApi/posts_images/';
  static String get reviewsApi => '$baseApi/reviews/';
  static String get settingsApi => '$baseApi/settings/';
  static String get storeReviewsApi => '$baseApi/store_reviews/';
  static String get getSocials => '$baseApi/socials/';
  static String get chatApi => '$baseApi/chat';
  static String get chatsListApi => '$baseApi/chats/';
  static String get supportApi => '$baseApi/support';
  static String get supportMyApi => '$supportApi/my';
  static String get supportStartApi => '$supportApi/start';
  static String get referralMyInvitees => '$baseApi/referral/my/invitees/';
  static String get referralMyProfile => '$baseApi/referral/my/profile/';
  static String get referralMyWallet => '$baseApi/referral/my/wallet/';
  static String get referralMyTransactions =>
      '$baseApi/referral/my/transactions/';
  static String get referralMyWithdrawals =>
      '$baseApi/referral/my/withdrawals/';
  static String get currencies => '$baseApi/settings/currencies/';

  // Target/Promotion endpoints
  static String get targetPackages => '$baseApi/target/packages/';
  static String get targetCampaigns => '$baseApi/target/campaigns/';
  static String get targetCampaignsMe => '$baseApi/target/campaigns/me/';
  static String get targetImpressions => '$baseApi/target/impressions/';
  static String targetCampaignCancel(int id) =>
      '$baseApi/target/campaigns/$id/cancel/';
  static String targetAdminCampaignCancel(int id) =>
      '$baseApi/target/admin/campaigns/$id/cancel/';

  // Comments endpoint
  static String get commentsApi => '$baseApi/comments/';

  // Push devices
  static String get devicesRegister =>
      '$accountsApi/push/devices/register/';
  static String get devicesUnregister =>
      '$accountsApi/push/devices/unregister/';
  static String get devicesHeartbeat =>
      '$accountsApi/push/devices/heartbeat/';

  // Notifications
  static String get notificationsList => '$baseApi/notifications/';
  static String get notificationsUnreadCount =>
      '$baseApi/notifications/unread-count/';
  static String notificationsRead(String id) =>
      '$baseApi/notifications/$id/read/';
  static String get notificationsReadAll =>
      '$baseApi/notifications/read-all/';
  static String get notificationsPreferences =>
      '$baseApi/notifications/preferences/';

  // Streams endpoints
  static String get streamsApi => '$baseApi/streams/reels/';
  static String get streamsListApi => '$baseApi/streams/';
  static String streamBan(String streamId) => '$baseApi/streams/$streamId/ban/';
  static String streamUnban(String streamId) => '$baseApi/streams/$streamId/unban/';

  // Market endpoints
  static String get marketApi => '$baseApi/market';

  // IAP endpoint
  static String get iapValidateApi => '$baseApi/iap/validate/';

  // Payment endpoints
  static const String freedomPayBaseUrl = 'https://api.freedompay.kg';
  static String freedomPayRedirect(String pmtId) =>
      '$freedomPayBaseUrl/pay.html?customer=$pmtId';
  static String get freedomPayWebhook => '$baseApi/freedompay/result/';
  static String get finikWebhook => '$baseApi/finik/webhook/';
}

/// Auth options for GET requests — allows HTTP caching
Options options(String token) => Options(
      headers: {
        "Authorization": "Bearer $token",
      },
    );

/// Auth options for mutating requests (POST/PUT/DELETE) — skips cache
Options optionsNoCache(String token) => Options(
      headers: {
        "Authorization": "Bearer $token",
      },
      extra: _noCacheExtra,
    );

Options optionsFormData(String token) => Options(
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "multipart/form-data",
      },
      extra: _noCacheExtra,
    );

final Map<String, dynamic> _noCacheExtra =
    CacheOptions(store: MemCacheStore(), policy: CachePolicy.noCache).toExtra();
