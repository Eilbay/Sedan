# Рилсы (видео-лента)

Вертикальная видео-лента в стиле TikTok: персонализированный цикличный фид, агрессивный
пребуферинг плееров и офлайн-доставка метрик.

## Компоненты

| Класс | Файл | Роль |
|---|---|---|
| `ReelBloc` | `lib/bloc/reel_bloc/` | состояние: загрузка, фильтр категории, лайки, просмотры, кэш |
| `ReelPlaybackManager` | `lib/pages/reels/reel_playback_manager.dart` | жизненный цикл плееров в окне ±2 вокруг текущего |
| `IVideoPreBufferService` → `VideoPreBufferService` | `lib/services/video_pre_buffer_service.dart` | пул готовых плееров (очередь → processing → ready), FIFO-вытеснение |
| `IPlayerFactory` | `lib/services/media_kit_player_factory.dart`, `lib/services/video_player_factory.dart` | фабрика плееров (см. ⚠️ ниже) |
| `IConnectivityConfig` → `ConnectivityAwareConfig` | `lib/services/connectivity_aware_config.dart` | конкуррентность пребуфера по типу сети |
| `IReelMetadataCache` → `ReelMetadataCache` | `lib/services/reel_metadata_cache.dart` | кэш фида в SharedPreferences (`cached_reel_metadata_v3`) |
| `ReelFeedActionQueue` | `lib/pages/reels/reel_feed_action_queue.dart` | офлайн-очередь прогресса/impression |

> ⚠️ **Две фабрики плееров.** В проекте есть `MediaKitPlayerFactory` (mpv, см. MEMORY) и
> `VideoPlayerFactory` (`video_player`). Идёт миграция (`main.dart` содержит
> `TODO(phase-2): remove MediaKit.ensureInitialized once ... migrate off media_kit`). Какая фабрика
> активна — определяется регистрацией `IPlayerFactory` в `lib/core/di/injection.dart`. **При работе
> с видео сначала проверьте, что именно зарегистрировано.** См.
> [troubleshooting.md](troubleshooting.md#два-видео-фактори).

## Поток данных

```mermaid
sequenceDiagram
    participant Splash
    participant Bloc as ReelBloc
    participant Cache as ReelMetadataCache
    participant API
    participant Screen as ReelsViewerScreen
    participant PB as VideoPreBufferService
    participant PM as ReelPlaybackManager

    Splash->>Bloc: LoadCachedReelsEvent
    Bloc->>Cache: loadCached()
    Cache-->>Splash: мгновенный показ из кэша
    Splash->>Bloc: FetchReelsEvent
    Bloc->>API: GET /api/v2/posts/reels-feed/
    API-->>Bloc: {results[], next (cyclic), nextOffset}
    Bloc->>Cache: сохранить
    Note over Screen: экран смонтирован
    Screen->>Screen: _applyNetworkAwareConfig() → PB.setMaxConcurrent
    Screen->>PM: initControllers(center=0)
    PM->>PB: take(url) — попадание в пул? мгновенный старт
    PM-->>Screen: onCurrentReady → play
    Screen->>PB: enqueue(next 2 urls)
    loop при скролле
        Screen->>PM: initControllers(center=i)
        PM->>PM: pause prev, play current, preload ±1
        PM->>PB: returnToPool(вне ±2)
        Screen->>API: progress (debounce 800ms)
        Screen->>Bloc: RegisterViewEvent
    end
```

## Цикличный фид и пагинация

- Backend возвращает **цикличный `next`** (никогда null) — лента бесконечная.
- `ReelBloc._onFetchMoreReels` дедуплицирует по `id`: если встретился уже загруженный рил → этот и
  следующие = «конец уникального контента» → `hasReachedEnd = true`, сетевые запросы прекращаются.
- На клиенте `PageView` оборачивает индексы (`_wrap(index, len)`) — бесконечный скролл без повторных
  запросов.

## Пребуферинг и память

```mermaid
flowchart LR
    Q[_queue] --> P["_processing<br/>(max _maxConcurrent)"]
    P --> R["_ready map<br/>(max _maxReady)"]
    R -->|take| PM[ReelPlaybackManager]
    PM -->|returnToPool| R
    R -->|переполнен| EV[evict oldest FIFO]
```

- `_maxReady`: iOS 4, Android 3 готовых плеера (контроль памяти, ~30 МБ на плеер).
- `_maxConcurrent` по сети (`ConnectivityAwareConfig`): fast(Wi-Fi)=3, mobile=2, slow/offline=1.
- Окно активных плееров: ±2 от текущего (макс 5). Вне окна — `returnToPool` (pause→seek(0)→volume 0),
  не dispose — для мгновенного реплея при обратном скролле.
- **Адаптивное торможение:** 3 ошибки подряд → пауза очереди (защита от UI-freeze на плохой сети).
- **Защита от быстрого скролла:** `_generation++` на каждый `initControllers`; устаревшая
  инициализация отменяется до завершения, плеер возвращается в пул.
- Таймаут первого кадра: пребуфер 5–6с, playback ~10с (1 ретрай через 1с).

## Lifecycle

- `paused` (фон): `pauseAll()`, `tracker.flush()` (отправить очередь), `flushForBackground()`
  (сбросить готовый пул) — минимизация памяти под OOM-killer.
- `resumed`: `initControllers(isActive=true)` с последнего индекса, `resume()` сбрасывает throttle.
- Прекэш обложек: первые ~10, декодирование разбито на 80мс-интервалы (не фризит слабые устройства).

## Офлайн-метрики (ReelFeedActionQueue)

- Виды: `progress`, `impression`. Дедуп по ключу `"${kind}:${postId}"`.
- Офлайн → копится в памяти; при возврате сети (`connectivity_plus` listener) → `_drain()`.
- Полный сброс очереди при сворачивании приложения.

## Ключевые виджеты

- `_ReelVideoPlayer` (StatefulWidget) — слои: обложка → видео (монтируется скрытым, fade-in после
  первого кадра) → debounced-спиннер буферизации (800мс).
- `_ReelRightActions` — лайк (оптимистично, `LikeReelEvent`/`UnlikeReelEvent`), комментарии, share.
- `_ReelFavoriteButton` — сохранение в «Сохранённые публикации» через `FavoriteBloc` (по `post.id`).
