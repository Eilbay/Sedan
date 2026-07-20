# Каталог BLoC / Cubit

State management — `flutter_bloc`. Все BLoC/Cubit провайдятся **глобально** в одном
`MultiBlocProvider` (`lib/app/app.dart`), кроме помеченных «локально». Сами BLoC **не**
регистрируются в get_it — они получают репозитории (интерфейсы) через `getIt<...>()` в конструкторе.

**Соглашения по состояниям:**
- **Один State + флаги** — большинство (`isLoading/isSuccess/...` + данные + `copyWith`).
- **Отдельные классы State** — Auth, Banner, Language, Subscription, Upload (sealed).

## Глобальные BLoC/Cubit

| # | Класс | Файл | Ответственность | Ключевые события / методы | Зависимости |
|---|---|---|---|---|---|
| 1 | `AuthCubit` | `bloc/auth_bloc/auth_cubit.dart` | Аутентификация, регистрация, OTP, токены | методы: `login`, `register`, `activateAccount`, `refreshToken` | `IAuthRepository`, `SubscriptionBloc` |
| 2 | `UserBloc` | `bloc/user_bloc/` | Профиль (свой/чужой), обновление, просмотры, соцссылки, пагинация | `UserOwnerEvent`, `UserOtherEvent`, `UserUpdateEvent`, `SearchUsersEvent`, `UserDeleteEvent` | `IUserRepository` |
| 3 | `CategoryBloc` | `bloc/category_bloc/` | Категории товаров (+кэш) | `CategoryAllEvent`, `CategoryGetEvent` | `ICategoryRepository` |
| 4 | `ProductBloc` | `bloc/product_bloc/` | Товары: фильтр, пагинация, создание, статистика, оптимистичные апдейты | `ProductWithFilter`, `GetProductInfo`, `RefreshSingleProduct`, `PreloadHomeEvent`, `OptimisticAdd/RemoveProductEvent` | `IProductRepository` |
| 5 | `UploadCubit` | `bloc/upload_cubit/` | Загрузка медиа + атомарное создание поста (v2) | методы: `startUpload`, `retry`, `dismiss`; states: `UploadProcessing/Creating/Uploading/Success/Error` (sealed) | `IProductRepository`, `MediaProcessor` |
| 6 | `FavoriteBloc` | `bloc/favorite_bloc/` | Избранное (+фильтры) | `FavoriteAllEvent`, `FavoriteCreateEvent`, `FavoriteDelete`, `FavoriteWithFilter` | `IFavoriteRepository` |
| 7 | `ReviewBloc` | `bloc/review_bloc/` | Отзывы на товары | `ReviewCreateEvent`, `AllReviewsEvent`, `UpdateReviewEvent`, `ReviewDeleteEvent` | `IReviewRepository` |
| 8 | `StoreReviewBloc` | `bloc/store_review_bloc/` | Отзывы о магазине | `StoreReviewCreateEvent`, `AllStoreReviewEvent`, ... | `IStoreReviewRepository` |
| 9 | `SubscriptionBloc` | `bloc/subscription_bloc/` | Тарифы подписки | `FetchSubscriptionEvent`; states: `Loading/Loaded/Error` | `ISubscriptionRepository` |
| 10 | `CurrencyBloc` | `bloc/currency_bloc/` | Валюты + выбор | `CurrencyAllEvent`, `SetSelectedCurrencyEvent` | `ISettingsRepository` |
| 11 | `BannerBloc` | `bloc/banner_bloc/` | Рекламные баннеры главной | `BannerAllEvent`; states sealed: `Initial/Loading/Error/Success` | `ISettingsRepository` |
| 12 | `QuestionBloc` | `bloc/question_bloc/` | Обратная связь (вопросы) | `QuestionCreateEvent` | `ISettingsRepository` |
| 13 | `CountryBloc` | `bloc/country_bloc/` | Список стран | `CountryAllEvent` | `ISettingsRepository` |
| 14 | `ImageBloc` | `bloc/image_bloc/` | Фото организации | `ImageCreateEvent`, `GetAllImage`, `ImageDelete` | `IImageRepository` |
| 15 | `DocumentBloc` | `bloc/document_bloc/` | Документы | `DocumentImageCreateEvent`, `GetAllDocumentImage`, `ImageDocumentDelete` | `IImageRepository` |
| 16 | `PmtBloc` | `bloc/pmt_bloc/` | Платежи: создание, история, статус | `PmtCreateEvent`, `PmtHistoryEvent`, `PmtStatusEvent`, `PmtByIdEvent` | `IPmtRepository` |
| 17 | `AdminRequestBloc` | `bloc/admin_request_bloc/` | Запросы администратору | `SendRequest` | `IAdminRequestRepository` |
| 18 | `LanguageBloc` | `bloc/language_bloc/` | Язык + перевод (Google Translator + кэш) | `ChangeLanguageEvent`, `TranslateTextEvent` | `GoogleTranslator` |
| 19 | `ButtonVisibleBloc` | `bloc/button_visible_bloc/` | Видимость кнопки подписки (Firebase + страна) | `LoadButtonVisible`, `ButtonVisibleChanged`, `UpdateButtonVisible` | `FirebaseService`, `UserBloc` |
| 20 | `ChatBloc` | `bloc/chat_bloc/` | Список чатов: создание, мут, перевод, пагинация | `FetchChatsEvent`, `CreatePersonalChatEvent`, `MuteUserEvent`, `TranslateChatEvent`, `DeleteChatEvent` | `IChatRepository` |
| 21 | `CommentCubit` | `bloc/comment_bloc/` | Комментарии к постам | методы: `loadComments`, `createComment`, `deleteComment` | `ICommentRepository` |
| 22 | `MessageBloc` | `bloc/message_bloc/` | Сообщения чата + WebSocket | `FetchMessagesEvent`, `SendMessageEvent`, `ConnectWebSocketEvent`, `NewMessageFromWebSocketEvent`, `ChatWsErrorEvent` | `IChatRepository`, `WebSocketService` |
| 23 | `SupportBloc` | `bloc/support_bloc/` | Сессии поддержки | `CheckActiveSupportSessionEvent`, `StartSupportSessionEvent`, `CloseSupportSessionEvent` | `ISupportRepository` |
| 24 | `SupplierMarketBloc` | `bloc/market_bloc/` | Маркет поставщика (выбор, заявка) | `SupplierMarketInit`, `SupplierMarketSelect`, `SupplierMarketSendRequest` | `IMarketRepository` |
| 25 | `ReelBloc` | `bloc/reel_bloc/` | Видео-посты: загрузка, фильтр, лайки, просмотры, кэш | `FetchReelsEvent`, `FetchMoreReelsEvent`, `LikeReelEvent`, `RegisterViewEvent`, `LoadCachedReelsEvent` | `IReelRepository`, `IReelMetadataCache` |
| 26 | `AdWalletBloc` | `bloc/ad_wallet_bloc/` | Рекламный кошелёк, пополнение, IAP | `LoadAdWalletEvent`, `InitTopUpEvent`, `IAPTopUpEvent` | `IAdWalletRepository` |
| 27 | `CartBloc` | `bloc/cart_bloc/` | Корзина (Hive) | `CartLoadEvent`, `CartAddItemEvent`, `CartCheckoutEvent`, `CartSelectDeliveryEvent` | `CartStorageService` |
| 28 | `OrderBloc` | `bloc/order_bloc/` | Заказы (Hive) + статусы | `OrderLoadEvent`, `OrderPaymentSuccessEvent`, `OrderCheckStatusUpdatesEvent` | `CartStorageService` |
| 29 | `BlockBloc` | `bloc/block_bloc/` | Блокировка пользователей | `BlockUserEvent`, `UnblockUserEvent`, `GetBlockedUsersEvent` | `IBlockRepository` |
| 30 | `ReportCubit` | `bloc/report_bloc/` | Жалобы на контент (+опц. блок) | методы: `submitReport`, `reset` | `IReportRepository` |
| 31 | `ReferralCubit` | `features/referral/presentation/` | Реферальная программа | — | `ReferralRepository` |
| 32 | `StreamCubit` | `features/live_stream/presentation/logic/` | Список лайв-стримов | методы: `getStreams`, `createStream`, `startStream`, `endStream` | `LiveStreamRepository` |
| 33 | `NotificationsCubit` | `features/notifications/presentation/` | Список уведомлений | — | `NotificationsRemoteDataSource` |

## Локальные (scoped) BLoC

| Класс | Где | Почему scoped |
|---|---|---|
| `SocialTypesBloc` | экраны профиля | используется точечно, не нужен глобально |
| `ProductBloc` (scoped) | `OrdersScreen` | оборачивается в локальный `BlocProvider<ProductBloc>`, чтобы home-fetch не отменял запрос экрана (см. [troubleshooting.md](troubleshooting.md#orders-screen-был-пуст)) |
| `LiveChatCubit`, `StreamPlayerCubit` | экраны лайв-стрима | привязаны к жизненному циклу стрима |

## Замечания

- **`ProductBloc` глобальный** провайдится как `.value` (создаётся раньше для предзагрузки home).
  При этом `OrdersScreen` использует **отдельный scoped** экземпляр — намеренно, не объединять.
- `MessageBloc.transientError` — one-shot ошибки WebSocket (например `BLOCKED`), отдельно от
  `errors` (ошибки fetch). Пара `listenWhen` + сброс tick.
- Для глобально-провайдимых BLoC на `BlocListener` обязателен `listenWhen` + guard по состоянию
  (см. дедуп снэкбаров в [troubleshooting.md](troubleshooting.md)).
