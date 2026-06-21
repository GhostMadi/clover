# Booking — ТЗ для Supabase (backend)

> **Реализовано в миграциях 20260726120000–20260726120200.**  
> Актуальная спека: [`../SPEC_BOOKING_SYSTEM.md`](../SPEC_BOOKING_SYSTEM.md)  
> Навигатор: [`../migrations/_booking/README.md`](../migrations/_booking/README.md)

Документ описывает схему БД, RPC и правила для модуля **Запись** (`lib/feature/booking`), исходя из текущего UI (mock-only).

**Rev. 2** — доработки после review: per-staff schedule, blocked slots, history, search, analytics, reviews, guard деактивации услуг. Уведомления — **не в v1** (backlog).

## Цели

| Требование | Решение |
|------------|---------|
| **Расширяемость** | Нормализованная схема, M2M «услуга ↔ исполнитель», per-staff schedule, снапшоты на `bookings`, nullable `profile_id` у staff |
| **Скорость** | Индексы под листы и поиск, `EXCLUDE` на пересечения слотов, один RPC на availability, keyset pagination |
| **Без кастома** | Стандартный Postgres (`btree_gist`, `tstzrange`, `pg_trgm`), Supabase RLS, `SECURITY DEFINER` RPC по образцу chat |

---

## Связь с существующей системой

- **Включение фичи на профиле:** тег аккаунта `booking` (`marker_tags.key = 'booking'`, group `account`) — уже есть. Кнопка «Записаться» на гостевом профиле показывается при `hasBookingTag`. Отдельный флаг в `profiles` не нужен.
- **Host** = владелец аккаунта (`profiles.id = auth.uid()`).
- **Client** = любой аутентифицированный пользователь, создающий запись к host.
- **Staff (исполнитель)** = сотрудник host-аккаунта; может быть без аккаунта в Clover (`profile_id` nullable).

---

## Модули UI → backend

| UI-модуль | Роль | Backend |
|-----------|------|---------|
| `booking_create` | Host: CRUD услуг | `booking_services`, `booking_service_staff` |
| `booking_settings` | Host: расписание, выходные, отсутствия | `booking_schedule_settings`, `booking_staff_schedule`, `booking_staff_absences`, `booking_blocked_slots` |
| `booking_list` | Host: входящие записи + поиск | `list_host_bookings_enriched` |
| `booking_client` | Client: запись к host | `get_booking_availability`, `create_booking` |
| `my_bookings` | Client: свои записи | `list_my_bookings_enriched` |
| `booking_analytics` | Host: агрегаты | `get_booking_analytics` |

---

## Enums

```sql
create type public.booking_status as enum (
  'pending',
  'confirmed',
  'completed',
  'cancelled'
);

create type public.booking_horizon_kind as enum (
  'days_ahead',
  'until_date'
);

create type public.booking_history_action as enum (
  'created',
  'status_changed',
  'rescheduled'  -- зарезервировано; v1 UI не меняет время
);
```

---

## Таблицы

### 1. `booking_staff`

```sql
create table public.booking_staff (
  id            uuid primary key default gen_random_uuid(),
  host_id       uuid not null references public.profiles(id) on delete cascade,
  display_name  text not null check (char_length(trim(display_name)) >= 1),
  username      text,
  profile_id    uuid references public.profiles(id) on delete set null,
  sort_order    int not null default 0,
  is_active     boolean not null default true,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

create unique index booking_staff_host_username_uidx
  on public.booking_staff (host_id, lower(username))
  where username is not null;

create index booking_staff_host_active_idx
  on public.booking_staff (host_id, is_active, sort_order);
```

---

### 2. `booking_services`

```sql
create table public.booking_services (
  id                    uuid primary key default gen_random_uuid(),
  host_id               uuid not null references public.profiles(id) on delete cascade,
  title                 text not null check (char_length(trim(title)) >= 1),
  emoji_text            text not null default '💈',
  description           text,
  duration_minutes      int not null check (duration_minutes > 0),
  buffer_after_minutes  int not null default 0 check (buffer_after_minutes >= 0),
  price                 numeric(12,2) not null default 0 check (price >= 0),
  max_participants      int not null default 1 check (max_participants >= 1),
  default_staff_id      uuid references public.booking_staff(id) on delete set null,
  is_active             boolean not null default true,
  sort_order            int not null default 0,
  created_at            timestamptz not null default now(),
  updated_at            timestamptz not null default now()
);

create index booking_services_host_active_idx
  on public.booking_services (host_id, is_active, sort_order);
```

#### Деактивация услуги (`is_active = false`)

Soft delete — hard delete не используем.

**Запрет деактивации**, если есть будущие активные записи:

```sql
-- exists (
--   select 1 from bookings b
--   where b.service_id = p_service_id
--     and b.status in ('pending', 'confirmed')
--     and b.starts_at > now()
-- )
```

Enforce в RPC `deactivate_booking_service(p_service_id)` (не прямой PATCH `is_active` с клиента) или `BEFORE UPDATE` trigger → `P0026 service_has_future_bookings`.

---

### 3. `booking_service_staff` — M2M

```sql
create table public.booking_service_staff (
  service_id  uuid not null references public.booking_services(id) on delete cascade,
  staff_id    uuid not null references public.booking_staff(id) on delete cascade,
  primary key (service_id, staff_id)
);

create index booking_service_staff_staff_idx on public.booking_service_staff (staff_id);
```

---

### 4. `booking_schedule_settings` — defaults аккаунта + горизонт

**Не единственный источник рабочих часов.** Хранит fallback для staff без персонального графика и общие параметры бронирования.

```sql
create table public.booking_schedule_settings (
  host_id                 uuid primary key references public.profiles(id) on delete cascade,
  rest_weekdays           int[] not null default '{7}',  -- fallback: ISO 1=пн … 7=вс
  horizon_kind            public.booking_horizon_kind not null default 'days_ahead',
  max_booking_days_ahead  int not null default 14 check (max_booking_days_ahead >= 1),
  max_booking_until_date  date,
  default_work_start_time time not null default '09:00',
  default_work_end_time   time not null default '20:00',
  slot_step_minutes       int not null default 30 check (slot_step_minutes in (15, 30, 60)),
  timezone                text not null default 'Asia/Almaty',
  updated_at              timestamptz not null default now(),

  check (default_work_end_time > default_work_start_time),
  check (
    horizon_kind = 'days_ahead'
    or max_booking_until_date is not null
  )
);
```

Переименование `work_*` → `default_work_*` явно показывает: это дефолт, не график каждого мастера.

---

### 5. `booking_staff_schedule` — персональный график мастера (v1 schema)

Решает кейс «Мастер А: Пн–Пт 09–18, Мастер Б: Вт–Сб 12–21».

```sql
create table public.booking_staff_schedule (
  id              uuid primary key default gen_random_uuid(),
  host_id         uuid not null references public.profiles(id) on delete cascade,
  staff_id        uuid not null references public.booking_staff(id) on delete cascade,
  weekday         int not null check (weekday between 1 and 7),  -- ISO
  is_working      boolean not null default true,
  work_start_time time,
  work_end_time   time,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now(),

  unique (staff_id, weekday),
  check (
    (is_working = false)
    or (work_start_time is not null and work_end_time is not null and work_end_time > work_start_time)
  )
);

create index booking_staff_schedule_staff_idx on public.booking_staff_schedule (staff_id, weekday);
```

#### Резолв рабочего окна на день (функция-хелпер)

```sql
-- booking_resolve_staff_day_window(p_staff_id, p_day date) returns (is_working, start_time, end_time)
--
-- 1. Если есть строка booking_staff_schedule для (staff_id, weekday(p_day)) → использовать её.
-- 2. Иначе fallback:
--    - если weekday in booking_schedule_settings.rest_weekdays → is_working = false
--    - иначе default_work_start_time / default_work_end_time
```

**v1 UI** (`booking_settings`) может писать только `booking_schedule_settings` — backend уже готов к per-staff. Когда появится UI графика мастера — POST в `booking_staff_schedule` без миграций.

---

### 6. `booking_staff_absences`

```sql
create table public.booking_staff_absences (
  id          uuid primary key default gen_random_uuid(),
  host_id     uuid not null references public.profiles(id) on delete cascade,
  staff_id    uuid not null references public.booking_staff(id) on delete cascade,
  start_date  date not null,
  end_date    date not null check (end_date >= start_date),
  note        text,
  created_at  timestamptz not null default now()
);

create index booking_staff_absences_staff_dates_idx
  on public.booking_staff_absences (staff_id, start_date, end_date);
```

---

### 7. `booking_blocked_slots` — блокировка времени host (v1)

Отпуск без fake booking, обед, совещание, личные дела.

```sql
create table public.booking_blocked_slots (
  id          uuid primary key default gen_random_uuid(),
  host_id     uuid not null references public.profiles(id) on delete cascade,
  staff_id    uuid not null references public.booking_staff(id) on delete cascade,
  starts_at   timestamptz not null,
  ends_at     timestamptz not null,
  reason      text,  -- «Обед», «Совещание» — только для host UI
  created_at  timestamptz not null default now(),

  check (ends_at > starts_at)
);

-- тот же паттерн, что bookings
alter table public.booking_blocked_slots add constraint booking_blocked_slots_no_overlap
  exclude using gist (
    staff_id with =,
    tstzrange(starts_at, ends_at, '[)') with &&
  );

create index booking_blocked_slots_staff_starts_idx
  on public.booking_blocked_slots (staff_id, starts_at);
```

В `get_booking_availability` blocked slots → `host_busy` (как занятые bookings).

Host CRUD через PostgREST + RLS или RPC `upsert_booking_blocked_slot`.

---

### 8. `bookings`

```sql
create table public.bookings (
  id                      uuid primary key default gen_random_uuid(),
  host_id                 uuid not null references public.profiles(id) on delete cascade,
  client_id               uuid not null references public.profiles(id) on delete restrict,
  service_id              uuid not null references public.booking_services(id) on delete restrict,
  staff_id                uuid not null references public.booking_staff(id) on delete restrict,

  status                  public.booking_status not null default 'pending',

  starts_at               timestamptz not null,
  ends_at                 timestamptz not null,

  service_title           text not null,
  service_emoji           text not null,
  duration_minutes        int not null,
  buffer_after_minutes    int not null default 0,
  price                   numeric(12,2) not null,
  max_participants        int not null default 1,
  participants_count      int not null default 1 check (participants_count >= 1),

  client_notes            text,

  cancelled_at            timestamptz,
  cancelled_by            uuid references public.profiles(id),
  completed_at            timestamptz,
  confirmed_at            timestamptz,

  created_at              timestamptz not null default now(),
  updated_at              timestamptz not null default now(),

  check (ends_at > starts_at),
  check (char_length(coalesce(client_notes, '')) <= 300)
);

alter table public.bookings add constraint bookings_staff_time_no_overlap
  exclude using gist (
    staff_id with =,
    tstzrange(starts_at, ends_at, '[)') with &&
  )
  where (status in ('pending', 'confirmed'));
```

#### Индексы (листы + поиск)

```sql
create index bookings_host_starts_idx on public.bookings (host_id, starts_at desc)
  where status != 'cancelled';

create index bookings_client_starts_idx on public.bookings (client_id, starts_at desc)
  where status != 'cancelled';

create index bookings_staff_starts_idx on public.bookings (staff_id, starts_at)
  where status in ('pending', 'confirmed');

-- поиск host-листа по названию услуги (снапшот)
create index bookings_service_title_trgm_idx on public.bookings
  using gin (service_title gin_trgm_ops);

-- будущие записи по услуге (guard деактивации)
create index bookings_service_future_active_idx on public.bookings (service_id, starts_at)
  where status in ('pending', 'confirmed');
```

**Поиск по клиенту** — через join на `profiles` (индексы ниже в разделе Search).

---

### 9. `booking_history` — аудит изменений (v1)

Кто подтвердил, кто отменил, когда.

```sql
create table public.booking_history (
  id          uuid primary key default gen_random_uuid(),
  booking_id  uuid not null references public.bookings(id) on delete cascade,
  actor_id    uuid references public.profiles(id) on delete set null,
  action      public.booking_history_action not null,
  old_status  public.booking_status,
  new_status  public.booking_status,
  created_at  timestamptz not null default now()
);

create index booking_history_booking_created_idx
  on public.booking_history (booking_id, created_at desc);
```

**Запись:**

| Событие | action | old_status | new_status |
|---------|--------|------------|------------|
| `create_booking` | `created` | null | `pending` |
| `update_booking_status` | `status_changed` | prev | new |

Только через RPC (не client INSERT). Host видит history своих bookings; client — своих.

---

### 10. `booking_reviews` — отзывы (v1 schema, UI позже)

```sql
create table public.booking_reviews (
  id          uuid primary key default gen_random_uuid(),
  booking_id  uuid not null unique references public.bookings(id) on delete cascade,
  client_id   uuid not null references public.profiles(id) on delete cascade,
  host_id     uuid not null references public.profiles(id) on delete cascade,
  staff_id    uuid references public.booking_staff(id) on delete set null,
  rating      int not null check (rating between 1 and 5),
  review_text text check (char_length(coalesce(review_text, '')) <= 1000),
  created_at  timestamptz not null default now(),

  check (client_id <> host_id)
);

create index booking_reviews_host_created_idx on public.booking_reviews (host_id, created_at desc);
create index booking_reviews_staff_rating_idx on public.booking_reviews (staff_id, rating)
  where staff_id is not null;
```

**Правила (RPC `create_booking_review`, v2 UI):**

- booking.status = `completed`
- booking.client_id = auth.uid()
- один отзыв на booking (`unique booking_id`)
- опционально: только в течение N дней после `completed_at`

Агрегат рейтинга staff — view/RPC позже, schema уже позволяет.

---

## Поиск (host-лист)

UI пока без поля поиска — **заложить в v1 API**.

### Индексы на `profiles`

```sql
create extension if not exists pg_trgm;

create index profiles_full_name_trgm_idx on public.profiles using gin (full_name gin_trgm_ops);
create index profiles_username_trgm_idx on public.profiles using gin (username gin_trgm_ops);
create index profiles_phone_idx on public.profiles (phone) where phone is not null;
```

### Параметр RPC

```sql
list_host_bookings_enriched(
  p_from     timestamptz,
  p_to       timestamptz,
  p_query    text default null,  -- NEW
  p_cursor   jsonb default null,
  p_limit    int default 50
)
```

**`p_query` ищет (ILIKE / `%query%`):**

- `profiles.full_name`
- `profiles.username`
- `profiles.phone`
- `bookings.service_title` (снапшот)

Минимум 2 символа; trim; пустой → без фильтра.

---

## RLS (общие правила)

| Таблица | SELECT | INSERT | UPDATE | DELETE |
|---------|--------|--------|--------|--------|
| `booking_staff` | host + authenticated (catalog) | host | host | host |
| `booking_services` | host + authenticated (active) | host | host | host |
| `booking_service_staff` | как services | host | host | host |
| `booking_schedule_settings` | host + authenticated | host | host | — |
| `booking_staff_schedule` | host + authenticated | host | host | host |
| `booking_staff_absences` | host + authenticated | host | host | host |
| `booking_blocked_slots` | host | host | host | host |
| `bookings` | host + client (свои) | RPC only | RPC only | — |
| `booking_history` | host + client (свои bookings) | RPC only | — | — |
| `booking_reviews` | public read для host profile / staff | RPC (v2) | — | — |

---

## RPC

### `create_booking`

Без изменений сигнатуры. Дополнительные проверки:

- Рабочее окно через `booking_resolve_staff_day_window`, не только account settings.
- Overlap с `booking_blocked_slots`.
- После insert → `booking_history` (`created`).

---

### `get_booking_availability`

Busy sources для staff:

1. `bookings` (pending/confirmed)
2. `booking_blocked_slots`
3. Client cross-bookings (все host)

Day unavailable:

- staff `is_working = false` (schedule)
- staff absence
- day beyond horizon

Response — без изменений формата; `work_start` / `work_end` из resolved window.

---

### `list_host_bookings_enriched`

+ `p_query` (см. Search).

---

### `list_my_bookings_enriched`

Без search в v1 (client обычно мало записей). При необходимости — `p_query` по `host_display_name`, `service_title` в v2.

---

### `update_booking_status`

После смены статуса → insert `booking_history` (`status_changed`, `old_status`, `new_status`, `actor_id = auth.uid()`).

---

### `deactivate_booking_service`

```sql
deactivate_booking_service(p_service_id uuid) returns void
```

Проверка future pending/confirmed bookings → `is_active = false`.

---

### `get_booking_analytics`

```sql
get_booking_analytics(
  p_from      date,
  p_to        date,
  p_staff_id  uuid default null
) returns jsonb
```

**Response (v1):**

```json
{
  "total_bookings": 42,
  "pending_bookings": 4,
  "confirmed_bookings": 8,
  "completed_bookings": 26,
  "cancelled_bookings": 4,
  "revenue": 560000,
  "avg_check": 21538.46,
  "popular_services": [
    {
      "service_id": "...",
      "title": "Стрижка мужская",
      "emoji_text": "💈",
      "booking_count": 18,
      "revenue": 63000
    }
  ],
  "top_staff": [
    {
      "staff_id": "...",
      "display_name": "Марат Т.",
      "booking_count": 22,
      "revenue": 77000,
      "completed_count": 20
    }
  ]
}
```

| Метрика | Правило |
|---------|---------|
| `total_bookings` | все статусы, `starts_at::date` в периоде |
| `*_bookings` | breakdown по status |
| `revenue` | `sum(price)` where status = `completed` |
| `avg_check` | `revenue / nullif(completed_bookings, 0)` |
| `popular_services` | group by `service_id`, top 10 by count |
| `top_staff` | group by `staff_id`, top 10 by count |

Фильтр `p_staff_id` — все метрики только по этому мастеру.

---

## PostgREST (без RPC)

| Операция | Таблица |
|----------|---------|
| CRUD staff | `booking_staff` |
| CRUD services | `booking_services` (деактивация → RPC) |
| Link staff ↔ service | `booking_service_staff` |
| Upsert account settings | `booking_schedule_settings` |
| CRUD staff schedule | `booking_staff_schedule` |
| CRUD absences | `booking_staff_absences` |
| CRUD blocked slots | `booking_blocked_slots` |

---

## Маппинг бизнес-правил UI → server

| Правило | Где enforce |
|---------|-------------|
| Per-staff schedule | `booking_staff_schedule` + resolver |
| Blocked slots | `booking_blocked_slots` + EXCLUDE |
| Деактивация услуги | `deactivate_booking_service` |
| История статусов | `booking_history` в RPC |
| Поиск host-листа | `p_query` + trgm indexes |
| Аналитика revenue/avg | `get_booking_analytics` |

---

## Производительность

1. Availability — один round-trip, все busy intervals за день одним запросом.
2. Lists — keyset pagination, limit 50.
3. Search — `pg_trgm` + GIN; не full table scan без `p_query`.
4. Analytics — aggregate в одном RPC; при >100k rows — materialized view (отдельная миграция).
5. `booking_history` append-only, без UPDATE.

---

## Порядок миграций

1. Extensions: `btree_gist`, `pg_trgm`
2. Enums
3. Tables: staff → services → service_staff → schedule_settings → **staff_schedule** → absences → **blocked_slots** → bookings → **history** → **reviews**
4. EXCLUDE constraints (bookings + blocked_slots)
5. Indexes (lists, search, future bookings guard)
6. Helper: `booking_resolve_staff_day_window`
7. RLS
8. RPC: availability, create, status, deactivate service, lists, analytics
9. Grants

---

## Flutter (после backend)

| Mock | Repository |
|------|------------|
| `BookingServicesMockData` | PostgREST + `deactivate_booking_service` |
| `BookingScheduleSettingsStore` | PostgREST settings (+ staff_schedule later) |
| `ClientBookingMockData` | `get_booking_availability` |
| `ClientBookingSubmissionsStore` | `create_booking` |
| `BookingListMockData` | `list_host_bookings_enriched` (+ search) |
| `MyBookingsMockData` | `list_my_bookings_enriched` |
| `BookingAnalyticsMockData` | `get_booking_analytics` |

---

## Backlog (не v1)

### `booking_notifications` — отложено

Таблица и push/in-app — **после** стабилизации core flow. Черновик на будущее:

```sql
-- v2
create type booking_notification_type as enum (
  'booking_created',
  'booking_confirmed',
  'booking_cancelled',
  'booking_completed',
  'booking_reminder'
);

create table booking_notifications (
  id uuid primary key,
  booking_id uuid references bookings(id),
  user_id uuid references profiles(id),
  type booking_notification_type not null,
  title text not null,
  message text not null,
  is_read boolean not null default false,
  created_at timestamptz not null default now()
);
```

Заполнять из trigger на `bookings.status` или из RPC `update_booking_status` — решить при реализации v2.

---

## Anti-patterns

- ❌ JSONB «расписание на месяц»
- ❌ Проверка конфликтов только на Flutter
- ❌ Fake booking для блокировки слота
- ❌ Hard delete bookings
- ❌ Один график на всех без `booking_staff_schedule` fallback chain

---

## Расширения (после v1)

| Фича | Как |
|------|-----|
| Уведомления | `booking_notifications` + cron reminder |
| UI отзывов | `create_booking_review` RPC |
| UI per-staff schedule | CRUD `booking_staff_schedule` |
| Групповые записи | participants sum в availability |
| Оплата | `booking_payments` |
| iCal | view/RPC |

---

## Чеклист приёмки backend

- [ ] Per-staff schedule: мастер с Пн–Пт 09–18 и мастер с Вт–Сб 12–21 — корректные слоты
- [ ] Fallback на account defaults, если у staff нет строк в `booking_staff_schedule`
- [ ] Blocked slot блокирует availability и create_booking
- [ ] EXCLUDE: параллельные create на один слот — один успех
- [ ] `booking_history` пишется на create и status change
- [ ] Деактивация услуги с future pending/confirmed → ошибка
- [ ] `list_host_bookings_enriched(p_query)` находит по имени/phone/username/услуге
- [ ] Analytics: revenue, avg_check, top_staff, breakdown по статусам
- [ ] `booking_reviews` schema создана; RPC отзыва — можно v2
- [ ] RLS: client не видит чужие host bookings
- [ ] Уведомления **не** в scope v1
