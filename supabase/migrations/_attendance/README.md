## Attendance (посещаемость)

Миграции **не переносить** из корня `supabase/migrations/` — Supabase применяет только файлы по timestamp в корне. Эта папка — навигатор по домену **посещаемость / attendance**.

**Спека:** [`../../docs/supabase/SPEC_ATTENDANCE_SYSTEM.md`](../../docs/supabase/SPEC_ATTENDANCE_SYSTEM.md)  
**Процесс:** [`../../docs/business/attendance.md`](../../docs/business/attendance.md)

### Идея данных

- **Owner** управляет компаниями (workplaces), геозоной, типами отметок, invite, отсутствиями.
- **Member** после Accept — punch / ack правил; данные через bootstrap + RPC.
- Не участник — нет полезного SELECT (0 трафика).

### Миграции по порядку

| Файл | Назначение |
|------|------------|
| `../20260903120000_attendance_schema.sql` | Enums, tables, PostGIS location, indexes, `attendance_set_updated_at` |
| `../20260903120100_attendance_rls_grants.sql` | RLS + GRANT |
| `../20260903120200_attendance_rpc.sql` | bootstrap, invite, ack, punch, cancel, absence |

### Таблицы

| Таблица | Назначение |
|--------|------------|
| `attendance_folders` | Папки admin |
| `attendance_workplaces` | Компании + geo + config_version |
| `attendance_punch_type_defs` | Свои типы отметок |
| `attendance_memberships` | pending/active/archived/declined |
| `attendance_punches` | Отметки + cancel + client_punch_id |
| `attendance_absences` | day_off / vacation / sick |

### RPC (контракт)

- `attendance_bootstrap_me` / `attendance_revision_me`
- `attendance_create_workplace` / `attendance_update_workplace_settings`
- `attendance_invite_member` / `accept` / `reject` / `archive` / `reinvite`
- `attendance_ack_config`
- `submit_attendance_punch` / `cancel_attendance_punch`
- `attendance_upsert_absence`

### Вне ядра v1

Overtime, duty, payroll, analytics, live chat cards — отдельные миграции позже.
