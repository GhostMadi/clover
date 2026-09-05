# In-app notifications — Supabase spec

**Process:** [notifications.md](../business/notifications.md)  
**Booking detail:** [booking.md](../business/booking.md) § уведомления  
**Migrations:** [MIGRATIONS_INDEX.md](MIGRATIONS_INDEX.md) § In-app уведомления

---

## 1. Model

Одна таблица **`public.notifications`** для соцграфа и записи.  
Отдельной `booking_notifications` **нет** — тексты только на клиенте (`kind` + `payload`).

| Column | Purpose |
|--------|---------|
| `recipient_id` | Кому |
| `actor_id` | Кто инициировал (≠ recipient) |
| `kind` | English key |
| `dedupe_key` | Unique; upsert / delete |
| `post_id`, `comment_id` | Social context |
| `booking_id` | Booking context |
| `payload` | jsonb (preview, service_title, starts_at, bonus_earn_amount, …) |
| `read_at` | Unread until set |

RLS: select/update **own** rows only. Writes — **triggers + SECURITY DEFINER RPC**, not direct client INSERT.

---

## 2. Social kinds

| kind | Trigger |
|------|---------|
| `post_like`, `post_dislike` | `post_reactions` |
| `post_comment`, `comment_reply` | `comments` |
| `comment_like`, `comment_dislike` | `comment_reactions` |

Migration: `20260729120000_notifications_reactions_comments.sql`

---

## 3. Follow

| kind | Trigger |
|------|---------|
| `user_follow` | `follow_user` RPC → `upsert_notification` |

List RPC adds `is_following_actor` (via `is_following_user`, not direct `profile_follows` SELECT).

Migrations: `20260830210000`, `20260830211000`, `20260830212000`

Legacy rows backfilled from `notification_events` where `type = follow`.

---

## 4. Booking kinds (instant booking)

**No** `booking_confirmed` — `create_booking` → `confirmed` immediately.

| kind | Recipient | Trigger |
|------|-----------|---------|
| `booking_created_host` | Host | `AFTER INSERT` on `bookings` |
| `booking_booked_client` | Client | same |
| `booking_reminder_client` | Client | Cron: **24 h, 3 h, 1 h, 30 min** before `starts_at` (`confirmed` only) |
| `booking_visit_started` | Host | Cron: `confirmed`, slot started |
| `booking_visit_needs_close` | Host | Cron: visit past `ends_at`, not terminal |
| `booking_cancelled_host` | Host | `cancelled_by = client` |
| `booking_cancelled_client` | Client | `cancelled_by = host` |
| `booking_completed_client` | Client | `status → completed` |
| `booking_no_show_client` | Client | `status → no_show` |

Migration: `20260830220000_booking_notifications.sql` · client reminders: `20260830230000_booking_client_reminders.sql`

### Payload (booking)

```json
{
  "service_title": "Стрижка",
  "service_emoji": "💈",
  "starts_at": "2026-08-30T10:00:00+05:00",
  "ends_at": "2026-08-30T10:45:00+05:00",
  "bonus_earn_amount": 50,
  "minutes_before": 60
}
```

`minutes_before` — only on `booking_reminder_client`.

### Dedupe keys

- `booking:{id}:created:host` / `:created:client`
- `booking:{id}:reminder:1440` / `:180` / `:60` / `:30`
- `booking:{id}:visit_started`
- `booking:{id}:needs_close`
- `booking:{id}:cancelled:host` / `:cancelled:client`
- `booking:{id}:completed:client`
- `booking:{id}:no_show:client`

Visit / client reminder keys **deleted** when booking leaves `confirmed` or reaches terminal status.

### Cron

- `booking_notifications_scan_scheduled()` — every **15 min** (`pg_cron`): host visit pings + client reminders
- `booking_auto_close_stale_visits()` — hourly; default target **`no_show`** (same migration family)

---

## 5. RPC (client)

| RPC | Purpose |
|-----|---------|
| `list_notifications_enriched_cursor(limit, cursor…)` | Feed 30d; actor json, post preview, `booking_id`, `is_following_actor` |
| `mark_notifications_read(ids?)` | Mark read |
| `count_unread_notifications()` | Dashboard badge |

---

## 6. Flutter

`lib/feature/_feed_/notification_page/` — list, tile copy, follow button, badge via `NotificationsUnreadCubit`.

Navigation: post → `PostRoute`; follow → `GuestProfileRoute`; booking host → `BookingListRoute`; booking client → `MyBookingsRoute`.

---

## 7. Backlog

| Item | Status |
|------|--------|
| In-app social + booking | **v1 done** |
| Push / FCM | **Client token sync v1** — см. [SPEC_PUSH_FCM.md](SPEC_PUSH_FCM.md) |
| `push_device_tokens` + outbox | Table v1; send outbox v2 |
| Client in-app reminders (24h / 3h / 1h / 30m) | **v1** — `booking_reminder_client` |
| Action buttons in notification tile | v2 |
