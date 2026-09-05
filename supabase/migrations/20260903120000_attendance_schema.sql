-- Attendance module (core): schema, indexes, helpers.
-- Spec: docs/supabase/SPEC_ATTENDANCE_SYSTEM.md | Navigator: migrations/_attendance/README.md

create extension if not exists postgis;

-- --------------------------------------------------------------------------- enums
do $$ begin
  create type public.attendance_membership_status as enum (
    'pending',
    'active',
    'archived',
    'declined'
  );
exception
  when duplicate_object then null;
end $$;

do $$ begin
  create type public.attendance_punch_kind as enum (
    'clock_in',
    'clock_out',
    'custom'
  );
exception
  when duplicate_object then null;
end $$;

do $$ begin
  create type public.attendance_absence_kind as enum (
    'day_off',
    'vacation',
    'sick'
  );
exception
  when duplicate_object then null;
end $$;

-- --------------------------------------------------------------------------- updated_at helper
create or replace function public.attendance_set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

-- --------------------------------------------------------------------------- attendance_folders
create table if not exists public.attendance_folders (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.profiles (id) on delete cascade,
  name text not null constraint attendance_folders_name_not_blank check (char_length(trim(name)) > 0),
  sort_order int not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table public.attendance_folders is
  'Папки для группировки компаний посещаемости (UI admin).';

create index if not exists attendance_folders_owner_idx
  on public.attendance_folders (owner_id, sort_order);

drop trigger if exists trg_attendance_folders_set_updated_at on public.attendance_folders;
create trigger trg_attendance_folders_set_updated_at
  before update on public.attendance_folders
  for each row
  execute function public.attendance_set_updated_at();

-- --------------------------------------------------------------------------- attendance_workplaces
create table if not exists public.attendance_workplaces (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.profiles (id) on delete cascade,
  folder_id uuid references public.attendance_folders (id) on delete set null,
  name text not null constraint attendance_workplaces_name_not_blank check (char_length(trim(name)) > 0),
  location geography(point, 4326),
  geofence_radius_m int not null default 150
    constraint attendance_workplaces_radius_positive check (geofence_radius_m > 0 and geofence_radius_m <= 5000),
  clock_in_enabled boolean not null default true,
  clock_out_enabled boolean not null default true,
  clock_in_scheduled time,
  clock_out_scheduled time,
  config_version int not null default 1 constraint attendance_workplaces_config_positive check (config_version >= 1),
  timezone text not null default 'Asia/Almaty',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table public.attendance_workplaces is
  'Компания посещаемости: геозона, типы отметок (флаги), config_version для ack правил.';

create index if not exists attendance_workplaces_owner_idx
  on public.attendance_workplaces (owner_id, created_at desc);

create index if not exists attendance_workplaces_folder_idx
  on public.attendance_workplaces (folder_id)
  where folder_id is not null;

create index if not exists attendance_workplaces_location_gix
  on public.attendance_workplaces using gist (location);

drop trigger if exists trg_attendance_workplaces_set_updated_at on public.attendance_workplaces;
create trigger trg_attendance_workplaces_set_updated_at
  before update on public.attendance_workplaces
  for each row
  execute function public.attendance_set_updated_at();

-- --------------------------------------------------------------------------- attendance_punch_type_defs
create table if not exists public.attendance_punch_type_defs (
  id uuid primary key default gen_random_uuid(),
  workplace_id uuid not null references public.attendance_workplaces (id) on delete cascade,
  label text not null constraint attendance_punch_type_label_not_blank check (char_length(trim(label)) > 0),
  scheduled_time time,
  sort_order int not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table public.attendance_punch_type_defs is
  'Свои типы отметок компании (обед и т.п.). System clock_in/out — флаги на workplace.';

create index if not exists attendance_punch_type_defs_workplace_idx
  on public.attendance_punch_type_defs (workplace_id, sort_order)
  where is_active = true;

drop trigger if exists trg_attendance_punch_type_defs_set_updated_at on public.attendance_punch_type_defs;
create trigger trg_attendance_punch_type_defs_set_updated_at
  before update on public.attendance_punch_type_defs
  for each row
  execute function public.attendance_set_updated_at();

-- --------------------------------------------------------------------------- attendance_memberships
create table if not exists public.attendance_memberships (
  id uuid primary key default gen_random_uuid(),
  workplace_id uuid not null references public.attendance_workplaces (id) on delete cascade,
  profile_id uuid not null references public.profiles (id) on delete cascade,
  status public.attendance_membership_status not null default 'pending',
  ack_version int not null default 0 constraint attendance_memberships_ack_nonneg check (ack_version >= 0),
  invited_by uuid references public.profiles (id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint attendance_memberships_workplace_profile_uidx unique (workplace_id, profile_id)
);

comment on table public.attendance_memberships is
  'Связь аккаунта с компанией: pending → active | declined; archive / reinvite.';

create index if not exists attendance_memberships_profile_status_idx
  on public.attendance_memberships (profile_id, status);

create index if not exists attendance_memberships_workplace_status_idx
  on public.attendance_memberships (workplace_id, status);

drop trigger if exists trg_attendance_memberships_set_updated_at on public.attendance_memberships;
create trigger trg_attendance_memberships_set_updated_at
  before update on public.attendance_memberships
  for each row
  execute function public.attendance_set_updated_at();

-- --------------------------------------------------------------------------- attendance_punches
create table if not exists public.attendance_punches (
  id uuid primary key default gen_random_uuid(),
  workplace_id uuid not null references public.attendance_workplaces (id) on delete cascade,
  membership_id uuid not null references public.attendance_memberships (id) on delete cascade,
  profile_id uuid not null references public.profiles (id) on delete cascade,
  punch_kind public.attendance_punch_kind not null,
  punch_type_id uuid references public.attendance_punch_type_defs (id) on delete set null,
  punched_at timestamptz not null default now(),
  client_punch_id text,
  cancelled_at timestamptz,
  cancel_note text,
  created_at timestamptz not null default now(),
  constraint attendance_punches_custom_type_check check (
    (punch_kind = 'custom'::public.attendance_punch_kind and punch_type_id is not null)
    or (punch_kind <> 'custom'::public.attendance_punch_kind and punch_type_id is null)
  ),
  constraint attendance_punches_cancel_note_len check (
    cancel_note is null or char_length(cancel_note) <= 500
  )
);

comment on table public.attendance_punches is
  'Отметки работников. Cancel = tombstone (cancelled_at). client_punch_id для outbox.';

create unique index if not exists attendance_punches_client_id_uidx
  on public.attendance_punches (profile_id, client_punch_id)
  where client_punch_id is not null;

create index if not exists attendance_punches_workplace_at_idx
  on public.attendance_punches (workplace_id, punched_at desc);

create index if not exists attendance_punches_profile_at_idx
  on public.attendance_punches (profile_id, punched_at desc);

create index if not exists attendance_punches_membership_at_idx
  on public.attendance_punches (membership_id, punched_at desc);

-- --------------------------------------------------------------------------- attendance_absences
create table if not exists public.attendance_absences (
  id uuid primary key default gen_random_uuid(),
  workplace_id uuid not null references public.attendance_workplaces (id) on delete cascade,
  profile_id uuid not null references public.profiles (id) on delete cascade,
  kind public.attendance_absence_kind not null,
  start_date date not null,
  end_date date not null,
  note text,
  created_by uuid references public.profiles (id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint attendance_absences_range_valid check (end_date >= start_date),
  constraint attendance_absences_note_len check (note is null or char_length(note) <= 500)
);

comment on table public.attendance_absences is
  'Оформленное отсутствие: всегда перекрывает пропуск в аналитике/ЗП (продукт).';

create index if not exists attendance_absences_workplace_range_idx
  on public.attendance_absences (workplace_id, start_date, end_date);

create index if not exists attendance_absences_profile_range_idx
  on public.attendance_absences (profile_id, start_date, end_date);

drop trigger if exists trg_attendance_absences_set_updated_at on public.attendance_absences;
create trigger trg_attendance_absences_set_updated_at
  before update on public.attendance_absences
  for each row
  execute function public.attendance_set_updated_at();

-- --------------------------------------------------------------------------- helpers
create or replace function public.attendance_is_workplace_owner(p_workplace_id uuid, p_uid uuid default auth.uid())
returns boolean
language sql
stable
security definer
set search_path = public
set row_security to off
as $$
  select exists (
    select 1
    from public.attendance_workplaces w
    where w.id = p_workplace_id
      and w.owner_id = p_uid
  );
$$;

create or replace function public.attendance_is_active_member(p_workplace_id uuid, p_uid uuid default auth.uid())
returns boolean
language sql
stable
security definer
set search_path = public
set row_security to off
as $$
  select exists (
    select 1
    from public.attendance_memberships m
    where m.workplace_id = p_workplace_id
      and m.profile_id = p_uid
      and m.status = 'active'::public.attendance_membership_status
  );
$$;

create or replace function public.attendance_can_view_workplace(p_workplace_id uuid, p_uid uuid default auth.uid())
returns boolean
language sql
stable
security definer
set search_path = public
set row_security to off
as $$
  select
    public.attendance_is_workplace_owner(p_workplace_id, p_uid)
    or exists (
      select 1
      from public.attendance_memberships m
      where m.workplace_id = p_workplace_id
        and m.profile_id = p_uid
        and m.status in (
          'active'::public.attendance_membership_status,
          'pending'::public.attendance_membership_status
        )
    );
$$;

create or replace function public.attendance_shift_is_open(p_membership_id uuid)
returns boolean
language plpgsql
stable
security definer
set search_path = public
set row_security to off
as $$
declare
  v_kind public.attendance_punch_kind;
begin
  select p.punch_kind into v_kind
  from public.attendance_punches p
  where p.membership_id = p_membership_id
    and p.cancelled_at is null
    and p.punch_kind in (
      'clock_in'::public.attendance_punch_kind,
      'clock_out'::public.attendance_punch_kind
    )
  order by p.punched_at desc
  limit 1;

  return coalesce(v_kind = 'clock_in'::public.attendance_punch_kind, false);
end;
$$;
