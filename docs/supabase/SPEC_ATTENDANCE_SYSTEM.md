# Attendance System — Supabase Spec (ядро v1)

**Процесс:** [`docs/business/attendance.md`](../business/attendance.md)  
**Навигатор:** [`../../supabase/migrations/_attendance/README.md`](../../supabase/migrations/_attendance/README.md)  
**Статус:** ядро (workplace / membership / punch / absences). OT, duty, payroll, analytics, live chat-карточки — следующие срезы.

---

## 1. Overview

| Роль | Кто | Доступ |
|------|-----|--------|
| **Owner (admin)** | `attendance_workplaces.owner_id = auth.uid()` | CRUD компании, invite, absences, settings |
| **Member (worker)** | `attendance_memberships` status `active` | punch, ack, свои данные |
| **Не участник** | нет membership / ownership | **нет** полезного SELECT (0 трафика) |

### Принципы

- UI читает локальный snapshot; сеть — bootstrap / действие
- Invite accept/reject и ack — **только online** (RPC)
- Punch: UI может кэшировать геозону; сервер **всегда** проверяет `ST_DWithin` + membership + ack
- Outbox: `client_punch_id` — идемпотентность
- EN keys в enum; подписи только на Flutter
- Mutations с логикой — `SECURITY DEFINER` RPC; каталог owner — PostgREST где безопасно

---

## 2. Schema

### Enums

- `attendance_membership_status`: `pending`, `active`, `archived`, `declined`
- `attendance_punch_kind`: `clock_in`, `clock_out`, `custom`
- `attendance_absence_kind`: `day_off`, `vacation`, `sick`

### Tables

```
profiles
  ├── attendance_folders (owner)
  └── attendance_workplaces (owner)
        ├── attendance_punch_type_defs (custom)
        ├── attendance_memberships → profiles
        ├── attendance_punches
        └── attendance_absences
```

| Таблица | Назначение |
|--------|------------|
| `attendance_folders` | Группировка компаний в UI admin |
| `attendance_workplaces` | Компания: geo, radius, clock flags, scheduled times, `config_version` |
| `attendance_punch_type_defs` | Свои отметки (label, scheduled time) |
| `attendance_memberships` | Связь profile ↔ workplace + status + `ack_version` |
| `attendance_punches` | Отметки; soft-cancel; `client_punch_id` |
| `attendance_absences` | Оформленное отсутствие (перекрывает пропуск) |

### Key constraints

- Unique `(workplace_id, profile_id)` на memberships
- Unique `(profile_id, client_punch_id)` where client_punch_id not null
- Custom punch: `punch_kind = custom` ⇒ `punch_type_id` not null
- Absences: `end_date >= start_date`

---

## 3. RLS (кратко)

| Таблица | SELECT | INSERT/UPDATE/DELETE |
|--------|--------|---------------------|
| folders / workplaces | owner; member своих workplaces | owner |
| punch_type_defs | owner или member workplace | owner |
| memberships | owner workplace или self | owner (list); accept/reject **RPC only** |
| punches | owner или self | **RPC only** |
| absences | owner или self | owner (PostgREST или RPC) |

---

## 4. RPC

| Function | Returns | Notes |
|----------|---------|--------|
| `attendance_assert_authenticated()` | uuid | helper |
| `attendance_bootstrap_me(p_since?)` | jsonb | workplaces + memberships + punches window + absences + revision |
| `attendance_revision_me()` | text | лёгкая проверка |
| `attendance_create_workplace(...)` | uuid | owner |
| `attendance_update_workplace_settings(...)` | void | bumps `config_version` when geo/types change |
| `attendance_invite_member(p_workplace_id, p_profile_id)` | uuid | → pending |
| `attendance_accept_invite(p_membership_id)` | void | → active; ack = config |
| `attendance_reject_invite(p_membership_id)` | void | → declined |
| `attendance_archive_member(p_membership_id)` | void | → archived |
| `attendance_reinvite_member(p_membership_id)` | void | archived/declined → pending |
| `attendance_ack_config(p_workplace_id)` | void | ack_version = config_version |
| `submit_attendance_punch(...)` | uuid | geofence + shift rules + idempotent client id |
| `cancel_attendance_punch(p_punch_id, p_note?)` | void | tombstone |
| `attendance_upsert_absence(...)` | uuid | owner |

### Error codes (`P01xx`)

| Code | Meaning |
|------|---------|
| `P0003` | not_authenticated |
| `P0101` | invalid_arguments |
| `P0102` | forbidden |
| `P0103` | not_found |
| `P0104` | not_active_member / wrong status |
| `P0105` | needs_ack |
| `P0106` | outside_geofence |
| `P0107` | location_required |
| `P0108` | invalid_punch / shift_state |
| `P0109` | punch_type_invalid |

Idempotent `client_punch_id`: повтор → тот же punch id (без ошибки).

---

## 5. Миграции

| Файл | Назначение |
|------|------------|
| `20260903120000_attendance_schema.sql` | enums, tables, indexes, helpers |
| `20260903120100_attendance_rls_grants.sql` | RLS + GRANT |
| `20260903120200_attendance_rpc.sql` | RPC |

---

## 6. Вне ядра (следующие срезы)

- overtime approve pipeline  
- duty roster  
- payroll rules / analytics aggregates  
- timesheet export RPC  
- live chat message kinds для invite/rules cards  
- group chat auto-create on workplace  

## Секреты

Нет.  
