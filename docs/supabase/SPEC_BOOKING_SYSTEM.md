# Booking System — Supabase Spec

Production-ready backend для модуля **Запись** (`lib/feature/booking`).

**Навигатор миграций:** [`migrations/_booking/README.md`](migrations/_booking/README.md)

---

## 1. Overview

| Роль | Описание |
|------|----------|
| **Host** | `profiles.id = auth.uid()`, тег `booking`, CRUD каталога и расписания |
| **Client** | Любой authenticated user, создаёт запись через RPC |
| **Staff** | Мастер host-аккаунта (`booking_staff`), optional `profile_id` |

### Принципы

- Нормализованная схема, без JSON-расписаний
- Double-booking: Postgres `EXCLUDE` + `tstzrange`
- Availability только на сервере (`get_booking_availability`)
- Mutations с бизнес-логикой: `SECURITY DEFINER` RPC
- Снапшоты услуги на `bookings` для исторической корректности

---

## 2. Schema

### Enums

- `booking_status`: `pending`, `confirmed`, `completed`, `cancelled`
- `booking_horizon_kind`: `days_ahead`, `until_date`
- `booking_history_action`: `created`, `status_changed`, `rescheduled` (reserved)

### Entity diagram

```
profiles (host)
  ├── booking_staff
  │     ├── booking_staff_schedule (weekday 1–7)
  │     ├── booking_staff_absences
  │     └── booking_blocked_slots
  ├── booking_services
  │     └── booking_service_staff (M2M)
  ├── booking_schedule_settings (1 row)
  └── bookings ← client profiles
        └── booking_history
```

~~`booking_reviews`~~ сняты (`20260906111000`); in-app отзывы не делаем.
### Key constraints

- `bookings`: EXCLUDE overlap on `staff_id` + time range (pending/confirmed)
- `booking_blocked_slots`: EXCLUDE overlap on `staff_id` + time range
- `booking_services`: trigger blocks `is_active=false` if future active bookings exist
- `client_notes`: max 300 chars

---

## 3. Schedule resolution

Function: `booking_resolve_staff_day_window(staff_id, day)`

| Priority | Source |
|----------|--------|
| 1 | Staff absence on date → not working |
| 2 | `booking_staff_schedule` row for ISO weekday |
| 3 | Account `rest_weekdays` → not working |
| 4 | Account `default_work_start_time` / `default_work_end_time` |

Horizon: `booking_last_bookable_day(host_id)` from `booking_schedule_settings`.

Timezone: `booking_schedule_settings.timezone` (default `Asia/Almaty`).

Slot step: `slot_step_minutes` ∈ {15, 30, 60}.

---

## 4. RPC Reference

### `create_booking`

```sql
create_booking(
  p_host_id uuid,
  p_service_id uuid,
  p_staff_id uuid,
  p_starts_at timestamptz,
  p_participants_count int default 1,
  p_client_notes text default null
) returns uuid
```

**Validations:** booking tag, active service/staff, M2M link, horizon, working window, slot alignment, no overlap (staff + client cross-host), blocked slots.

**Result:** новая запись сразу `confirmed`, `confirmed_at = now()`; в `booking_history` — `new_status = confirmed` (без этапа `pending` для клиента).

**Errors:** `P0020` not available, `P0021` conflict, `P0022` service, `P0023` staff, `P0024` schedule, `P0025` disabled, `P0026` future bookings (deactivate), `P0027` self-booking.

### `get_booking_availability`

```sql
get_booking_availability(
  p_host_id uuid,
  p_service_id uuid,
  p_staff_id uuid,
  p_day date
) returns jsonb
```

Response fields: `day_unavailable_reason`, `slots[]`, `work_start`, `work_end`, `slot_step_minutes`.

Slot object: `{ starts_at, status, conflict_label? }`.

### `list_host_bookings_enriched`

Cursor: `{"starts_at": "...", "id": "..."}`. Search `p_query` (min 2 chars): client name, username, phone, service title.

### `list_my_bookings_enriched`

Same cursor pattern, no search in v1.

### `update_booking_status`

| Transition | Actor |
|------------|-------|
| pending → confirmed | host |
| confirmed → completed | host |
| pending/confirmed → cancelled | host; client if before `starts_at` |

Writes `booking_history`.

### `deactivate_booking_service`

Soft-deactivate; fails if future pending/confirmed bookings exist.

### `get_booking_analytics`

Returns: `total_bookings`, status breakdown, `revenue`, `avg_check`, `popular_services[]`, `top_staff[]`.

---

## 5. RLS Summary

| Table | Client read | Host write |
|-------|-------------|------------|
| Catalog (staff, services, settings) | Active + booking tag | own rows |
| `bookings` | own as client | own as host |
| `booking_blocked_slots` | — | host only |

Direct INSERT/UPDATE on `bookings` — **not granted** to authenticated.

---

## 6. Migrations

| Timestamp | File |
|-----------|------|
| 20260726120000 | `booking_schema.sql` |
| 20260726120100 | `booking_rls_grants.sql` |
| 20260726120200 | `booking_rpc.sql` |

Apply: `supabase db push` or CI migration pipeline.

Verify: `supabase/scripts/verify_booking_rpcs.sql`

---

## 7. Flutter integration checklist

- [ ] Repositories for host catalog (PostgREST)
- [ ] `BookingClientRepository`: availability + create
- [ ] `BookingListRepository`: host list + search
- [ ] `MyBookingsRepository`: client list
- [ ] `BookingAnalyticsRepository`
- [ ] Replace mock stores in `lib/feature/booking/`
- [ ] Map JSON fields to existing Dart models (`BookingListItem`, `MyBookingItem`, …)

---

## 8. Backlog

| Feature | Status |
|---------|--------|
| In-app booking notifications | **v1** — общая `notifications`, см. [SPEC_IN_APP_NOTIFICATIONS.md](SPEC_IN_APP_NOTIFICATIONS.md) |
| Push / FCM | Not v1 |
| In-app reviews | **Removed** — no `booking_reviews` |
| Per-staff schedule UI | Backend ready |
| Realtime host inbox | Optional |

---

## 9. Acceptance checklist

- [ ] Per-staff vs account schedule produces correct slots
- [ ] Blocked slot blocks availability and create
- [ ] Parallel create on same slot → one wins (EXCLUDE)
- [ ] Cross-host client conflict in availability
- [ ] History on create + status change
- [ ] Service deactivate blocked with future bookings
- [x] Host search by client/service
- [x] Client reschedule (same window as cancel)
- [x] Blocked slots + staff schedule UI
- [ ] Analytics metrics complete
- [ ] RLS isolation between users
