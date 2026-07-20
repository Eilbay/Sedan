# Eilbay Mobile (optombai)

Мобильное приложение B2B/B2C-маркетплейса **Eilbay / Optombai** для iOS и Android: каталог
товаров, видео-рилсы, live-стримы, чаты, заказы, онлайн-оплата, реферальная программа и
продвижение объявлений.

- **Package (pubspec):** `optombai`
- **Версия:** `2.0.242+260514` (`versionName+versionCode`)
- **Flutter:** `3.35.7` (зафиксирована через **fvm** в `.fvmrc`)
- **Dart SDK:** `>=3.0.0 <4.0.0`
- **iOS bundle id:** `kg.eilbay` (+ extension `kg.eilbay.OneSignalNotificationServiceExtension`)
- **Android applicationId:** `b2b.optombai.app`
- **iOS min target:** `18.5` · **Android:** `compileSdk 36`, `targetSdk 35`, `minSdk = flutter.minSdkVersion`

---

> 📚 **Полная документация — в каталоге [`docs/`](docs/README.md)** (онбординг, архитектура с
> диаграммами, каталог BLoC, API-контракты, разбор подсистем, how-to, troubleshooting).
> Этот README — обзор и быстрый справочник.

## Содержание

1. [Стек технологий](#стек-технологий)
2. [Архитектура](#архитектура)
3. [Структура каталогов](#структура-каталогов)
4. [Поток запуска (startup)](#поток-запуска-startup)
5. [Сетевой слой и API](#сетевой-слой-и-api)
6. [Аутентификация и JWT](#аутентификация-и-jwt)
7. [Где менять ключи и конфигурацию](#где-менять-ключи-и-конфигурацию-)
8. [Платежи](#платежи)
9. [Push-уведомления](#push-уведомления)
10. [Видео-архитектура (reels)](#видео-архитектура-reels)
11. [Локализация](#локализация)
12. [Темы (light/dark)](#темы-lightdark)
13. [Навигация (auto_route)](#навигация-auto_route)
14. [Локальное хранилище](#локальное-хранилище)
15. [Обработка ошибок и логирование](#обработка-ошибок-и-логирование)
16. [Сборка и запуск](#сборка-и-запуск)
17. [Полезные команды (justfile / skills)](#полезные-команды)

---

## Стек технологий

| Область | Решение |
|---|---|
| **State management** | `flutter_bloc` 9.x (BLoC + Cubit), `equatable` |
| **DI** | `get_it` 9.x (`registerLazySingleton`) |
| **Навигация** | `auto_route` 10.x (`@RoutePage`, кодогенерация) |
| **HTTP** | `dio` 5.x + `dio_cache_interceptor` + кастомные интерсепторы |
| **Локальное хранилище** | `shared_preferences` (токены, флаги), `hive` (корзина, заказы) |
| **Видео** | `media_kit` (mpv напрямую) — основной; `video_player` — легаси |
| **Live-стриминг** | `flutter_webrtc` + `web_socket_channel` |
| **Платежи** | `flutter_paybox_2` (FreedomPay/Paybox), `finik_sdk`, `in_app_purchase` |
| **Push / Firebase** | `firebase_core`, `firebase_messaging`, `firebase_crashlytics`, `firebase_database`, `flutter_local_notifications`; OneSignal-extension на iOS |
| **Локализация** | кастомный словарь `lib/l10n/tr.dart` (6 языков) |
| **Прочее** | `translator`, `flutter_screenutil`, `cached_network_image`, `permission_handler`, `app_links` (deep links), `talker` (логи) |

---

## Архитектура

Приложение построено по слоистой архитектуре с инверсией зависимостей:

```
UI (pages / widgets)
   │   context.read<XxxBloc>().add(Event)
   ▼
BLoC / Cubit  (lib/bloc, lib/features/*/presentation)
   │   зависят от АБСТРАКЦИЙ репозиториев (IXxxRepository)
   ▼
Repositories  (lib/data/repositories)  — реализации интерфейсов
   │   используют ApiClient + модели
   ▼
ApiClient (Dio + интерсепторы)  ──►  Backend REST API (/api/v1, /api/v2)
```

**Ключевые принципы :**
- **SOLID + Clean Code.** Репозитории описаны интерфейсами (`abstract class I...Repository`), BLoC получают их через конструктор из `get_it` (Dependency Inversion).
- **Запрещены helper-методы** (статические утилитные классы). Логика выносится в extension-методы, сервисы и use-case классы.
- **Навигация только `auto_route`** с `@RoutePage()` и guard-ами (`AuthGuard`).
- **Immutable-модели** на `Equatable` с `copyWith`.
- **Единая обработка ошибок** через sealed `AppException` + `ErrorHandler`.

---

## Структура каталогов

```
lib/
├── main.dart                 # Точка входа: zoneGuarded, Firebase, DI, Hive, runApp
├── firebase_options.dart     # Сгенерированные опции Firebase (по платформам)
│
├── app/
│   ├── app.dart              # MyApp → MaterialApp.router, провайдеры, тема
│   └── router/
│       ├── app_router.dart   # 67 маршрутов auto_route (+ guards)
│       └── app_router.gr.dart# Сгенерированный part-файл
│
├── bloc/                     # Глобальные BLoC/Cubit (по доменам)
│   ├── auth_bloc/  product_bloc/  cart_bloc/  reel_bloc/  chat_bloc/
│   ├── favorite_bloc/  order_bloc/  user_bloc/  category_bloc/
│   ├── ad_wallet_bloc/  subscription_bloc/  pmt_bloc/  language_bloc/
│   ├── block_bloc/  report_bloc/  comment_bloc/  banner_bloc/ ... (~30 шт.)
│
├── core/
│   ├── di/injection.dart     # configureDependencies() — регистрация всех зависимостей
│   ├── error/                # AppException, ErrorHandler, GlobalErrorHandler, crash_log_file
│   ├── enums/                # EnumRequestType и пр.
│   ├── deep_link/            # Обработка app_links
│   ├── debug/                # FrameTimingLogger, HeartbeatService
│   ├── appColors.dart        # Базовая палитра (light/dark)
│   ├── theme_notifier.dart   # ThemeNotifier (ChangeNotifier, isDarkMode)
│   ├── dark/                 # Тёмная тема (DarkBackground и т.д.)
│   └── import_links.dart     # Barrel-файл общих зависимостей
│
├── configs/
│   ├── app_color.dart        # Цвета навигации/аватаров
│   ├── app_style.dart        # Типографика
│   └── constrants.dart       # Константы
│
├── data/
│   ├── api_client.dart       # ApiClient (Dio + интерсепторы)
│   ├── domain_set.dart       # ApiEndpoints — ВСЕ URL эндпоинтов
│   ├── models/               # Модели (User, Product, Cart, Order ...)
│   ├── repositories/         # Реализации репозиториев
│   └── services/             # Сервисы уровня данных
│
├── features/                 # Самодостаточные фичи (domain/data/presentation)
│   ├── live_stream/          # WebRTC-стриминг (StreamPlayerPool)
│   ├── notifications/        # Push device data source + список уведомлений
│   ├── promotion/            # Продвижение (target/* API)
│   ├── referral/             # Реферальная программа
│   └── try_on/               # Виртуальная примерка
│
├── pages/                    # Экраны, сгруппированные по разделам
│   ├── auth/  add_product/  cart/  category/  chat/  profile/
│   ├── reels/  pmt/  wallet/  promotion/  support/  moderation/  webview/
│   └── main_screen/  → bottom_nav.dart (загрузка данных после splash)
│
├── services/
│   ├── config_service.dart           # Динамический base URL (Vercel config)
│   ├── media_kit_player_factory.dart # Фабрика mpv-плееров
│   ├── video_pre_buffer_service.dart # Пул предзагрузки рилсов
│   ├── connectivity_aware_config.dart# Адаптивная конкуррентность по сети
│   ├── iap_service.dart              # In-App Purchase
│   ├── wallet_payment_service.dart   # Пополнение рекламного кошелька
│   ├── push/                         # PushNotificationService
│   ├── chat/  media/                 # Сервисы чата и медиа
│   └── ...
│
├── widgets/                  # Переиспользуемые виджеты (shimmer, common, drawer ...)
├── utils/extensions/         # Extension-методы (URL, валидация, строки)
├── l10n/tr.dart              # Словарь переводов (6 языков)
├── paybox/ · finik/          # Платёжные экраны/клиенты
└── onboarding/ · tour/ · tutorial/  # Онбординг и showcase
```

---

## Поток запуска (startup)

`main.dart` → `_appMain()`:

1. **`runZonedGuarded`** ловит все async-ошибки → `GlobalErrorHandler`.
2. Перехват ошибок фреймворка (`FlutterError.onError`) и платформы (`PlatformDispatcher.onError`).
3. `MediaKit.ensureInitialized()` — инициализация mpv.
4. `_initializeFirebase()` — `Firebase.initializeApp` + Crashlytics включён во всех билдах.
5. `SharedPreferences.getInstance()`.
6. **`configureDependencies(preferences)`** — поднимается весь DI-контейнер.
7. `ConfigService.initFast(prefs)` — быстрый bootstrap base URL из кэша (без сети).
8. `_initializeHive()` — адаптеры и боксы корзины/заказов.
9. `MemoryPressureHandler` + `AppLifecycleLogger` + `FrameTimingLogger` + `HeartbeatService`.
10. `runApp(ChangeNotifierProvider<ThemeNotifier> → MyApp)`.
11. **`_initializeDeferredServices()`** (после первого кадра): `ConfigService.refreshConfig()` (сеть),
    `dotenv.load(".env")`, `IAPService().initialize()`.

**Splash → BottomNav (разделение загрузки):**
- **Splash** (`splash_screen.dart`): только auth-флоу + метаданные рилсов.
- **BottomNav** (`bottom_nav.dart`): баннеры, избранное, корзина (сразу); валюта, подписка,
  история платежей, документы (отложенно ~1с); прекэш обложек рилсов; IAP-listener.

---

## Сетевой слой и API

### Базовый URL — динамический

URL backend **не захардкожен**, а грузится из удалённого конфига:

- `lib/services/config_service.dart`
  - Источник: **`https://elibay-api.vercel.app/config.json`** (поле `start_point`).
  - Fallback по умолчанию: **`https://optombai.com`**.
  - Кэш в `SharedPreferences`: ключи `start_point`, `app_config`.
  - `getApiUrl()` → `<start_point>/api/v1`.

### Эндпоинты — единый реестр

Все URL собраны в `lib/data/domain_set.dart` → класс **`ApiEndpoints`** (геттеры на базе `baseApi`):

- `baseApi` = `getApiUrl()` (v1), `baseApiV2` = подмена `/api/v1` → `/api/v2`.
- Рилсы v2: `reelsFeed`, `reelsFeedProgress`, `postsApiV2`, `postMediaApiV2`.
- Профиль/контент: `accountsApi`, `postsApi`, `categoriesApi`, `favoritesApi`, `reviewsApi`, `commentsApi`.
- Чат/поддержка: `chatApi`, `chatsListApi`, `supportApi`.
- Реферал: `referralMy*`. Продвижение: `target*`. Уведомления: `notifications*`, `devices*`.
- Платежи: `iapValidateApi`, `freedomPayRedirect/Webhook`, `finikWebhook`.

> **Любой новый эндпоинт добавляется только сюда**, не в виде строки по месту.

### ApiClient и интерсепторы

`lib/data/api_client.dart` → singleton `ApiClient.I`. Dio: connect 10с / receive 30с,
keep-alive, gzip, до 8 соединений на хост. Цепочка интерсепторов:

| Интерсептор | Назначение |
|---|---|
| `EmptyBearerInterceptor` | Отбрасывает запрос с пустым токеном (анонимный доступ без сети) |
| `TokenRefreshInterceptor` | Проактивный + реактивный refresh JWT (см. ниже) |
| `RetryInterceptor` | До 2 повторов на 5xx (экспон. задержка; multipart пропускается) |
| `ErrorBodyCompactor` | Усечение больших/HTML тел ошибок |
| `InFlightGetDedupInterceptor` | Схлопывает одинаковые параллельные GET в один запрос |
| `DioCacheInterceptor` | Кэш GET (MemCacheStore, stale 5 мин; 401/403 не кэшируются) |
| `TimingInterceptor` / `TalkerDioLogger` | Тайминги и логирование |

`options(token)` / `optionsNoCache(token)` / `optionsFormData(token)` — хелперы заголовков
авторизации (в `domain_set.dart`).

---

## Аутентификация и JWT

`TokenRefreshInterceptor`:

- **Хранилище токенов** — `SharedPreferences`:
  - `TOKEN_KEY` — access-JWT
  - `REFRESH_TOKEN_KEY` — refresh-JWT
  - `REGISTER_KEY` — флаг прохождения регистрации
- **Проактивный refresh**: на `onRequest` декодирует `exp` (через `dart_jsonwebtoken`) и
  обновляет токен заранее (с запасом ~15с), чтобы не ловить 401.
- **Реактивный refresh**: на `401` — `POST {baseApi}/accounts/token/refresh/` с `{ "refresh": ... }`,
  ответ `{ "access": ... }`, повтор исходного запроса.
- **Мёртвая сессия**: при 401 на сам refresh или `code: token_not_valid` токены очищаются,
  приложение продолжает работать **анонимно** (эндпоинты доступны без авторизации).
- Guard: `AuthGuard` (`app_router.dart`) проверяет `TOKEN_KEY` и редиректит на `SignInRoute`
  для защищённых экранов (профиль другого пользователя, избранное и т.д.).

---

## Где менять ключи и конфигурацию ⚙️

> Сводная таблица — самое важное для деплоя/ротации ключей.

| Что | Файл / место | Примечание |
|---|---|---|
| **Base URL backend** | удалённо: `https://elibay-api.vercel.app/config.json` (поле `start_point`) | можно сменить домен без релиза; локальный fallback — в `config_service.dart` (`_defaultStartPoint`, `_configUrl`) |
| **Платёжные ключи** | `/.env` (грузится `dotenv.load(".env")`) | НЕ в git — раздать вручную/CI |
| `FINIK_API_KEY`, `FINIK_ACCOUNT_ID`, `FINIK_IS_BETA` | `.env` | Finik SDK |
| `MERCHANT_ID`, `SECRET_KEY`, `MERCHANT_CURRENCY`, `PAYBOX_TEST_MODE` | `.env` | FreedomPay / Paybox |
| **FreedomPay base URL** | `domain_set.dart` → `freedomPayBaseUrl = https://api.freedompay.kg` | хардкод |
| **Firebase (Dart)** | `lib/firebase_options.dart` | генерируется `flutterfire configure` |
| **Firebase (Android)** | `android/app/google-services.json` | плагин `google-services` сейчас закомментирован в `android/app/build.gradle:4` |
| **Firebase (iOS)** | `ios/Runner/GoogleService-Info.plist` | **в репозитории отсутствует** — добавить перед iOS-сборкой |
| **Android signing** | `android/keystore.properties` (+ `android/key.jks`) | ключи: `storeFile`, `storePassword`, `keyAlias`, `keyPassword`. Файлы НЕ в git |
| **iOS bundle / подпись** | `ios/Runner.xcodeproj` (`PRODUCT_BUNDLE_IDENTIFIER = kg.eilbay`) | подпись в Xcode / signing settings |
| **IAP product ids** | `lib/services/iap_service.dart` | `business_weekly/monthly`, `ad_wallet_500/1000/2000/5000` |
| **IAP-валидация (сервер)** | `ApiEndpoints.iapValidateApi` = `{baseApi}/iap/validate/` | platform `apple`/`google` |
| **OneSignal (iOS extension)** | `ios/OneSignalNotificationServiceExtension`, target `kg.eilbay.OneSignalNotificationServiceExtension` | App ID настраивается в Info.plist расширения |
| **App-иконки** | `pubspec.yaml` → `flutter_launcher_icons` (`assets/logo2.png`, `assets/pro2.png`) | `flutter pub run flutter_launcher_icons` |

> **`.env.example` отсутствует** — при первом клоне создайте `.env` вручную с ключами из таблицы
> (FreedomPay/Finik). Без `.env` приложение стартует, но платежи работать не будут.

---

## Платежи

Доступно три канала:

### 1. In-App Purchase (Apple / Google)
- `lib/services/iap_service.dart` (`IAPService`, singleton) + `lib/data/repositories/iap_repository.dart`.
- Продукты: подписки `business_weekly`, `business_monthly`; пакеты кошелька
  `ad_wallet_500/1000/2000/5000`.
- Валидация на сервере: `POST {baseApi}/iap/validate/`
  (`platform`, `receipt_data`, `subscription_id`, `package_name`, `transaction_id`).
- `completePurchase()` вызывается **только после** успешной серверной валидации (требование Apple).
- iOS использует `PaymentQueueDelegate`.

### 2. FreedomPay / Paybox
- `lib/paybox/` (клиент `PayboxClient`, пакет `flutter_paybox_2`).
- Ключи из `.env`: `MERCHANT_ID`, `SECRET_KEY`, `MERCHANT_CURRENCY` (def. KGS), `PAYBOX_TEST_MODE`.
- Редирект: `freedomPayRedirect(pmtId)`, webhook: `freedomPayWebhook`.

### 3. Finik
- `lib/finik/` (`FinikPaymentScreen`, `@RoutePage`, пакет `finik_sdk`).
- Ключи из `.env`: `FINIK_API_KEY`, `FINIK_ACCOUNT_ID`, `FINIK_IS_BETA`.
- Webhook: `finikWebhook` = `{baseApi}/finik/webhook/` (кредитует рекламный кошелёк).

### Рекламный кошелёк (AdWallet)
- `lib/services/wallet_payment_service.dart` (`WalletPaymentService`) + `AdWalletBloc`.
- Пополнение через Finik/FreedomPay либо IAP; продвижение объявлений через `target/*` API.

---

## Push-уведомления

- Главный класс: `lib/services/push/push_notification_service.dart` (`PushNotificationService`).
- **FCM** (`firebase_messaging`) — основной транспорт; `flutter_local_notifications` — локальный показ.
- На iOS подключено расширение **OneSignalNotificationServiceExtension** (target `kg.eilbay.OneSignalNotificationServiceExtension`).
- Регистрация устройства: `POST {accountsApi}/push/devices/register/` (через `DeviceRemoteDataSource`),
  есть `unregister` и `heartbeat`.
- Android-канал: `eilbay_default`. Если открыт чат — локальный баннер подавляется.
- Deep-навигация по payload: `message → chat`, `like/comment → список уведомлений → ProductDetails`
  (`ChatResolver` резолвит чат по id). См. `notifications*` эндпоинты.

---

## Видео-архитектура (reels)

Используется **media_kit** напрямую (mpv), без моста `video_player`:

- `IPlayerFactory` → `MediaKitPlayerFactory` (`lib/services/media_kit_player_factory.dart`) —
  создаёт `Player` с mpv-настройками (8 МБ буфер, 120с readahead и т.д.).
- `IVideoPreBufferService` → `VideoPreBufferService` — пул плееров (макс. 15, FIFO-вытеснение),
  таймаут первого кадра 6с.
- `ReelPlaybackManager` (`lib/pages/reels/`) — плеер + `VideoController` на индекс рилса (±3).
- `ConnectivityAwareConfig` — конкуррентность 1 на старте, 2 при входе в рилсы.
- Фид рилсов: `GET /api/v2/posts/reels-feed/` (offset, цикличный `next`), прогресс — `reels-feed/progress/`.
  Есть офлайн-очередь действий `ReelFeedActionQueue`.

---

## Локализация

- Кастомный словарь: `lib/l10n/tr.dart` — `Map<ключ, Map<язык, перевод>>`.
- Языки: **`ru`, `en`, `de`, `tr`, `ky`, `zh-cn`**.
- Текущий язык — `LanguageBloc`; доступ в UI — `context.translateText(text)`
  (`TranslationContextExtension`). Runtime-перевод произвольных строк — пакет `translator`.
- **Где добавлять строки:** новый ключ в `tr.dart` со всеми 6 языками.

---

## Темы (light/dark)

- `lib/core/theme_notifier.dart` — `ThemeNotifier` (`ChangeNotifier`), ключ `isDarkMode` в `SharedPreferences`,
  методы `setTheme`/`toggleTheme`. Провайдится в `main.dart`.
- В UI читать через `context.select<ThemeNotifier, bool>(...)` (полную `ThemeData` берёт только `app.dart`).
- Палитры: `lib/core/appColors.dart` (базовые light/dark) и `lib/configs/app_color.dart`
  (навигация/аватары). Тёмный фон-градиент — `lib/core/dark/`.

---

## Навигация (auto_route)

- Конфиг: `lib/app/router/app_router.dart` (**67 маршрутов**) + сген. `app_router.gr.dart` (part-файл).
- Экраны помечены `@RoutePage()`; виджеты без суффикса Screen/Page — с явным `name:`.
- Переходы: `context.router.push(SomeRoute())`, `maybePop()`, `replaceAll([...])`.
- Guards: `AuthGuard` для защищённых маршрутов.
- ⚠️ Все импорты моделей для маршрутов должны быть в `app_router.dart` (т.к. `.gr.dart` — `part`).

После изменения маршрутов: `fvm dart run build_runner build --delete-conflicting-outputs`.

---

## Локальное хранилище

- **SharedPreferences** — токены (`TOKEN_KEY`, `REFRESH_TOKEN_KEY`, `REGISTER_KEY`), `isDarkMode`,
  кэш конфига (`start_point`, `app_config`), язык и пр.
- **Hive** — корзина и заказы. Адаптеры регистрируются в `main.dart` (`_initializeHive`),
  боксы: `cartItems`, `orders` (typeId 10–14).

---

## Обработка ошибок и логирование

- `lib/core/error/app_exception.dart` — sealed `AppException` (вкл. `BlockedException` для 403 BLOCKED).
- `ErrorHandler` — единый разбор ошибок в репозиториях/блоках.
- `GlobalErrorHandler` — точка сбора всех необработанных ошибок (zone/flutter/platform) → Crashlytics + файл.
- `crash_log_file.dart` — пишет `crash_log.txt` (доступен через share); `HeartbeatService`,
  `FrameTimingLogger`, `AppLifecycleLogger` помогают отличать OOM-kill от watchdog-freeze.
- Логи запросов — `talker_dio_logger`.

---

## Сборка и запуск

### Требования
- Flutter **3.35.7** (`fvm install` подтянет нужную версию по `.fvmrc`).
- Xcode (iOS, min target 18.5), Android Studio / SDK.
- Файлы, которых нет в git: `.env`, `android/keystore.properties`, `android/key.jks`,
  `ios/Runner/GoogleService-Info.plist`.

### Первичная настройка
```bash
fvm install
fvm flutter pub get
# Кодогенерация маршрутов auto_route (+ прочая генерация)
fvm dart run build_runner build --delete-conflicting-outputs
# Создать .env с платёжными ключами (см. раздел «Где менять ключи»)
# Запуск
fvm flutter run
```

### Релизные сборки
```bash
fvm flutter build apk --release        # Android APK
fvm flutter build appbundle --release  # Android AAB (для Google Play)
fvm flutter build ios --release        # iOS
```

---

## Полезные команды

### justfile (`just <recipe>`)
| Рецепт | Действие |
|---|---|
| `apk` | release APK + открыть папку |
| `aab` | release AAB (App Bundle) |
| `release` | `clean → deps → apk → aab` |
| `clean` | `flutter clean` |
| `deps` | `flutter pub get` |
| `analyze` | `flutter analyze` |
| `run` | запуск приложения |

---

## Конвенции разработки

- Общение/обсуждение — на русском; **комментарии в коде — на английском**.
- После любых изменений Dart-кода: **`fvm flutter analyze` → 0 errors** (baseline info ≈ 258–272).
- Без helper-методов: extension-методы / сервисы / use-case классы.
- Навигация — только `auto_route`. Новые эндпоинты — только в `ApiEndpoints`.
- Curl-first для backend-контрактов: имя поля берётся из ответа бэка, а не из swagger.

---

