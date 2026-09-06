# Attendance System — Supabase Spec (ядро v1.1)

**Процесс:** [`docs/business/attendance.md`](../business/attendance.md)  
**Навигатор:** [`../../supabase/migrations/_attendance/README.md`](../../supabase/migrations/_attendance/README.md)  
**Статус:** ядро v1.5 — workplace / membership / punch / absences / payroll preview / duty (`duty_only_punch`) / OT + folders + rich chat / push_outbox / analytics+timesheet / corrections / replace punch types. FCM drain: Edge `drain_push_outbox` (cron/secrets — ops).

---

## 1. Overview

| Роль | Кто | Доступ |
|------|-----|--------|
| **Owner (admin)** | `attendance_workplaces.owner_id = auth.uid()` | CRUD компании, invite, absences, settings, payroll/duty/salary, approve OT |
| **Member (worker)** | `attendance_memberships` status `active` | punch, ack, свои данные, заявка OT |
| **Не участник** | нет membership / ownership | **нет** полезного SELECT (0 трафика) |

### Принципы

- UI читает локальный snapshot; сеть — bootstrap / действие
- Invite accept/reject и ack — **только online** (RPC), без outbox
- Punch / absences / payroll / duty / OT: при сетевом сбое → **outbox** + optimistic UI
- Punch: сервер **всегда** проверяет `ST_DWithin` + membership + ack
- Outbox идемпотентность: `client_punch_id`, `client_request_id` (OT)
- Payroll / duty **не** бампят `config_version` (ack остаётся для geo/types)
- EN keys в enum; подписи только на Flutter
- Mutations с логикой — `SECURITY DEFINER` RPC

---

## 2. Schema

### Enums

- `attendance_membership_status`: `pending`, `active`, `archived`, `declined`
- `attendance_punch_kind`: `clock_in`, `clock_out`, `custom`
- `attendance_absence_kind`: `day_off`, `vacation`, `sick`
- `attendance_overtime_status`: `pending`, `approved`, `rejected`

### Tables

```
profiles
  ├── attendance_folders (owner)
  └── attendance_workplaces (owner)
        ├── attendance_punch_type_defs (custom)
        ├── attendance_memberships → profiles (+ base_salary_tenge)
        ├── attendance_punches
        ├── attendance_absences
        └── attendance_overtime_entries
```

| Таблица | Назначение |
|--------|------------|
| `attendance_folders` | Группировка компаний в UI admin |
| `attendance_workplaces` | Компания: geo, radius, clock flags, `payroll_rules` jsonb, `duty_roster` jsonb, `duty_only_punch`, `config_version` |
| `attendance_punch_type_defs` | Свои отметки (label, scheduled time) |
| `attendance_memberships` | Связь profile ↔ workplace + status + `ack_version` + `base_salary_tenge` |
| `attendance_punches` | Отметки; soft-cancel; `client_punch_id` |
| `attendance_absences` | Оформленное отсутствие (перекрывает пропуск) |
| `attendance_overtime_entries` | Заявки OT; `client_request_id`; status pipeline |

### Key constraints

- Unique `(workplace_id, profile_id)` на memberships
- Unique `(profile_id, client_punch_id)` where client_punch_id not null
- Unique `(profile_id, client_request_id)` where client_request_id not null (OT)
- Custom punch: `punch_kind = custom` ⇒ `punch_type_id` not null
- Absences: `end_date >= start_date`

---

## 3. RLS (кратко)

| Таблица | SELECT | INSERT/UPDATE/DELETE |
|--------|--------|---------------------|
| folders / workplaces | owner; member своих workplaces | owner |
| punch_type_defs | owner или member workplace | owner |
| memberships | owner workplace или self | owner (list); accept/reject **RPC only**; salary via RPC |
| punches | owner или self | **RPC only** |
| absences | owner или self | owner (PostgREST или RPC) |
| overtime_entries | owner или self | **RPC only** |

---

## 4. RPC

| Function | Returns | Notes |
|----------|---------|--------|
| `attendance_assert_authenticated()` | uuid | helper |
| `attendance_bootstrap_me(p_since?)` | jsonb | folders + workplaces (+ payroll/duty/duty_only) + memberships (+ salary) + punches + absences + overtime + revision |
| `attendance_set_duty_only_punch(p_workplace_id, p_duty_only_punch)` | void | owner; hard gate on punch when true |
| `attendance_create_folder` / `attendance_set_workplace_folder` | uuid / void | admin folders |
| `attendance_revision_me()` | text | лёгкая проверка |
| `attendance_create_workplace(...)` | uuid | owner |
| `attendance_update_workplace_settings(...)` | void | bumps `config_version` when geo/types change |
| `attendance_update_payroll_settings(p_workplace_id, p_payroll_rules)` | void | owner; **no** config bump |
| `attendance_update_duty_roster(p_workplace_id, p_duty_roster)` | void | owner; **no** config bump |
| `attendance_set_member_base_salary(p_workplace_id, p_profile_id, p_salary)` | void | owner |
| `attendance_upsert_overtime(...)` | uuid | member/owner create pending; idempotent `client_request_id` |
| `attendance_set_overtime_status(p_entry_id, p_status)` | void | owner; pending → approved\|rejected |
| `attendance_invite_member(p_workplace_id, p_profile_id)` | uuid | → pending |
| `attendance_accept_invite(p_membership_id)` | void | → active; ack = config |
| `attendance_reject_invite(p_membership_id)` | void | → declined |
| `attendance_archive_member(p_membership_id)` | void | → archived |
| `attendance_reinvite_member(p_membership_id)` | void | archived/declined → pending + DM card + notify |
| `attendance_list_corrections(p_workplace_id, p_status?)` | jsonb | owner: all; member: own |
| `attendance_request_punch_correction(...)` | uuid | worker |
| `attendance_resolve_punch_correction(...)` | void | owner approve/reject |
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

Idempotent `client_punch_id` / `client_request_id`: повтор → тот же id (без ошибки).

---

## 5. Миграции

| Файл | Назначение |
|------|------------|
| `20260903120000_attendance_schema.sql` | enums, tables, indexes, helpers |
| `20260903120100_attendance_rls_grants.sql` | RLS + GRANT |
| `20260903120200_attendance_rpc.sql` | RPC ядра |
| `20260905130000_attendance_payroll_duty_ot.sql` | payroll/duty jsonb, base salary, OT table + RPC + bootstrap |
| `20260905200000_attendance_chat_push_analytics_correction.sql` | group chat, invite/rules cards, notifications+push_outbox, analytics/timesheet RPC, punch correction |
| `20260905210000_attendance_chat_card_kinds.sql` | enum `attendance_invite`/`attendance_rules` + `chat_message_attendance_cards` |
| `20260905210100_attendance_rich_chat_reinvite_corrections_list.sql` | rich post card, reinvite DM+notify, list corrections, enriched `attendance_card` |
| `20260906020000_booking_push_client_reschedule_attendance_duty_folders.sql` | `duty_only_punch` + folders bootstrap |
| `20260906130000_booking_attendance_prod_ready.sql` | `attendance_replace_punch_types`, `attendance_payroll_preview`, availability `p_exclude_booking_id`, `service_id` in booking lists |

---

## 6. Вне ядра (следующие срезы)

- расписание cron для `drain_push_outbox` на проде (после secrets)
- ARB / полная l10n приложения

## Секреты

Нет.
