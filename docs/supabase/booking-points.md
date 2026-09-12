# SPEC: booking_points

**Продукт:** [booking-points.md](../business/booking-points.md)

## Таблица `booking_points`

| Колонка | Тип | Примечание |
|---------|-----|------------|
| id | uuid PK | |
| host_id | uuid → profiles | хозяин |
| name | text | свободное имя |
| created_at | timestamptz | |
| archived_at | timestamptz nullable | мягкий архив |

RLS: select/insert/update — `host_id = auth.uid()`.

## `booking_services.point_id`

FK → `booking_points`, nullable на переход; backfill на точку «Основная» на host.

## `booking_schedule_settings`

PK = `point_id` (одна строка настроек на точку). `host_id` — для RLS.

Триггер на `booking_points` insert → дефолтная строка настроек.

Хелперы: `booking_schedule_settings_for_point` / `_for_service` / `_for_host` (первая точка).

## RPC

- `booking_ensure_default_point()` → uuid точки (создаёт «Основная», если нет).
- `booking_default_point_id(host)` → uuid первой активной точки.
- CRUD точки: через table API + RLS (достаточно для веба).
- `replace_booking_staff_absences(p_point_id, p_absences)` — отсутствия **только** этой точки.
- `get_booking_analytics(..., p_point_id?)` — опциональный фильтр через `booking_services.point_id`.

## Absences / blocked slots

| Таблица | Scope |
|---------|--------|
| `booking_staff_absences.point_id` | NOT NULL → точка |
| `booking_blocked_slots.point_id` | NOT NULL; EXCLUDE overlap per `(staff_id, point_id)` |

Availability / create / reschedule учитывают block/absence только для `service.point_id`.
