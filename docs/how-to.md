# How-to: типовые задачи

Рецепты под архитектуру проекта. После любой правки Dart: `fvm flutter analyze` → 0 errors.

## Добавить экран

1. Создать виджет экрана, пометить `@RoutePage()`:
   ```dart
   @RoutePage()
   class ProductDetailsScreen extends StatelessWidget { ... }
   ```
   Если имя без суффикса `Screen`/`Page` — `@RoutePage(name: 'ProductDetailsRoute')`.
2. Добавить маршрут в `lib/app/router/app_router.dart` (`AutoRoute(page: ProductDetailsRoute.page)`).
3. Если экран принимает модель-аргумент — импорт модели **в `app_router.dart`** (не в `.gr.dart`).
4. Кодогенерация:
   ```bash
   fvm dart run build_runner build --delete-conflicting-outputs   # или /gen
   ```
5. Навигация: `context.router.push(ProductDetailsRoute(product: p))`.
6. Защита (опц.): добавить `AuthGuard` в `guards: [...]` маршрута.

## Добавить эндпоинт

1. Добавить геттер в `ApiEndpoints` (`lib/data/domain_set.dart`) — **никаких строк-URL по месту**:
   ```dart
   static String get myThing => '$baseApi/my-thing/';
   ```
2. Добавить метод в **интерфейс** репозитория (`i_xxx_repository.dart`), затем в реализацию.
   Использовать `ApiClient.I` и `options(token)`/`optionsNoCache(token)`.
3. **Проверить курлом** до интеграции: имя поля брать из ответа бэка, не из swagger.
4. Вызвать из BLoC/Cubit через интерфейс (получен в конструкторе из `getIt`).

## Добавить BLoC/Cubit

1. Создать `xxx_bloc.dart` (+ events/state). Зависеть от **интерфейса** репозитория через
   конструктор (DIP). Состояние — immutable + `copyWith` (или sealed-классы).
2. Зарегистрировать репозиторий в `lib/core/di/injection.dart` (`registerLazySingleton`).
   **Сам BLoC в get_it не регистрируется.**
3. Добавить провайдер в `MultiBlocProvider` (`lib/app/app.dart`):
   ```dart
   BlocProvider(create: (_) => MyBloc(getIt<IMyRepository>(), getIt())),
   ```
   Если BLoC нужен точечно — оборачивать локальным `BlocProvider` на экране (scoped).
4. На `BlocListener` глобального BLoC — обязателен `listenWhen` + guard по состоянию (избегать
   повторных снэкбаров/действий).

## Добавить перевод

1. Открыть `lib/l10n/tr.dart`, добавить ключ со **всеми 6 языками** (`ru, en, de, tr, ky, zh-cn`):
   ```dart
   'my_key': {'ru': '...', 'en': '...', 'de': '...', 'tr': '...', 'ky': '...', 'zh-cn': '...'},
   ```
2. В UI: `context.translateText('my_key')` (`TranslationContextExtension`).
3. Не использовать helper-методы для форматирования — выносить в extension/сервис.

## Добавить Hive-модель

1. Создать модель с `@HiveType(typeId: N)` (новый уникальный typeId; текущие заняты 10–14).
2. Запустить кодогенерацию адаптера (`/gen`).
3. Зарегистрировать адаптер и открыть бокс в `main.dart` → `_initializeHive()`.

## Изменить ключ/секрет
См. таблицу в [корневом README](../README.md#где-менять-ключи-и-конфигурацию-) и
[onboarding.md](onboarding.md#2-секреты-и-конфиги-не-в-git).

## Сменить домен backend без релиза
Поменять `start_point` в удалённом `https://elibay-api.vercel.app/config.json` — клиент подхватит
при следующем `ConfigService.refreshConfig()` (после первого кадра). Локальный fallback —
`_defaultStartPoint` в `lib/services/config_service.dart`.
