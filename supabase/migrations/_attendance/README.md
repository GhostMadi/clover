## Attendance (посещаемость)

Миграции **не переносить** из корня `supabase/migrations/` — Supabase применяет только файлы по timestamp в корне. Эта папка — навигатор по домену **посещаемость / attendance**.

**Спека:** [`../../docs/supabase/SPEC_ATTENDANCE_SYSTEM.md`](../../docs/supabase/SPEC_ATTENDANCE_SYSTEM.md)  
**Процесс:** [`../../docs/business/attendance.md`](../../docs/business/attendance.md)

### Идея данных

- **Owner** управляет компаниями (workplaces), геозоной, типами отметок, invite, отсутствиями, payroll/duty/salary, approve OT.
- **Member** после Accept — punch / ack правил / заявка OT; данные через bootstrap + RPC.
- Не участник — нет полезного SELECT (0 трафика).

### Миграции по порядку

| Файл | Назначение |
|------|------------|
| `../20260903120000_attendance_schema.sql` | Enums, tables, PostGIS location, indexes, `attendance_set_updated_at` |
| `../20260903120100_attendance_rls_grants.sql` | RLS + GRANT |
| `../20260903120200_attendance_rpc.sql` | bootstrap, invite, ack, punch, cancel, absence |
| `../20260905130000_attendance_payroll_duty_ot.sql` | payroll/duty jsonb, base salary, OT + RPC |
| `../20260905200000_attendance_chat_push_analytics_correction.sql` | group chat, cards, notify/push_outbox, analytics/timesheet, correction |
| `../20260905210000_attendance_chat_card_kinds.sql` | enum kinds + `chat_message_attendance_cards` |
| `../20260905210100_attendance_rich_chat_reinvite_corrections_list.sql` | rich cards, reinvite parity, list corrections, enriched payload |
| `../20260906020000_booking_push_client_reschedule_attendance_duty_folders.sql` | duty_only_punch + folders bootstrap |
| `../20260906130000_booking_attendance_prod_ready.sql` | Atomic punch types, server payroll preview |
| `../20260908194706_attendance_tag_powers_impl.sql` | Теги `attendance` / `attendanceWork`; гейты create/invite/update/punch; bootstrap `has_attendance_work_tag` |

### Таблицы

| Таблица | Назначение |
|--------|------------|
| `attendance_folders` | Папки admin |
| `attendance_workplaces` | Компании + geo + config_version + payroll_rules + duty_roster |
| `attendance_punch_type_defs` | Свои типы отметок |
| `attendance_memberships` | pending/active/archived/declined + base_salary_tenge |
| `attendance_punches` | Отметки + cancel + client_punch_id |
| `attendance_absences` | day_off / vacation / sick |
| `attendance_overtime_entries` | OT заявки + client_request_id |
| `attendance_punch_correction_requests` | запросы на правку punch |
| `chat_message_attendance_cards` | ref invite/rules карточек в чате |

### RPC (контракт)

- `attendance_bootstrap_me` / `attendance_revision_me`
- `attendance_create_workplace` / `attendance_update_workplace_settings`
- `attendance_update_payroll_settings` / `attendance_update_duty_roster` / `attendance_set_member_base_salary`
- `attendance_upsert_overtime` / `attendance_set_overtime_status`
- `attendance_invite_member` / `accept` / `reject` / `archive` / `reinvite` (+ DM card/notify)
- `attendance_ack_config`
- `submit_attendance_punch` / `cancel_attendance_punch`
- `attendance_upsert_absence`
- `attendance_list_corrections` / `attendance_request_punch_correction` / `attendance_resolve_punch_correction`

### Вне ядра

FCM drain: Edge `drain_push_outbox` (+ secrets/cron). `duty_only_punch` — shipped (колонка + RPC).

Audit: `../20260911185500_attendance_audit_rls_payroll_keys.sql` — workplaces/memberships DML только через RPC; payroll preview EN keys.
