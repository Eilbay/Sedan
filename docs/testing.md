# Тестирование

## Текущее покрытие

В `test/` — **12 тестовых файлов**. Покрытие выборочное (критичные узлы видео и постов), не сквозное.

| Файл | Что покрывает |
|---|---|
| `test/widget_test.dart` | базовый смоук |
| `test/core/deep_link_parser_test.dart` | парсинг deep links |
| `test/services/video_pre_buffer_service_test.dart` | пул пребуфера, лимиты, FIFO |
| `test/services/video_player_factory_test.dart` | фабрика плееров |
| `test/pages/reels/reel_playback_manager_test.dart` | окно ±2, переиспользование плееров |
| `test/bloc/reel_bloc_test.dart` | загрузка/пагинация/дедуп рилсов |
| `test/bloc/product_bloc_test.dart` | фильтры/пагинация товаров |
| `test/bloc/upload_cubit_test.dart` | upload-флоу v2, retry |
| `test/data/models/post_model_test.dart` | парсинг модели поста |
| `test/widgets/product_cover_image_test.dart` | обложка товара |
| `test/widgets/upload_progress_banner_test.dart` | баннер прогресса загрузки |
| `test/helpers/test_utils.dart` | утилиты тестов |

**Инструменты:** `flutter_test`, `mocktail` (моки), `bloc_test`-подобные сценарии вручную.

## Запуск

```bash
fvm flutter test                 # все тесты   (или /test)
fvm flutter test test/bloc/      # подкаталог
fvm flutter test --coverage      # с покрытием → coverage/lcov.info
```

## Стратегия (рекомендации)

- **BLoC/Cubit** — основная зона юнит-тестов: события → состояния, на `mocktail`-моках интерфейсов
  репозиториев (всё уже за абстракциями — мокать легко).
- **Репозитории** — мокать `ApiClient`/Dio (`DioAdapter` или `mocktail`), проверять формирование
  тела запроса (особенно поля v2-постов и auth).
- **Видео-сервисы** — самые хрупкие (память, конкуррентность) → держать тесты пула/менеджера зелёными.
- **Виджеты** — golden/smoke для ключевых карточек.

## Чего нет (технический долг)

- **CI отсутствует** (`.github/workflows` нет) — тесты и `flutter analyze` не гоняются автоматически.
  Рекомендуется GitHub Actions: `flutter analyze` + `flutter test` на PR.
- Нет интеграционных (`integration_test`) и e2e сценариев (auth → заказ → оплата).
