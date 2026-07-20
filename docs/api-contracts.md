# API-контракты

Реальные эндпоинты и тела запросов/ответов, восстановленные из кода репозиториев. Все URL
строятся от `ApiEndpoints` (`lib/data/domain_set.dart`) на базе динамического base URL
(`<start_point>/api/v1`, v2 — подмена на `/api/v2`).

> ⚠️ **Правило проекта (curl-first):** swagger часто устаревший. Перед интеграцией нового
> эндпоинта проверьте контракт курлом; имя поля берите из ответа бэка. 4xx от NestJS-валидатора
> читать буквально — это финальная истина по контракту.

Все защищённые запросы несут заголовок `Authorization: Bearer <access>`.

## Аутентификация (`/accounts/...`)

| Метод | Путь | Тело | Ответ |
|---|---|---|---|
| POST | `/accounts/token/` | `{username, password, email}` (email дублирует username) | `{access, refresh}` |
| POST | `/accounts/users/?is_email_conf=0\|1` | `{username, password, phone_number, email?, referral_code?}` | `{access_token?, refresh_token?, id, ...}` |
| POST | `/accounts/users/account_activate/` | `{token}` (код из SMS/email) | `{account: "activated"}` |
| POST | `/accounts/token/refresh/` | `{refresh}` | `{access}` |
| POST | `/accounts/users/social_signin/` | `{token}` (OAuth от Google) | `{access, refresh}` |
| POST | `/accounts/users/check_email_to_exist_user/` | `{email}` | 200 если свободно, 4xx если занято |
| POST | `/accounts/users/reset_password_by_pn/` | `{phone_number}` | — |
| POST | `/accounts/users/reset_password_confirm_by_pn/` | `{phone_number, token}` | `{user_id}` |
| PATCH | `/accounts/users/{id}/update_password/` | `{password}` | — |
| PATCH | `/accounts/users/{id}/update_password_check_old/` | `{old_password, password}` | — |

Есть и email-аналоги reset (`reset_password_by_email/`, `reset_password_confirm_by_email/`).

**Поток:** register → код в SMS/email → `account_activate` (или confirm) → `login` (сохраняет
токены) → при 401 авто-`refresh` → если refresh мёртв → logout/анонимный режим.

## Товары (posts)

### Чтение
| Метод | Путь | Query | Ответ |
|---|---|---|---|
| GET | `/posts/` | `category, owner, price__gte, price__lte, search, ordering, product_type, owner__user_type, owner__country, currency, is_video, page, page_size` | пагинация `{count, next, previous, results[]}` |
| GET | `/posts/{id}/` | — | полный `Product` |
| GET | `/posts/stats/by-owner-type/` | — | `PostsStatsByOwnerType` |

### Создание (актуальный путь — v2, media-first)
| Метод | Путь | Тело | Ответ |
|---|---|---|---|
| POST | `/api/v2/post-media/` | FormData `image` (файл) | `{id: int, image: url, is_video: bool}` |
| POST | `/api/v2/posts/` | JSON `{name, description, price:"100.00", category, product_type, media_ids:[int], client_request_id:uuid}` | `{id}` |
| DELETE | `/api/v2/post-media/{id}/` | — | — (откат загрузки) |
| DELETE | `/posts/{id}/` | — | — |

- `price` — строка с 2 знаками.
- `client_request_id` (UUID v4) — **идемпотентность**: retry с тем же id вернёт существующий пост,
  не создаст дубль.
- v1-создание (`POST /posts/` FormData) — легаси-fallback; PATCH-редактирование пока только в v1.

Подробный upload-флоу: [features/cart-orders.md](features/cart-orders.md) и
[how-to.md](how-to.md#добавить-загрузку-товара).

## Рилсы (v2)

| Метод | Путь | Назначение |
|---|---|---|
| GET | `/api/v2/posts/reels-feed/?category=<uuid>` | персонализированный фид, offset-пагинация, **цикличный `next`** (никогда null), поля `card_type` (organic/promo), `low_quality`, HLS (`hls_master_url`, `hls_ready`, `hls_renditions`) |
| POST | `/api/v2/posts/reels-feed/progress/` | `{post_id}` → фид резюмируется со следующего |

Детали: [features/reels.md](features/reels.md).

## Чат

| Метод | Путь | Тело | Ответ |
|---|---|---|---|
| POST | `/chat/start/` | `{user_id, product_id?}` | `Chat` |
| GET | `/chats/` | пагинация | `{next, previous, results[Chat]}` |
| GET | `/chat/{id}/messages/` | пагинация | `{next, previous, results[Message]}` |
| POST | `/chat/{id}/messages/` | FormData `text, type, attachment?` | `Message` |
| POST | `/chat/{id}/messages/read/` | — | `{updated:int}` |
| POST | `/chat/{id}/mute/` | `{user_id, minutes?, until?, reason?}` | — |
| POST | `/chat/{id}/unmute/` | `{user_id}` | — |
| POST | `/chats/{id}/translate/` | — | — |
| GET | `/chats/{id}/translate-status/` | — | `{total, done}` |
| POST | `/chats/{id}/delete/` | — | `{deleted:bool}` |

**WebSocket (приём сообщений):** `wss://<host>/ws/chat/{chatId}/?token=<token>`. Подробно:
[features/chat.md](features/chat.md).

## Live-стримы

| Метод | Путь | Тело | Ответ |
|---|---|---|---|
| GET | `/streams/?status=live` | — | `{next, previous, results[StreamModel]}` |
| GET | `/streams/{id}/` | — | `StreamModel` |
| POST | `/streams/` | `{title, description}` | `StreamModel` |
| POST | `/streams/{id}/start/` | — | `StreamModel` |
| POST | `/streams/{id}/end/` | — | `StreamModel` |
| GET | `/streams/reels/` | пагинация | `Streams` (для рилс-ленты стримов) |

**WebRTC-сигналинг (не REST, SRS-сервер):** `POST /rtc/v1/play/` и `POST /rtc/v1/publish/` с
`{api, streamurl, sdp}`. **Лайв-чат WS:** `wss://<host>/ws/streams/{uuid}/?token=<token>`.
Подробно: [features/live-stream.md](features/live-stream.md).

## Платежи

| Метод | Путь | Назначение |
|---|---|---|
| POST | `/iap/validate/` | валидация чека IAP: `{platform: apple\|google, receipt_data, subscription_id, package_name, transaction_id}` |
| — | `freedomPayRedirect(pmtId)` = `https://api.freedompay.kg/pay.html?customer=<pmtId>` | редирект на оплату Paybox |
| POST (webhook) | `/freedompay/result/` | вебхук FreedomPay |
| POST (webhook) | `/finik/webhook/` | вебхук Finik (кредитует рекламный кошелёк) |

Подробно: [features/payments.md](features/payments.md).

## Прочее (по `ApiEndpoints`)

- Уведомления: `/notifications/`, `/notifications/unread-count/`, `/notifications/{id}/read/`,
  `/notifications/read-all/`, `/notifications/preferences/`.
- Push-устройства: `/accounts/push/devices/register|unregister|heartbeat/`.
- Реферал: `/referral/my/{invitees,profile,wallet,transactions,withdrawals}/`.
- Продвижение (target): `/target/{packages,campaigns,campaigns/me,impressions}/`,
  `/target/campaigns/{id}/cancel/`. Enum placement: `main/search/category_top/video_feed`.
- Комментарии: `/comments/`. Отзывы: `/reviews/`, `/store_reviews/`. Настройки: `/settings/`,
  `/settings/currencies/`. Соцсети: `/socials/`. Поддержка: `/support/{my,start}`.
