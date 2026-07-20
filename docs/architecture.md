# Архитектура

## Слои

Приложение построено по слоистой архитектуре с инверсией зависимостей (DIP): UI зависит от
BLoC, BLoC — от **интерфейсов** репозиториев, репозитории — от `ApiClient`.

```mermaid
flowchart TD
    UI["UI слой<br/>lib/pages, lib/widgets<br/>(@RoutePage экраны)"]
    BLOC["BLoC / Cubit<br/>lib/bloc, lib/features/*/presentation<br/>(~33 шт.)"]
    IREPO["Интерфейсы репозиториев<br/>IProductRepository, IAuthRepository, ..."]
    REPO["Реализации репозиториев<br/>lib/data/repositories"]
    API["ApiClient (Dio + интерсепторы)<br/>lib/data/api_client.dart"]
    EP["ApiEndpoints<br/>lib/data/domain_set.dart"]
    BE[("Backend REST<br/>/api/v1, /api/v2")]
    HIVE[("Hive<br/>корзина, заказы")]
    SP[("SharedPreferences<br/>токены, конфиг, флаги")]

    UI -->|"context.read<Bloc>().add(Event)"| BLOC
    BLOC -->|"зависят от абстракций"| IREPO
    IREPO -.->|реализуются| REPO
    REPO --> API
    REPO --> EP
    API --> BE
    BLOC --> HIVE
    REPO --> SP
    API --> SP
```

**Принципы :**
- SOLID + Clean Code; запрещены helper-методы (статические утилиты) — только extension-методы,
  сервисы и use-case классы.
- Навигация только `auto_route` (`@RoutePage`, guards).
- Immutable-модели на `Equatable` + `copyWith`.
- Единая обработка ошибок: sealed `AppException` + `ErrorHandler` + `GlobalErrorHandler`.

## Dependency Injection (get_it)

`lib/core/di/injection.dart` → `configureDependencies(SharedPreferences)`. Регистрируются
**только репозитории и сервисы** (паттерн `registerLazySingleton`). **BLoC НЕ регистрируются в
get_it** — они создаются в `MultiBlocProvider` в `lib/app/app.dart` и получают репозитории через
`getIt<...>()`.

Группы регистрации:
- **Репозитории** (~21): `IProductRepository`, `IUserRepository`, `IAuthRepository`,
  `ICategoryRepository`, `IChatRepository`, `ICommentRepository`, `IFavoriteRepository`,
  `IMarketRepository`, `IPmtRepository`, `IReviewRepository`, `IReelRepository`,
  `ISubscriptionRepository`, `IImageRepository`, `ISettingsRepository`, `IAdWalletRepository`,
  `IIapRepository`, `IStoreReviewRepository`, `ISupportRepository`, `IAdminRequestRepository`,
  `IBlockRepository`, `IReportRepository`.
- **Сервисы**: `CartStorageService`, `IPlayerFactory`, `IVideoPreBufferService`,
  `IReelMetadataCache`, `IConnectivityConfig`, `DeviceRemoteDataSource`,
  `NotificationsRemoteDataSource`, `PushNotificationService`, `ChatResolver`.
- **Feature-репозитории**: `PromotionRepository`, `ReferralRepository`.

## Поток запуска (startup)

```mermaid
sequenceDiagram
    participant OS
    participant main as main.dart
    participant DI as get_it
    participant Cfg as ConfigService
    participant App as MyApp / Splash
    participant BN as BottomNav

    OS->>main: launch
    main->>main: runZonedGuarded + FlutterError/Platform onError
    main->>main: MediaKit.ensureInitialized()
    main->>main: Firebase.initializeApp + Crashlytics
    main->>main: SharedPreferences.getInstance()
    main->>DI: configureDependencies(prefs)
    main->>Cfg: initFast(prefs)  (base URL из кэша, без сети)
    main->>main: Hive init (cartItems, orders)
    main->>main: MemoryPressure + Lifecycle + Frame + Heartbeat loggers
    main->>App: runApp(ChangeNotifierProvider<ThemeNotifier>)
    main-->>Cfg: _initializeDeferredServices(): refreshConfig (сеть), dotenv.load(.env), IAP.init()
    App->>App: Splash: auth-флоу + ReelBloc метаданные
    App->>BN: после splash
    BN->>BN: баннеры, избранное, корзина (сразу)
    BN-->>BN: валюта, подписка, история, документы (отложенно ~1с)
    BN->>BN: прекэш обложек рилсов, IAP-listener
```

**Ключевое разделение:** Splash грузит **только** аутентификацию и метаданные рилсов; всё
остальное — в `bottom_nav.dart`, чтобы не блокировать первый кадр.

## Сетевой слой

### Динамический base URL
URL backend не захардкожен (`lib/services/config_service.dart`):
- Источник: `https://elibay-api.vercel.app/config.json` (поле `start_point`).
- Fallback: `https://optombai.com`. Кэш в `SharedPreferences` (`start_point`, `app_config`).
- `getApiUrl()` → `<start_point>/api/v1`; v2 — подмена `/api/v1` → `/api/v2`.

### Реестр эндпоинтов
Все URL — в `ApiEndpoints` (`lib/data/domain_set.dart`). Новый эндпоинт добавляется **только сюда**.

### Цепочка интерсепторов Dio (`lib/data/api_client.dart`, singleton `ApiClient.I`)

```mermaid
flowchart LR
    REQ[Request] --> A[EmptyBearer]
    A --> B[TokenRefresh<br/>proactive+reactive]
    B --> C[Retry 5xx ×2]
    C --> D[ErrorBodyCompactor]
    D --> E[InFlightGetDedup]
    E --> F[DioCache<br/>stale 5м]
    F --> G[Timing + TalkerLogger]
    G --> BE[(Backend)]
```

| Интерсептор | Назначение |
|---|---|
| `EmptyBearerInterceptor` | отбрасывает запрос с пустым токеном (анонимный доступ без сети) |
| `TokenRefreshInterceptor` | проактивный + реактивный refresh JWT |
| `RetryInterceptor` | до 2 повторов на 5xx (экспон. задержка; multipart пропускается) |
| `ErrorBodyCompactor` | усечение больших/HTML тел ошибок |
| `InFlightGetDedupInterceptor` | схлопывает одинаковые параллельные GET |
| `DioCacheInterceptor` | кэш GET (MemCacheStore 50 МБ, stale 5 мин; 401/403 не кэшируются) |
| `TimingInterceptor` / `TalkerDioLogger` | тайминги и логи |

## Аутентификация и JWT

```mermaid
sequenceDiagram
    participant App
    participant TRI as TokenRefreshInterceptor
    participant API as Backend

    App->>TRI: GET /posts/ (Bearer access)
    Note over TRI: onRequest: декод exp,<br/>истекает? → refresh заранее
    alt access истёк проактивно
        TRI->>API: POST /accounts/token/refresh/ {refresh}
        API-->>TRI: {access}
        TRI->>TRI: сохранить TOKEN_KEY
    end
    TRI->>API: GET /posts/ (свежий access)
    alt 401 (реактивно)
        API-->>TRI: 401
        TRI->>API: POST /accounts/token/refresh/ {refresh}
        alt refresh валиден
            API-->>TRI: {access} → повтор запроса
        else refresh мёртв / token_not_valid
            TRI->>TRI: очистить токены → анонимный режим
        end
    end
```

- Токены в `SharedPreferences`: `TOKEN_KEY` (access), `REFRESH_TOKEN_KEY` (refresh),
  `REGISTER_KEY` (флаг регистрации).
- При мёртвой сессии токены очищаются, приложение продолжает работать анонимно (эндпоинты
  доступны без авторизации). См. [troubleshooting.md](troubleshooting.md#мёртвая-сессия).
- `AuthGuard` (`lib/app/router/app_router.dart`) редиректит на `SignInRoute` для защищённых
  экранов.

## Карта каталогов

См. раздел «Структура каталогов» в [корневом README](../README.md).
