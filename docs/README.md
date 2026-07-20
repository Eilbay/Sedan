# Документация Eilbay Mobile

Полная техническая документация проекта. Начните отсюда, если вы новый разработчик.

## Быстрый старт

1. **[onboarding.md](onboarding.md)** — установка окружения, секреты, setup-гочи (iOS/Android), первый запуск. **Читать первым.**
2. **[architecture.md](architecture.md)** — слои, поток запуска, диаграммы.
3. **[../README.md](../README.md)** — обзор проекта и таблица «где менять ключи».

## Справочники

| Документ | О чём |
|---|---|
| [architecture.md](architecture.md) | Слоистая архитектура, DI, поток запуска, сетевой слой, JWT (+Mermaid) |
| [bloc-catalog.md](bloc-catalog.md) | Каталог всех ~33 BLoC/Cubit: события, состояния, зависимости, провайдинг |
| [api-contracts.md](api-contracts.md) | Реальные эндпоинты, тела запросов/ответов (auth, posts, media, chat, streams, payments) |
| [navigation.md](navigation.md) | auto_route: маршруты, guards, как добавить экран |
| [how-to.md](how-to.md) | Рецепты: добавить экран / эндпоинт / BLoC / перевод / модель |
| [testing.md](testing.md) | Что покрыто тестами, как запускать, стратегия |
| [troubleshooting.md](troubleshooting.md) | Известные проблемы и их корневые причины |

## Разбор подсистем (features)

| Документ | Подсистема |
|---|---|
| [features/reels.md](features/reels.md) | Видео-рилсы: фид v2, пул плееров, пребуферинг, lifecycle |
| [features/chat.md](features/chat.md) | Чат: WebSocket, reconnect, ChatBloc/MessageBloc |
| [features/live-stream.md](features/live-stream.md) | Live-стримы: WebRTC (SRS), пул плееров, лайв-чат |
| [features/payments.md](features/payments.md) | Платежи: IAP, FreedomPay, Finik, рекламный кошелёк |
| [features/cart-orders.md](features/cart-orders.md) | Корзина и заказы (локальный Hive), checkout-флоу |

> Документация описывает состояние ветки `main`. При расхождении кода и доки — **истина в коде**;
> проверяйте контракты курлами (правило проекта «curl-first»).
