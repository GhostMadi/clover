# Booking: услуга ↔ пост

**Продукт:** [`docs/business/booking.md`](../business/booking.md) · [`docs/business/publications.md`](../business/publications.md)

## Идея

Пост = витрина процедуры; CTA «Записаться на эту услугу» ведёт в client flow с **предвыбранной** услугой.

Цена и каталог по-прежнему живут в `booking_services`; пост не дублирует прайс, только **ссылку**.

## Модель (как marker)

| Слой | Роль |
|------|------|
| `posts.booking_service_id` | Опциональный FK; **null** → обычный пост |
| `booking_services` | Источник правды: title, price, duration, active |
| `get_post_enriched` | В JSON поста добавляет `booking_service { … }` для CTA |
| List RPC | Достаточно `booking_service_id` в `to_jsonb(p.*)` |

**Кардинальность:** один пост → не более одной услуги. Одна услуга → много постов (портфолио).

## Правила

1. **Тот же владелец:** `posts.user_id = booking_services.host_id` (trigger + RPC).
2. **Чужой пост / чужая услуга** — `P0030 booking_service_not_owned`.
3. **Удаление услуги** — `ON DELETE SET NULL` на посте.
4. **Чтение услуги с поста:** RLS `booking_services_select_by_visible_post` (как для marker).
5. **Неактивная услуга:** связь может остаться; UI не показывает CTA, если `is_active = false`.

## API

### PostgREST

Колонка `posts.booking_service_id` — patch своего поста (срабатывает trigger).

### RPC (рекомендуется для UI)

```sql
set_post_booking_service(p_post_id uuid, p_service_id uuid default null) → void
```

- `p_service_id = null` — отвязать.
- Иначе — привязать; проверки владельца post + service.

### Enriched detail

`get_post_enriched` → поле `booking_service`:

```json
{
  "id": "uuid",
  "title": "Стрижка",
  "emoji_text": "💈",
  "price": 3500,
  "duration_minutes": 45,
  "is_active": true
}
```

`null`, если `booking_service_id` пуст или услуга недоступна по RLS.

## Клиент (Flutter)

1. **Host:** в compose поста — `PostCreateBookingServiceField` (только при теге `booking`, список своих активных услуг); FK уходит в `posts.booking_service_id` при insert.
2. **Guest:** на деталке поста — `PostBookingServiceSection` → `BookingClientRoute(hostId, initialServiceId: …)`.
3. **List:** только `booking_service_id` в JSON; без join. Enriched payload — на detail через `get_post_enriched`.

## Миграция

`20260830170000_posts_booking_service_link.sql`
