import 'package:auto_route/auto_route.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:optombai/pages/settings/advertising_info_screen.dart';
import 'package:optombai/pages/settings/settings_screen.dart';
import 'package:talker_flutter/talker_flutter.dart';

// Guards
import 'package:optombai/app/router/guards/auth_guard.dart';

// Models
import 'package:optombai/data/models/account/user/user.dart';
import 'package:optombai/data/models/cart/order_model.dart';
import 'package:optombai/data/models/category/category_model.dart';
import 'package:optombai/data/models/chat/chat_model.dart';
import 'package:optombai/data/models/chat/linked_post.dart';
import 'package:optombai/data/models/posts/post_model.dart';
import 'package:optombai/data/models/question/question_model.dart';
import 'package:optombai/data/models/reel/reel_model.dart';
import 'package:optombai/data/models/support/support_session_model.dart';
import 'package:optombai/features/live_stream/data/models/live_stream_model.dart'
    hide Chat;
import 'package:optombai/features/live_stream/presentation/logic/stream_player/stream_player_cubit.dart';
import 'package:optombai/onboarding/onboarding_language_screen.dart';
import 'package:optombai/widgets/drawer/premium_tariff.dart';
import 'package:optombai/widgets/drawer/drawer_screens/subscription_card.dart';

// Auth screens
import 'package:optombai/pages/auth/forgot_password.dart';
import 'package:optombai/pages/auth/sign_in.dart';
import 'package:optombai/pages/auth/sign_up.dart';
import 'package:optombai/pages/auth/splash_screen.dart';
import 'package:optombai/pages/auth/сonfirm_phone_screen.dart';

// Main screens
import 'package:optombai/pages/main_screen/main_screen.dart';
import 'package:optombai/pages/main_screen/order_screen.dart';
import 'package:optombai/pages/main_screen/product_details.dart';
import 'package:optombai/pages/main_screen/result_screen.dart';
import 'package:optombai/pages/main_screen/suborder_screen.dart';

// Category screens
import 'package:optombai/pages/category/category_screen.dart';
import 'package:optombai/pages/category/products_screen.dart';
import 'package:optombai/pages/category/subcategory_screen.dart';

// Chat screens
import 'package:optombai/pages/chat/chat_conversation_screen.dart';
import 'package:optombai/pages/chat/chat_list_screen.dart';

// Profile screens
import 'package:optombai/pages/profile/details_user_product.dart';
import 'package:optombai/pages/profile/edit_user_product.dart';
import 'package:optombai/pages/profile/other_user_profile_screen.dart';
import 'package:optombai/pages/profile/profile_screen.dart';
import 'package:optombai/pages/profile/edit/profile_edit_email.dart';
import 'package:optombai/pages/profile/edit/profile_edit_screen.dart';
import 'package:optombai/pages/profile/edit/profile_update_password.dart';
import 'package:optombai/pages/profile/edit/socials/create_socials.dart';
import 'package:optombai/widgets/profile/about_us/about_us_edit.dart';
import 'package:optombai/widgets/profile/about_us/desc_edit.dart';
import 'package:optombai/widgets/profile/about_us/requisites_edit.dart';

// Add product screens
import 'package:optombai/pages/add_product/add_product_screen.dart';
import 'package:optombai/pages/add_product/subcategory.dart';

// Reels screens
import 'package:optombai/pages/reels/reel_category_filter_screen.dart';
import 'package:optombai/pages/reels/reels_and_stream_viewer.dart';
import 'package:optombai/pages/reels/reels_grid_screen.dart';
import 'package:optombai/pages/reels/reels_viewer_screen.dart';

// Favorite
import 'package:optombai/pages/favorite/favorite_screen.dart';

// Cart screens
import 'package:optombai/pages/cart/cart_payment_screen.dart';
import 'package:optombai/pages/cart/cart_tab.dart';
import 'package:optombai/pages/cart/checkout_screen.dart';
import 'package:optombai/pages/cart/order_details_screen.dart';
import 'package:optombai/pages/cart/orders_tab.dart';
import 'package:optombai/pages/cart/pickup_points_screen.dart';

// Support
import 'package:optombai/pages/support/create_support_request_screen.dart';

// Wallet
import 'package:optombai/pages/pit/manager_contact_screen.dart';
import 'package:optombai/pages/pit/pit_screen.dart';

// Payment screens
import 'package:optombai/finik/finik_payment_screen.dart';
import 'package:optombai/pages/pmt/pmt_screen.dart';
import 'package:optombai/pages/webview/webview_screen.dart';
import 'package:optombai/widgets/drawer/pmt_info_screen.dart';

// Live stream screens
import 'package:optombai/features/live_stream/presentation/logic/stream_cubit.dart';
import 'package:optombai/features/live_stream/presentation/pages/create_stream_page.dart';
import 'package:optombai/features/live_stream/presentation/pages/live_room_page.dart';
import 'package:optombai/features/live_stream/presentation/pages/stream_page.dart';
import 'package:optombai/features/live_stream/presentation/pages/stream_reel_preview.dart';

// Try on screens
import 'package:optombai/features/try_on/presentation/pages/try_on_page.dart';
import 'package:optombai/features/try_on/presentation/pages/try_on_progress_page.dart';
import 'package:optombai/features/try_on/presentation/pages/try_on_result_page.dart';

// Referral screens
import 'package:optombai/features/referral/presentation/pages/referral_page.dart';
import 'package:optombai/features/referral/presentation/pages/referral_withdrawl_page.dart';

// Promotion
import 'package:optombai/features/promotion/presentation/screens/promotions_campaigns_screen.dart';
import 'package:optombai/pages/promotion/advertising_kabinet_screen.dart';
import 'package:optombai/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:optombai/features/notifications/presentation/screens/notification_preferences_screen.dart';

// Moderation
import 'package:optombai/pages/moderation/blocked_users_screen.dart';

// Navigation
import 'package:optombai/widgets/bottom_nav.dart';

// Drawer screens
import 'package:optombai/widgets/drawer/drawer_screens/about_us.dart';
import 'package:optombai/widgets/drawer/drawer_screens/complaint_screen.dart';
import 'package:optombai/widgets/drawer/drawer_screens/fulfilment_screen.dart';
import 'package:optombai/widgets/drawer/drawer_screens/info_screen.dart';
import 'package:optombai/widgets/drawer/drawer_screens/law_data.dart';
import 'package:optombai/widgets/drawer/drawer_screens/oferta.dart';
import 'package:optombai/widgets/drawer/drawer_screens/premium_connection.dart';
import 'package:optombai/widgets/drawer/drawer_screens/primary.dart';
import 'package:optombai/widgets/drawer/drawer_screens/priacy_policy.dart';
import 'package:optombai/widgets/drawer/drawer_screens/report_issue_screen.dart';
import 'package:optombai/widgets/drawer/drawer_screens/users_screen..dart';
import 'package:optombai/pages/debug/talker_log_screen.dart';
import 'package:optombai/pages/debug/talker_log_detail_screen.dart';

import 'package:optombai/app/router/route_transitions.dart';

part 'app_router.gr.dart';

@AutoRouterConfig()
class AppRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
        // Auth
        AutoRoute(page: SplashRoute.page, initial: true),
        AutoRoute(page: SignInRoute.page),
        AutoRoute(page: SignUpRoute.page),
        AutoRoute(page: ForgotPasswordRoute.page),
        AutoRoute(page: ConfirmPhoneRoute.page),

        // Main
        AutoRoute(page: BottomNavRoute.page),
        AutoRoute(page: HomeRoute.page),
        AutoRoute(page: OrdersRoute.page),
        AutoRoute(page: ResultsRoute.page),
        AutoRoute(page: ProductDetailsRoute.page),
        AutoRoute(page: OrderStatusRoute.page),

        // Category
        AutoRoute(page: CategoryRoute.page),
        AutoRoute(page: ProductsRoute.page),
        AutoRoute(page: SubcategoryRoute.page),

        // Chat — no transition to match IndexedStack tab switching feel
        CustomRoute(
          page: ChatListRoute.page,
          transitionsBuilder: noTransition,
          duration: Duration.zero,
          reverseDuration: Duration.zero,
        ),
        AutoRoute(page: ChatConversationRoute.page),

        // Profile
        AutoRoute(page: ProfileRoute.page),
        AutoRoute(page: OtherUserProfileRoute.page),
        AutoRoute(page: StateUserProductDetailsRoute.page),
        AutoRoute(page: EditUserProductRoute.page),
        AutoRoute(page: ProfileEditRoute.page),
        AutoRoute(page: ProfileEditEmailRoute.page),
        AutoRoute(page: ProfileEditPasswordRoute.page),
        AutoRoute(page: CreateSocialsRoute.page),
        AutoRoute(page: AboutUsEditRoute.page),
        AutoRoute(page: RequisitesEditRoute.page),
        AutoRoute(page: DescEditRoute.page),

        // Add product
        AutoRoute(page: AddProductRoute.page),
        AutoRoute(page: SubcategoryPickerRoute.page),

        // Reels
        AutoRoute(page: ReelsViewerRoute.page),
        AutoRoute(page: ReelsGridRoute.page),
        AutoRoute(page: ReelsAndStreamViewerRoute.page),
        AutoRoute(page: ReelCategoryFilterRoute.page),

        // Favorite
        AutoRoute(page: FavoriteRoute.page, guards: [AuthGuard()]),

        // Cart
        AutoRoute(page: CartTabRoute.page),
        CustomRoute(page: CartPaymentRoute.page, opaque: false),
        AutoRoute(page: CheckoutRoute.page),
        AutoRoute(page: OrderDetailsRoute.page),
        AutoRoute(page: OrdersTabRoute.page),
        AutoRoute(page: PickupPointsRoute.page),

        // Support
        AutoRoute(page: CreateSupportRequestRoute.page),

        // Wallet
        AutoRoute(page: PitRoute.page),
        AutoRoute(page: ManagerContactRoute.page),

        // Payment
        CustomRoute(page: PmtRoute.page, opaque: false),
        AutoRoute(page: PmtInfoRoute.page),
        AutoRoute(page: FinikPaymentRoute.page),
        AutoRoute(page: WebViewRoute.page),

        // Live stream
        AutoRoute(page: StreamRoute.page),
        AutoRoute(page: CreateStreamRoute.page),
        AutoRoute(page: LiveRoomRoute.page),
        AutoRoute(page: StreamReelPreviewRoute.page),

        // Try on
        AutoRoute(page: TryOnRoute.page),
        AutoRoute(page: TryOnProgressRoute.page),
        AutoRoute(page: TryOnResultRoute.page),

        // Referral
        AutoRoute(page: ReferralRoute.page),
        AutoRoute(page: ReferralWithdrawlRoute.page),

        // Promotion
        AutoRoute(page: PromotionsCampaignsRoute.page),
        AutoRoute(page: AdvertisingKabinetRoute.page),

        // Notifications
        AutoRoute(page: NotificationsRoute.page),
        AutoRoute(page: NotificationPreferencesRoute.page),

        // Moderation
        AutoRoute(page: BlockedUsersRoute.page),

        // Drawer screens
        AutoRoute(page: UsersRoute.page),
        AutoRoute(page: ProAccountsRoute.page),
        AutoRoute(page: ReportIssueRoute.page),
        AutoRoute(page: ComplaintRoute.page),
        AutoRoute(page: FulfilmentRoute.page),
        AutoRoute(page: LawDataRoute.page),
        AutoRoute(page: PrimaryRoute.page),
        AutoRoute(page: PoliticsRoute.page),
        AutoRoute(page: OfertaRoute.page),
        AutoRoute(page: InfoRoute.page),
        AutoRoute(page: AboutUsRoute.page),

        // Onboarding language choose screens
        AutoRoute(page: OnboardingLanguageRoute.page),

        // Settings
        AutoRoute(page: SettingsRoute.page),
        AutoRoute(page: AdvertisingInfoRoute.page),

        // Debug
        AutoRoute(page: TalkerLogRoute.page),
        AutoRoute(page: TalkerLogDetailRoute.page),
      ];
}
