# Troubleshooting и известные проблемы

Корневые причины реальных багов и архитектурных ловушек проекта. Перед диагностикой нового бага:
получить **точный текст ошибки** и проверить контракт **курлом** (правило проекта), а не гадать по
коду.

## Сборка

### iOS: «File ... has been modified since the module file ... was built»
Устаревший `.pcm` от explicit modules на Xcode 16. **Фикс уже в `ios/Podfile`** (`post_install`
отключает explicit modules на каждом pod-таргете). Если всплыло — `pod deintegrate && pod install`,
затем `flutter clean`. Не удалять флаги из Podfile. См. [onboarding.md](onboarding.md#ios-explicit-modules-отключены-в-podfile).

### Android: ошибки desugaring / `flutter_local_notifications`
Нужен `coreLibraryDesugaringEnabled = true` + `desugar_jdk_libs:2.1.4` в
`android/app/build.gradle` (уже настроено). Java 8 совместимость.

### Предпочитать корневые фиксы, а не `flutter clean`
Если проблема «лечится» только повторным `flutter clean` — искать причину в конфиге (Podfile/Gradle),
а не делать clean привычкой.

## Рантайм

### Мёртвая сессия → пустой home и пустые рилсы
**Симптом:** пустые товары на главной и пустые рилсы одновременно. **Причина:** протухли и access, и
refresh токены — 401 везде (это не баг reels API; эндпоинты работают анонимно). **Фикс (в коде):**
`TokenRefreshInterceptor` при 401 на refresh чистит мёртвые токены и продолжает анонимно.

### WebSocket reconnect storm
**Симптом:** `crash_log.txt` залит `Failed host lookup` каждые ~3с. **Причина:** `connect()` сбрасывал
`_reconnectAttempts = 0` **до** async DNS-ошибки → лимит не срабатывал. **Фикс:** сброс счётчика
только в `channel.ready.then`, `catchError` гасит утечку, backoff + connectivity-гейт. См.
[features/chat.md](features/chat.md#reconnect-логика-важно-reconnect-storm-fix).

### «Заказы оптом» пусты при первом входе (Orders screen был пуст)
**Причина:** home (debounce 250мс) и `OrdersScreen` делили один глобальный `ProductBloc` →
home-fetch отменял запрос экрана. **Фикс:** `OrdersScreen` оборачивает контент в scoped
`BlocProvider<ProductBloc>`. **Не объединять обратно.**

### Stale-фид после refresh (заблокированные авторы снова видны)
`forceRefresh` должен доходить до Dio-кэша через `ApiClient.forceRefreshOptions`
(`CachePolicy.refresh`), иначе 5-минутный кэш отдаёт устаревший фид.

### «Посты грузятся долго» — это клиент, не сервер
Был флуд запросов + дубли + 401-каскад. **Фиксы:** `InFlightGetDedupInterceptor` (схлопывает
параллельные GET) + проактивный JWT-refresh в `TokenRefreshInterceptor.onRequest`. См.
[architecture.md](architecture.md#сетевой-слой).

### Дубли снэкбаров
`showMessage()` имеет 1.2с-дедуп по ключу `variant|message`. На любом `BlocListener` над
глобально-провайдимым BLoC — пара `listenWhen` + guard по состоянию.

### Finik не зачислял пополнение
Была backend-проблема (исправлена). `/finik/webhook/` зачисляет на рекламный кошелёк с лагом от
нескольких секунд до ~1 минуты.

## Архитектурные ловушки

### Два видео-фактори
В проекте сосуществуют `MediaKitPlayerFactory` (mpv) и `VideoPlayerFactory` (`video_player`).
В `main.dart` есть `TODO(phase-2)` о миграции с media_kit. **Перед работой с видео** проверьте,
какая фабрика зарегистрирована как `IPlayerFactory` в `lib/core/di/injection.dart` — документация
описывает обе, но активна одна. См. [features/reels.md](features/reels.md).

### Файл с кириллицей в имени
`lib/pages/auth/сonfirm_phone_screen.dart` — первая буква `с` **кириллическая**. Осторожно с
импортами/переименованием.

### `import_links.dart` — транзитивные импорты
Barrel-файл реэкспортирует общие зависимости. При рефакторинге импортов проверять, не тянется ли
символ транзитивно через него.

### `replace_all` по многострочным паттернам
Если строка переносится на несколько строк — `replace_all` не сматчит, править вручную.

## Безопасность (технический долг)

### Захардкоженный JWT-секрет (live-stream)
`lib/features/live_stream/data/data_sources/live_jwt_factory.dart` подписывает HS256-токены
секретом, **зашитым в исходник** → он попадает в клиентский бандл. Любой может выпустить
publish/play-токен. **Рекомендация:** перенести выпуск токенов на backend.

### Секреты платежей в `.env` на устройстве
`SECRET_KEY` (Paybox) и Finik-ключи читаются клиентом из `.env`. Для критичных операций подпись
должна формироваться на сервере. Проверять, что чувствительные операции не полагаются только на
клиентскую подпись.

## Логи на устройстве
- `crash_log.txt` (через share) ← `talker.info` пишет сюда, а не в stdout; `debugPrint` → stdout.
- Беспроводной `flutter run` даёт фейковый «фриз сплеша» — отлаживать по USB/в profile.
- Рилсы и стримы — измерять скорость только в profile-режиме (не debug).
