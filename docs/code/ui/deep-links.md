# Deep links (in-app navigation)

**Статус:** v1  
**Код:** `lib/core/deep_link/` · `lib/core/config/app_link_config.dart`

---

## Схемы

| Тип | Пример |
|-----|--------|
| Custom scheme | `clover://p/{postId}` |
| HTTPS (universal) | `https://clover.app/p/{postId}` |

iOS: scheme `clover` в `Info.plist`.  
HTTPS требует Associated Domains на `clover.app` (настройка в Apple Developer + `apple-app-site-association` на домене).

---

## Маршруты (каждый — свой intent)

| URL path | Экран |
|----------|--------|
| `/p/{id}`, `/post/{id}` | Пост |
| `/u/{userId}`, `/profile/{userId}` | Чужой профиль |
| `/followers/{userId}` | Подписчики |
| `/following/{userId}` | Подписки |
| `/chat/{chatId}` | Чат по id |
| `/chat?with={userId}` | DM с пользователем |
| `/book/{hostId}?service={serviceId}` | Запись к хозяину |
| `/book/host` | Inbox хозяина (настройки записи) |
| `/bookings/mine`, `/bookings/mine/{id}` | Мои бронирования / деталь |
| `/bookings/host`, `/bookings/host/{id}` | Inbox / деталь записи |
| `/notifications` | Уведомления |
| `/bonuses` | Мои бонусы |
| `/home`, `/feed` | Home (лента/карта) |
| `/messages` | Чаты |
| `/me` | Свой профиль |

Деталь записи по `{id}`: RPC `get_booking_enriched_for_viewer` — роль client/host определяется на бэке.

---

## Поток

1. `AppDeepLinkService` слушает `app_links` (cold + warm).
2. До входа ссылка **копится** в pending.
3. После дашборда / онбординга — `flushPending()` → `AppDeepLinkParser` → `AppDeepLinkNavigator`.
4. Уведомления по записи с `booking_id` используют тот же `openBookingById`.

---

## Генерация ссылок в коде

```dart
AppLinkConfig.post(postId);
AppLinkConfig.profile(userId);
AppLinkConfig.bookHost(hostId, serviceId: serviceId);
AppLinkConfig.myBooking(bookingId);
```
