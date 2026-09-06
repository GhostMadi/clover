-- Attendance v1.1: payroll rules, duty roster, member base salary, overtime.
-- Process: docs/business/attendance.md · SPEC_ATTENDANCE_SYSTEM.md

-- --------------------------------------------------------------------------- schema
do $$ begin
  create type public.attendance_overtime_status as enum ('pending', 'approved', 'rejected');
exception when duplicate_object then null;
end $$;

alter table public.attendance_workplaces
  add column if not exists payroll_rules jsonb not null default '{}'::jsonb,
  add column if not exists duty_roster jsonb not null default '{}'::jsonb;

comment on column public.attendance_workplaces.payroll_rules is
  'Правила ЗП (флаги + ставки). EN keys; UI labels на клиенте.';
comment on column public.attendance_workplaces.duty_roster is
  'Очередь дежурств: worker_ids, working_weekdays, start_date.';

alter table public.attendance_memberships
  add column if not exists base_salary_tenge int not null default 0
    constraint attendance_memberships_salary_nonneg check (base_salary_tenge >= 0);

comment on column public.attendance_memberships.base_salary_tenge is
  'Оклад работника, ₸ (owner).';

create table if not exists public.attendance_overtime_entries (
  id uuid primary key default gen_random_uuid(),
  workplace_id uuid not null references public.attendance_workplaces (id) on delete cascade,
  profile_id uuid not null references public.profiles (id) on delete cascade,
  work_date date not null,
  hours int not null constraint attendance_overtime_hours_positive check (hours > 0 and hours <= 24),
  status public.attendance_overtime_status not null default 'pending',
  client_request_id text,
  created_by uuid references public.profiles (id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table public.attendance_overtime_entries is
  'Заявки на переработку; в ЗП только approved. client_request_id для outbox.';

create unique index if not exists attendance_overtime_client_id_uidx
  on public.attendance_overtime_entries (profile_id, client_request_id)
  where client_request_id is not null;

create index if not exists attendance_overtime_workplace_date_idx
  on public.attendance_overtime_entries (workplace_id, work_date desc);

create index if not exists attendance_overtime_profile_date_idx
  on public.attendance_overtime_entries (profile_id, work_date desc);

drop trigger if exists trg_attendance_overtime_set_updated_at on public.attendance_overtime_entries;
create trigger trg_attendance_overtime_set_updated_at
  before update on public.attendance_overtime_entries
  for each row
  execute function public.attendance_set_updated_at();

-- --------------------------------------------------------------------------- RLS
alter table public.attendance_overtime_entries enable row level security;

drop policy if exists attendance_overtime_select on public.attendance_overtime_entries;
create policy attendance_overtime_select
  on public.attendance_overtime_entries for select to authenticated
  using (
    profile_id = auth.uid()
    or public.attendance_is_workplace_owner(workplace_id, auth.uid())
  );

-- Writes via SECURITY DEFINER RPC only.
grant select on public.attendance_overtime_entries to authenticated;

-- --------------------------------------------------------------------------- helpers: JSON
create or replace function public.attendance_workplace_to_json(p_w public.attendance_workplaces)
returns jsonb
language sql
stable
as $$
  select jsonb_build_object(
    'id', p_w.id,
    'owner_id', p_w.owner_id,
    'folder_id', p_w.folder_id,
    'name', p_w.name,
    'latitude', case when p_w.location is null then null else st_y(p_w.location::geometry) end,
    'longitude', case when p_w.location is null then null else st_x(p_w.location::geometry) end,
    'geofence_radius_m', p_w.geofence_radius_m,
    'clock_in_enabled', p_w.clock_in_enabled,
    'clock_out_enabled', p_w.clock_out_enabled,
    'clock_in_scheduled', p_w.clock_in_scheduled,
    'clock_out_scheduled', p_w.clock_out_scheduled,
    'config_version', p_w.config_version,
    'timezone', p_w.timezone,
    'payroll_rules', coalesce(p_w.payroll_rules, '{}'::jsonb),
    'duty_roster', coalesce(p_w.duty_roster, '{}'::jsonb),
    'updated_at', p_w.updated_at,
    'is_admin', p_w.owner_id = auth.uid()
  );
$$;

-- --------------------------------------------------------------------------- revision includes overtime
create or replace function public.attendance_revision_me()
returns text
language plpgsql
stable
security definer
set search_path = public
set row_security to off
as $$
declare
  uid uuid;
  v_rev timestamptz;
begin
  uid := public.attendance_assert_authenticated();

  select max(x.ts) into v_rev
  from (
    select w.updated_at as ts
    from public.attendance_workplaces w
    where w.owner_id = uid
       or exists (
         select 1 from public.attendance_memberships m
         where m.workplace_id = w.id and m.profile_id = uid
           and m.status in ('active', 'pending')
       )
    union all
    select m.updated_at
    from public.attendance_memberships m
    where m.profile_id = uid
    union all
    select p.created_at
    from public.attendance_punches p
    where p.profile_id = uid
      and p.punched_at > now() - interval '14 days'
    union all
    select a.updated_at
    from public.attendance_absences a
    where a.profile_id = uid
       or public.attendance_is_workplace_owner(a.workplace_id, uid)
    union all
    select o.updated_at
    from public.attendance_overtime_entries o
    where o.profile_id = uid
       or public.attendance_is_workplace_owner(o.workplace_id, uid)
  ) x;

  return coalesce(v_rev, to_timestamp(0))::text;
end;
$$;

-- --------------------------------------------------------------------------- bootstrap + OT + salary
create or replace function public.attendance_bootstrap_me(
  p_since timestamptz default null
)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
set row_security to off
as $$
declare
  uid uuid;
  v_workplaces jsonb;
  v_memberships jsonb;
  v_types jsonb;
  v_punches jsonb;
  v_absences jsonb;
  v_overtime jsonb;
begin
  uid := public.attendance_assert_authenticated();

  select coalesce(jsonb_agg(public.attendance_workplace_to_json(w) order by w.created_at desc), '[]'::jsonb)
  into v_workplaces
  from public.attendance_workplaces w
  where w.owner_id = uid
     or exists (
       select 1 from public.attendance_memberships m
       where m.workplace_id = w.id
         and m.profile_id = uid
         and m.status in ('active', 'pending')
     );

  select coalesce(jsonb_agg(jsonb_build_object(
      'id', m.id,
      'workplace_id', m.workplace_id,
      'workplace_name', w.name,
      'profile_id', m.profile_id,
      'status', m.status,
      'ack_version', m.ack_version,
      'config_version', w.config_version,
      'needs_ack', m.ack_version < w.config_version,
      'shift_open', public.attendance_shift_is_open(m.id),
      'base_salary_tenge', m.base_salary_tenge,
      'updated_at', m.updated_at
    ) order by m.updated_at desc), '[]'::jsonb)
  into v_memberships
  from public.attendance_memberships m
  join public.attendance_workplaces w on w.id = m.workplace_id
  where m.profile_id = uid
     or w.owner_id = uid;

  select coalesce(jsonb_agg(jsonb_build_object(
      'id', t.id,
      'workplace_id', t.workplace_id,
      'label', t.label,
      'scheduled_time', t.scheduled_time,
      'sort_order', t.sort_order,
      'is_active', t.is_active
    ) order by t.sort_order), '[]'::jsonb)
  into v_types
  from public.attendance_punch_type_defs t
  where t.is_active = true
    and public.attendance_can_view_workplace(t.workplace_id, uid);

  select coalesce(jsonb_agg(jsonb_build_object(
      'id', p.id,
      'workplace_id', p.workplace_id,
      'membership_id', p.membership_id,
      'profile_id', p.profile_id,
      'punch_kind', p.punch_kind,
      'punch_type_id', p.punch_type_id,
      'punched_at', p.punched_at,
      'client_punch_id', p.client_punch_id,
      'cancelled_at', p.cancelled_at,
      'cancel_note', p.cancel_note
    ) order by p.punched_at desc), '[]'::jsonb)
  into v_punches
  from public.attendance_punches p
  where (p.profile_id = uid or public.attendance_is_workplace_owner(p.workplace_id, uid))
    and p.punched_at > coalesce(p_since, now() - interval '45 days');

  select coalesce(jsonb_agg(jsonb_build_object(
      'id', a.id,
      'workplace_id', a.workplace_id,
      'profile_id', a.profile_id,
      'kind', a.kind,
      'start_date', a.start_date,
      'end_date', a.end_date,
      'note', a.note
    ) order by a.start_date desc), '[]'::jsonb)
  into v_absences
  from public.attendance_absences a
  where a.profile_id = uid
     or public.attendance_is_workplace_owner(a.workplace_id, uid);

  select coalesce(jsonb_agg(jsonb_build_object(
      'id', o.id,
      'workplace_id', o.workplace_id,
      'profile_id', o.profile_id,
      'work_date', o.work_date,
      'hours', o.hours,
      'status', o.status,
      'client_request_id', o.client_request_id,
      'created_at', o.created_at
    ) order by o.work_date desc, o.created_at desc), '[]'::jsonb)
  into v_overtime
  from public.attendance_overtime_entries o
  where o.profile_id = uid
     or public.attendance_is_workplace_owner(o.workplace_id, uid);

  return jsonb_build_object(
    'workplaces', v_workplaces,
    'memberships', v_memberships,
    'punch_types', v_types,
    'punches', v_punches,
    'absences', v_absences,
    'overtime_entries', v_overtime,
    'revision', public.attendance_revision_me()
  );
end;
$$;

-- --------------------------------------------------------------------------- update payroll (no config_version bump)
create or replace function public.attendance_update_payroll_settings(
  p_workplace_id uuid,
  p_payroll_rules jsonb
)
returns void
language plpgsql
security definer
set search_path = public
set row_security to off
as $$
declare
  uid uuid;
begin
  uid := public.attendance_assert_authenticated();
  if p_workplace_id is null or p_payroll_rules is null then
    raise exception 'invalid_arguments' using errcode = 'P0101';
  end if;
  if not public.attendance_is_workplace_owner(p_workplace_id, uid) then
    raise exception 'forbidden' using errcode = 'P0102';
  end if;

  update public.attendance_workplaces
  set payroll_rules = p_payroll_rules,
      updated_at = now()
  where id = p_workplace_id;
end;
$$;

-- --------------------------------------------------------------------------- update duty roster
create or replace function public.attendance_update_duty_roster(
  p_workplace_id uuid,
  p_duty_roster jsonb
)
returns void
language plpgsql
security definer
set search_path = public
set row_security to off
as $$
declare
  uid uuid;
begin
  uid := public.attendance_assert_authenticated();
  if p_workplace_id is null or p_duty_roster is null then
    raise exception 'invalid_arguments' using errcode = 'P0101';
  end if;
  if not public.attendance_is_workplace_owner(p_workplace_id, uid) then
    raise exception 'forbidden' using errcode = 'P0102';
  end if;

  update public.attendance_workplaces
  set duty_roster = p_duty_roster,
      updated_at = now()
  where id = p_workplace_id;
end;
$$;

-- --------------------------------------------------------------------------- member base salary
create or replace function public.attendance_set_member_base_salary(
  p_workplace_id uuid,
  p_profile_id uuid,
  p_base_salary_tenge int
)
returns void
language plpgsql
security definer
set search_path = public
set row_security to off
as $$
declare
  uid uuid;
  v_updated int;
begin
  uid := public.attendance_assert_authenticated();
  if p_workplace_id is null or p_profile_id is null or p_base_salary_tenge is null or p_base_salary_tenge < 0 then
    raise exception 'invalid_arguments' using errcode = 'P0101';
  end if;
  if not public.attendance_is_workplace_owner(p_workplace_id, uid) then
    raise exception 'forbidden' using errcode = 'P0102';
  end if;

  update public.attendance_memberships
  set base_salary_tenge = p_base_salary_tenge,
      updated_at = now()
  where workplace_id = p_workplace_id
    and profile_id = p_profile_id
    and status in ('active', 'pending', 'archived');

  get diagnostics v_updated = row_count;
  if v_updated = 0 then
    raise exception 'not_found' using errcode = 'P0103';
  end if;
end;
$$;

-- --------------------------------------------------------------------------- upsert overtime
create or replace function public.attendance_upsert_overtime(
  p_workplace_id uuid,
  p_profile_id uuid,
  p_work_date date,
  p_hours int,
  p_client_request_id text default null
)
returns uuid
language plpgsql
security definer
set search_path = public
set row_security to off
as $$
declare
  uid uuid;
  v_id uuid;
  v_is_owner boolean;
  v_is_self_active boolean;
begin
  uid := public.attendance_assert_authenticated();
  if p_workplace_id is null or p_profile_id is null or p_work_date is null
     or p_hours is null or p_hours <= 0 or p_hours > 24 then
    raise exception 'invalid_arguments' using errcode = 'P0101';
  end if;

  v_is_owner := public.attendance_is_workplace_owner(p_workplace_id, uid);
  v_is_self_active := public.attendance_is_active_member(p_workplace_id, uid)
                      and p_profile_id = uid;

  if not v_is_owner and not v_is_self_active then
    raise exception 'forbidden' using errcode = 'P0102';
  end if;

  if p_client_request_id is not null and length(trim(p_client_request_id)) > 0 then
    select id into v_id
    from public.attendance_overtime_entries
    where profile_id = p_profile_id
      and client_request_id = trim(p_client_request_id);
    if v_id is not null then
      return v_id;
    end if;
  end if;

  insert into public.attendance_overtime_entries (
    workplace_id, profile_id, work_date, hours, status, client_request_id, created_by
  ) values (
    p_workplace_id,
    p_profile_id,
    p_work_date,
    p_hours,
    'pending'::public.attendance_overtime_status,
    nullif(trim(coalesce(p_client_request_id, '')), ''),
    uid
  )
  returning id into v_id;

  return v_id;
end;
$$;

-- --------------------------------------------------------------------------- set overtime status (owner)
create or replace function public.attendance_set_overtime_status(
  p_entry_id uuid,
  p_status text
)
returns void
language plpgsql
security definer
set search_path = public
set row_security to off
as $$
declare
  uid uuid;
  v_row public.attendance_overtime_entries%rowtype;
  v_status public.attendance_overtime_status;
begin
  uid := public.attendance_assert_authenticated();
  if p_entry_id is null or p_status is null then
    raise exception 'invalid_arguments' using errcode = 'P0101';
  end if;

  begin
    v_status := p_status::public.attendance_overtime_status;
  exception when others then
    raise exception 'invalid_arguments' using errcode = 'P0101';
  end;

  if v_status not in (
    'approved'::public.attendance_overtime_status,
    'rejected'::public.attendance_overtime_status
  ) then
    raise exception 'invalid_arguments' using errcode = 'P0101';
  end if;

  select * into v_row from public.attendance_overtime_entries where id = p_entry_id;
  if not found then
    raise exception 'not_found' using errcode = 'P0103';
  end if;
  if not public.attendance_is_workplace_owner(v_row.workplace_id, uid) then
    raise exception 'forbidden' using errcode = 'P0102';
  end if;
  if v_row.status <> 'pending'::public.attendance_overtime_status then
    -- idempotent: already decided
    if v_row.status = v_status then
      return;
    end if;
    raise exception 'invalid_punch' using errcode = 'P0108';
  end if;

  update public.attendance_overtime_entries
  set status = v_status,
      updated_at = now()
  where id = p_entry_id;
end;
$$;

grant execute on function public.attendance_update_payroll_settings(uuid, jsonb) to authenticated;
grant execute on function public.attendance_update_duty_roster(uuid, jsonb) to authenticated;
grant execute on function public.attendance_set_member_base_salary(uuid, uuid, int) to authenticated;
grant execute on function public.attendance_upsert_overtime(uuid, uuid, date, int, text) to authenticated;
grant execute on function public.attendance_set_overtime_status(uuid, text) to authenticated;
