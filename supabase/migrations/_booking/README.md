## Booking (онлайн-запись)

Миграции **не переносить** из корня `supabase/migrations/` — Supabase применяет только файлы по timestamp в корне. Эта папка — навигатор по домену **запись / booking**.

**Полная спека:** [`../../SPEC_BOOKING_SYSTEM.md`](../../SPEC_BOOKING_SYSTEM.md)  
**Исходное ТЗ (rev.2):** [`../../docs/booking_backend_spec.md`](../../docs/booking_backend_spec.md)

### Идея данных

- **Host** (владелец аккаунта с тегом `booking`) управляет услугами, мастерами, расписанием.
- **Client** записывается через RPC — слоты считаются на сервере.
- **Staff** (`booking_staff`) — мастера; опционально `profile_id` для будущей привязки к аккаунту.
- **Снапшоты** на `bookings` — цена/название услуги не «ломают» историю при редактировании каталога.

### Включение фичи

Тег аккаунта `booking` в `marker_tags` (group `account`). Проверка: `booking_host_has_booking_tag(host_id)`.

Миграция тега: `../20260725120000_marker_tag_booking.sql`

### Миграции по порядку

| Файл | Назначение |
|------|------------|
| `../20260726120000_booking_schema.sql` | Extensions `btree_gist`, `pg_trgm`; enums; таблицы; EXCLUDE constraints; helpers (`booking_resolve_staff_day_window`, …). |
| `../20260726120100_booking_rls_grants.sql` | RLS policies + GRANT для authenticated. |
| `../20260726120200_booking_rpc.sql` | RPC: create, availability, lists, status, deactivate service, analytics. |
| `../20260726120300_booking_visit_status.sql` | Enum: `client_arrived`, `in_progress`. |
| `../20260726120301_booking_visit_status_functions.sql` | `booking_status_blocks_slot()`; visit-flow в `update_booking_status`. |
| `../20260730200000_booking_no_show_enum.sql` | Enum `no_show`, `auto_closed`, колонка `no_show_at`. |
| `../20260730200001_booking_host_freedom.sql` | Свобода Host (cancel/complete/no_show), auto-close cron, `reschedule_booking`. |
| `../20260830160000_booking_create_confirmed_instant.sql` | `create_booking` → сразу `confirmed` + `confirmed_at`. |
| `../20260830170000_posts_booking_service_link.sql` | `posts.booking_service_id`, `set_post_booking_service`, enriched `booking_service` в `get_post_enriched`. |

### Таблицы

| Таблица | Назначение |
|---------|------------|
| `booking_staff` | Мастера host-аккаунта |
| `booking_services` | Услуги |
| `booking_service_staff` | M2M: кто может оказать услугу |
| `booking_schedule_settings` | Горизонт, шаг слотов, дефолтные часы (fallback) |
| `booking_staff_schedule` | Персональный график мастера по дням недели |
| `booking_staff_absences` | Отпуск / больничный (диапазон дат) |
| `booking_blocked_slots` | Ручная блокировка времени (обед, совещание) |
| `bookings` | Записи клиентов + снапшоты услуги |
| `booking_history` | Аудит created / status_changed |
| `booking_history` | Аудит смены статуса |

### Защита от double-booking

```sql
WHERE (public.booking_status_blocks_slot(status));
```

Статусы, блокирующие слот: `pending`, `confirmed`, `client_arrived`, `in_progress` — см. `booking_status_blocks_slot()`.

Терминальные (слот свободен): `completed`, `cancelled`, `no_show`.

**Host:** может отменить из любого активного статуса; `completed` — bulk-complete с автозаполнением timestamps; `no_show` — из `pending`/`confirmed` после `starts_at`.

**Client:** отмена только `pending`/`confirmed` до `starts_at - client_cancel_hours_before` (настройка host-а).

**Auto-close:** cron `booking_auto_close_stale_visits` — только `pending`/`confirmed` через N часов после `ends_at` → **`no_show`**. **`completed` никогда автоматом** (только host). `auto_close_hours_after_visit = 0` → выкл.

Тот же паттерн на `booking_blocked_slots`.

### RPC (контракт)

#### `create_booking(host_id, service_id, staff_id, starts_at, participants?, notes?) → uuid`

Единственная точка создания записи. Status = **`confirmed`** (instant booking), `confirmed_at = now()`. Пишет `booking_history` с `new_status = confirmed`. Legacy `pending` (если есть) — во вкладке «Предстоящие», не отдельным табом.

#### `get_booking_availability(host_id, service_id, staff_id, day) → jsonb`

Слоты на день. Status слота: `available` | `my_conflict` | `host_busy`.

#### `list_host_bookings_enriched(from, to, query?, cursor?, limit?) → setof jsonb`

Входящие записи host. Keyset cursor: `{"starts_at","id"}`. Поиск по имени/phone/username/услуге.

#### `list_my_bookings_enriched(from, to, cursor?, limit?) → setof jsonb`

Записи клиента.

#### `update_booking_status(booking_id, status) → void`

Переходы: pending→confirmed→client_arrived→in_progress→completed; cancel — host или client (ограничения по статусу в RPC).

#### `deactivate_booking_service(service_id) → void`

`is_active = false` только если нет future записей со статусом из `booking_status_blocks_slot`.

#### `get_booking_analytics(from, to, staff_id?) → jsonb`

total/pending/confirmed/completed/cancelled, revenue, avg_check, popular_services, top_staff.

### PostgREST (host CRUD)

- `booking_staff`, `booking_services`, `booking_service_staff`
- `booking_schedule_settings`, `booking_staff_schedule`
- `booking_staff_absences`, `booking_blocked_slots`

Клиент **не** пишет в `bookings` напрямую.

### График: account vs staff

1. Есть строка `booking_staff_schedule` для (staff, weekday) → используем её.
2. Иначе fallback: `rest_weekdays` + `default_work_*` из `booking_schedule_settings`.
3. Absence на дату → день недоступен для мастера.

v1 UI настроек пишет только account-level — backend уже поддерживает per-staff.

### Связь с Flutter

| Mock | Backend |
|------|---------|
| `BookingServicesMockData` | PostgREST + `deactivate_booking_service` |
| `BookingScheduleSettingsStore` | PostgREST settings / staff_schedule |
| `ClientBookingMockData` | `get_booking_availability` |
| `ClientBookingSubmissionsStore` | `create_booking` |
| `BookingListMockData` | `list_host_bookings_enriched` |
| `MyBookingsMockData` | `list_my_bookings_enriched` |
| `BookingAnalyticsMockData` | `get_booking_analytics` |

Экраны: `lib/feature/booking/`

### Проверка после деплоя

```bash
psql "$DATABASE_URL" -f supabase/scripts/verify_booking_rpcs.sql
```

### Backlog (не v1)

- Push / client reminder — in-app v1 уже в `notifications`; см. [SPEC_IN_APP_NOTIFICATIONS.md](../../docs/supabase/SPEC_IN_APP_NOTIFICATIONS.md)
- `create_booking_review` / UI отзывов — **не делаем** (таблица снята)
