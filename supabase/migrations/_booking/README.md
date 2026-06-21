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
| `booking_reviews` | Отзывы (schema v1; RPC/UI — позже) |

### Защита от double-booking

```sql
EXCLUDE USING gist (
  staff_id WITH =,
  tstzrange(starts_at, ends_at, '[)') WITH &&
)
WHERE (status IN ('pending', 'confirmed'));
```

Тот же паттерн на `booking_blocked_slots`.

### RPC (контракт)

#### `create_booking(host_id, service_id, staff_id, starts_at, participants?, notes?) → uuid`

Единственная точка создания записи. Status = `pending`. Пишет `booking_history`.

#### `get_booking_availability(host_id, service_id, staff_id, day) → jsonb`

Слоты на день. Status слота: `available` | `my_conflict` | `host_busy`.

#### `list_host_bookings_enriched(from, to, query?, cursor?, limit?) → setof jsonb`

Входящие записи host. Keyset cursor: `{"starts_at","id"}`. Поиск по имени/phone/username/услуге.

#### `list_my_bookings_enriched(from, to, cursor?, limit?) → setof jsonb`

Записи клиента.

#### `update_booking_status(booking_id, status) → void`

Переходы pending→confirmed→completed; cancel — host или client (до начала).

#### `deactivate_booking_service(service_id) → void`

`is_active = false` только если нет future pending/confirmed.

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

- `booking_notifications` — in-app/push при смене статуса
- `create_booking_review` RPC + UI отзывов
