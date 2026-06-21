-- Booking module: schema, indexes, constraints, helpers.
-- Spec: supabase/SPEC_BOOKING_SYSTEM.md | Navigator: migrations/_booking/README.md

create extension if not exists btree_gist;
create extension if not exists pg_trgm;

-- --------------------------------------------------------------------------- enums
do $$ begin
  create type public.booking_status as enum (
    'pending',
    'confirmed',
    'completed',
    'cancelled'
  );
exception
  when duplicate_object then null;
end $$;

do $$ begin
  create type public.booking_horizon_kind as enum (
    'days_ahead',
    'until_date'
  );
exception
  when duplicate_object then null;
end $$;

do $$ begin
  create type public.booking_history_action as enum (
    'created',
    'status_changed',
    'rescheduled'
  );
exception
  when duplicate_object then null;
end $$;

-- --------------------------------------------------------------------------- updated_at helper
create or replace function public.booking_set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

-- --------------------------------------------------------------------------- booking_staff
create table if not exists public.booking_staff (
  id uuid primary key default gen_random_uuid(),
  host_id uuid not null references public.profiles (id) on delete cascade,
  display_name text not null constraint booking_staff_display_name_not_blank check (char_length(trim(display_name)) > 0),
  username text,
  profile_id uuid references public.profiles (id) on delete set null,
  sort_order int not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table public.booking_staff is
  'Исполнители (мастера) host-аккаунта для модуля записи.';

create unique index if not exists booking_staff_host_username_uidx
  on public.booking_staff (host_id, lower(username))
  where username is not null;

create index if not exists booking_staff_host_active_idx
  on public.booking_staff (host_id, is_active, sort_order);

drop trigger if exists trg_booking_staff_set_updated_at on public.booking_staff;
create trigger trg_booking_staff_set_updated_at
  before update on public.booking_staff
  for each row
  execute function public.booking_set_updated_at();

-- --------------------------------------------------------------------------- booking_services
create table if not exists public.booking_services (
  id uuid primary key default gen_random_uuid(),
  host_id uuid not null references public.profiles (id) on delete cascade,
  title text not null constraint booking_services_title_not_blank check (char_length(trim(title)) > 0),
  emoji_text text not null default '💈',
  description text,
  duration_minutes int not null constraint booking_services_duration_positive check (duration_minutes > 0),
  buffer_after_minutes int not null default 0 constraint booking_services_buffer_nonneg check (buffer_after_minutes >= 0),
  price numeric(12, 2) not null default 0 constraint booking_services_price_nonneg check (price >= 0),
  max_participants int not null default 1 constraint booking_services_max_participants_positive check (max_participants >= 1),
  default_staff_id uuid references public.booking_staff (id) on delete set null,
  is_active boolean not null default true,
  sort_order int not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table public.booking_services is
  'Услуги host-аккаунта для онлайн-записи.';

create index if not exists booking_services_host_active_idx
  on public.booking_services (host_id, is_active, sort_order);

drop trigger if exists trg_booking_services_set_updated_at on public.booking_services;
create trigger trg_booking_services_set_updated_at
  before update on public.booking_services
  for each row
  execute function public.booking_set_updated_at();

-- --------------------------------------------------------------------------- booking_service_staff (M2M)
create table if not exists public.booking_service_staff (
  service_id uuid not null references public.booking_services (id) on delete cascade,
  staff_id uuid not null references public.booking_staff (id) on delete cascade,
  primary key (service_id, staff_id)
);

comment on table public.booking_service_staff is
  'Какие мастера могут оказать услугу.';

create index if not exists booking_service_staff_staff_idx
  on public.booking_service_staff (staff_id);

-- --------------------------------------------------------------------------- booking_schedule_settings
create table if not exists public.booking_schedule_settings (
  host_id uuid primary key references public.profiles (id) on delete cascade,
  rest_weekdays int[] not null default '{7}',
  horizon_kind public.booking_horizon_kind not null default 'days_ahead',
  max_booking_days_ahead int not null default 14 constraint booking_schedule_days_ahead_positive check (max_booking_days_ahead >= 1),
  max_booking_until_date date,
  default_work_start_time time not null default '09:00',
  default_work_end_time time not null default '20:00',
  slot_step_minutes int not null default 30 constraint booking_schedule_slot_step_allowed check (slot_step_minutes in (15, 30, 60)),
  timezone text not null default 'Asia/Almaty',
  updated_at timestamptz not null default now(),
  constraint booking_schedule_default_hours_valid check (default_work_end_time > default_work_start_time),
  constraint booking_schedule_until_date_required check (
    horizon_kind = 'days_ahead'::public.booking_horizon_kind
    or max_booking_until_date is not null
  )
);

comment on table public.booking_schedule_settings is
  'Общие настройки записи host: горизонт, шаг слотов, дефолтные часы (fallback для staff без персонального графика).';

drop trigger if exists trg_booking_schedule_settings_set_updated_at on public.booking_schedule_settings;
create trigger trg_booking_schedule_settings_set_updated_at
  before update on public.booking_schedule_settings
  for each row
  execute function public.booking_set_updated_at();

-- --------------------------------------------------------------------------- booking_staff_schedule
create table if not exists public.booking_staff_schedule (
  id uuid primary key default gen_random_uuid(),
  host_id uuid not null references public.profiles (id) on delete cascade,
  staff_id uuid not null references public.booking_staff (id) on delete cascade,
  weekday int not null constraint booking_staff_schedule_weekday_range check (weekday between 1 and 7),
  is_working boolean not null default true,
  work_start_time time,
  work_end_time time,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint booking_staff_schedule_unique_day unique (staff_id, weekday),
  constraint booking_staff_schedule_hours_valid check (
    is_working = false
    or (
      work_start_time is not null
      and work_end_time is not null
      and work_end_time > work_start_time
    )
  )
);

comment on table public.booking_staff_schedule is
  'Персональный график мастера по дням недели (ISO 1=пн … 7=вс).';

create index if not exists booking_staff_schedule_staff_weekday_idx
  on public.booking_staff_schedule (staff_id, weekday);

drop trigger if exists trg_booking_staff_schedule_set_updated_at on public.booking_staff_schedule;
create trigger trg_booking_staff_schedule_set_updated_at
  before update on public.booking_staff_schedule
  for each row
  execute function public.booking_set_updated_at();

-- --------------------------------------------------------------------------- booking_staff_absences
create table if not exists public.booking_staff_absences (
  id uuid primary key default gen_random_uuid(),
  host_id uuid not null references public.profiles (id) on delete cascade,
  staff_id uuid not null references public.booking_staff (id) on delete cascade,
  start_date date not null,
  end_date date not null constraint booking_staff_absences_dates_valid check (end_date >= start_date),
  note text,
  created_at timestamptz not null default now()
);

comment on table public.booking_staff_absences is
  'Отсутствие мастера (отпуск, больничный) — блокирует запись на диапазон дат.';

create index if not exists booking_staff_absences_staff_dates_idx
  on public.booking_staff_absences (staff_id, start_date, end_date);

-- --------------------------------------------------------------------------- booking_blocked_slots
create table if not exists public.booking_blocked_slots (
  id uuid primary key default gen_random_uuid(),
  host_id uuid not null references public.profiles (id) on delete cascade,
  staff_id uuid not null references public.booking_staff (id) on delete cascade,
  starts_at timestamptz not null,
  ends_at timestamptz not null constraint booking_blocked_slots_range_valid check (ends_at > starts_at),
  reason text,
  created_at timestamptz not null default now()
);

comment on table public.booking_blocked_slots is
  'Ручная блокировка времени мастера (обед, совещание) без fake booking.';

create index if not exists booking_blocked_slots_staff_starts_idx
  on public.booking_blocked_slots (staff_id, starts_at);

-- --------------------------------------------------------------------------- bookings
create table if not exists public.bookings (
  id uuid primary key default gen_random_uuid(),
  host_id uuid not null references public.profiles (id) on delete cascade,
  client_id uuid not null references public.profiles (id) on delete restrict,
  service_id uuid not null references public.booking_services (id) on delete restrict,
  staff_id uuid not null references public.booking_staff (id) on delete restrict,
  status public.booking_status not null default 'pending',
  starts_at timestamptz not null,
  ends_at timestamptz not null constraint bookings_range_valid check (ends_at > starts_at),
  service_title text not null,
  service_emoji text not null,
  duration_minutes int not null,
  buffer_after_minutes int not null default 0,
  price numeric(12, 2) not null,
  max_participants int not null default 1,
  participants_count int not null default 1 constraint bookings_participants_positive check (participants_count >= 1),
  client_notes text constraint bookings_client_notes_len check (char_length(coalesce(client_notes, '')) <= 300),
  cancelled_at timestamptz,
  cancelled_by uuid references public.profiles (id) on delete set null,
  completed_at timestamptz,
  confirmed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table public.bookings is
  'Записи клиентов. Снапшоты услуги — для исторической корректности.';

create index if not exists bookings_host_starts_idx
  on public.bookings (host_id, starts_at desc)
  where status <> 'cancelled'::public.booking_status;

create index if not exists bookings_client_starts_idx
  on public.bookings (client_id, starts_at desc)
  where status <> 'cancelled'::public.booking_status;

create index if not exists bookings_staff_starts_idx
  on public.bookings (staff_id, starts_at)
  where status in ('pending'::public.booking_status, 'confirmed'::public.booking_status);

create index if not exists bookings_service_title_trgm_idx
  on public.bookings using gin (service_title gin_trgm_ops);

create index if not exists bookings_service_future_active_idx
  on public.bookings (service_id, starts_at)
  where status in ('pending'::public.booking_status, 'confirmed'::public.booking_status);

drop trigger if exists trg_bookings_set_updated_at on public.bookings;
create trigger trg_bookings_set_updated_at
  before update on public.bookings
  for each row
  execute function public.booking_set_updated_at();

-- --------------------------------------------------------------------------- booking_history
create table if not exists public.booking_history (
  id uuid primary key default gen_random_uuid(),
  booking_id uuid not null references public.bookings (id) on delete cascade,
  actor_id uuid references public.profiles (id) on delete set null,
  action public.booking_history_action not null,
  old_status public.booking_status,
  new_status public.booking_status,
  created_at timestamptz not null default now()
);

comment on table public.booking_history is
  'Аудит создания и смены статуса записи.';

create index if not exists booking_history_booking_created_idx
  on public.booking_history (booking_id, created_at desc);

-- --------------------------------------------------------------------------- booking_reviews (schema v1, RPC/UI later)
create table if not exists public.booking_reviews (
  id uuid primary key default gen_random_uuid(),
  booking_id uuid not null unique references public.bookings (id) on delete cascade,
  client_id uuid not null references public.profiles (id) on delete cascade,
  host_id uuid not null references public.profiles (id) on delete cascade,
  staff_id uuid references public.booking_staff (id) on delete set null,
  rating int not null constraint booking_reviews_rating_range check (rating between 1 and 5),
  review_text text constraint booking_reviews_text_len check (char_length(coalesce(review_text, '')) <= 1000),
  created_at timestamptz not null default now(),
  constraint booking_reviews_client_not_host check (client_id <> host_id)
);

comment on table public.booking_reviews is
  'Отзывы после completed booking. RPC create — v2 UI.';

create index if not exists booking_reviews_host_created_idx
  on public.booking_reviews (host_id, created_at desc);

create index if not exists booking_reviews_staff_rating_idx
  on public.booking_reviews (staff_id, rating)
  where staff_id is not null;

-- --------------------------------------------------------------------------- EXCLUDE constraints (no double booking / blocked overlap)
alter table public.bookings
  drop constraint if exists bookings_staff_time_no_overlap;

alter table public.bookings
  add constraint bookings_staff_time_no_overlap
  exclude using gist (
    staff_id with =,
    tstzrange(starts_at, ends_at, '[)') with &&
  )
  where (status in ('pending'::public.booking_status, 'confirmed'::public.booking_status));

alter table public.booking_blocked_slots
  drop constraint if exists booking_blocked_slots_no_overlap;

alter table public.booking_blocked_slots
  add constraint booking_blocked_slots_no_overlap
  exclude using gist (
    staff_id with =,
    tstzrange(starts_at, ends_at, '[)') with &&
  );

-- --------------------------------------------------------------------------- search indexes on profiles (host list query)
create index if not exists profiles_full_name_trgm_idx
  on public.profiles using gin (full_name gin_trgm_ops);

create index if not exists profiles_username_trgm_idx
  on public.profiles using gin (username gin_trgm_ops);

create index if not exists profiles_phone_idx
  on public.profiles (phone)
  where phone is not null;

-- --------------------------------------------------------------------------- guard: deactivate service with future bookings
create or replace function public.booking_services_prevent_deactivate_with_future()
returns trigger
language plpgsql
as $$
begin
  if tg_op = 'UPDATE'
     and old.is_active = true
     and new.is_active = false
     and exists (
       select 1
       from public.bookings b
       where b.service_id = new.id
         and b.status in ('pending'::public.booking_status, 'confirmed'::public.booking_status)
         and b.starts_at > now()
     ) then
    raise exception 'service_has_future_bookings' using errcode = 'P0026';
  end if;

  return new;
end;
$$;

drop trigger if exists trg_booking_services_prevent_deactivate on public.booking_services;
create trigger trg_booking_services_prevent_deactivate
  before update of is_active on public.booking_services
  for each row
  execute function public.booking_services_prevent_deactivate_with_future();

-- --------------------------------------------------------------------------- helpers
create or replace function public.booking_host_has_booking_tag(p_host_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
set row_security to off
as $$
  select exists (
    select 1
    from public.profiles p
    join public.profile_tag_links ptl on ptl.id = p.tag_link_id
    join public.marker_tags mt on mt.id = any (ptl.tag_ids)
    where p.id = p_host_id
      and mt.key = 'booking'
  );
$$;

comment on function public.booking_host_has_booking_tag(uuid) is
  'Host принимает записи только при теге аккаунта booking.';

create or replace function public.booking_last_bookable_day(p_host_id uuid)
returns date
language plpgsql
stable
security definer
set search_path = public
set row_security to off
as $$
declare
  v_settings public.booking_schedule_settings%rowtype;
  v_today date;
begin
  v_today := (now() at time zone coalesce(
    (select timezone from public.booking_schedule_settings where host_id = p_host_id),
    'Asia/Almaty'
  ))::date;

  select * into v_settings
  from public.booking_schedule_settings
  where host_id = p_host_id;

  if not found then
    return v_today + 14;
  end if;

  if v_settings.horizon_kind = 'until_date'::public.booking_horizon_kind then
    return coalesce(v_settings.max_booking_until_date, v_today + 14);
  end if;

  return v_today + v_settings.max_booking_days_ahead;
end;
$$;

create or replace function public.booking_resolve_staff_day_window(
  p_staff_id uuid,
  p_day date
)
returns table (
  is_working boolean,
  work_start time,
  work_end time,
  unavailable_reason text
)
language plpgsql
stable
security definer
set search_path = public
set row_security to off
as $$
declare
  v_host_id uuid;
  v_weekday int;
  v_settings public.booking_schedule_settings%rowtype;
  v_has_settings boolean := false;
  v_sched public.booking_staff_schedule%rowtype;
  v_absence_note text;
begin
  select s.host_id into v_host_id
  from public.booking_staff s
  where s.id = p_staff_id
    and s.is_active = true;

  if v_host_id is null then
    return query select false, null::time, null::time, 'invalid_staff'::text;
    return;
  end if;

  select * into v_settings
  from public.booking_schedule_settings
  where host_id = v_host_id;

  v_has_settings := found;

  select a.note into v_absence_note
  from public.booking_staff_absences a
  where a.staff_id = p_staff_id
    and p_day between a.start_date and a.end_date
  order by a.start_date
  limit 1;

  if found then
    return query select
      false,
      null::time,
      null::time,
      coalesce(nullif(trim(v_absence_note), ''), 'executor_absent');
    return;
  end if;

  v_weekday := extract(isodow from p_day)::int;

  select * into v_sched
  from public.booking_staff_schedule
  where staff_id = p_staff_id
    and weekday = v_weekday;

  if found then
    if not v_sched.is_working then
      return query select false, null::time, null::time, 'staff_rest_day'::text;
      return;
    end if;

    return query select true, v_sched.work_start_time, v_sched.work_end_time, null::text;
    return;
  end if;

  if not v_has_settings then
    return query select true, '09:00'::time, '20:00'::time, null::text;
    return;
  end if;

  if v_weekday = any (v_settings.rest_weekdays) then
    return query select false, null::time, null::time, 'rest_day'::text;
    return;
  end if;

  return query select
    true,
    v_settings.default_work_start_time,
    v_settings.default_work_end_time,
    null::text;
end;
$$;

comment on function public.booking_resolve_staff_day_window(uuid, date) is
  'Рабочее окно мастера на день: staff_schedule → fallback account settings.';

create or replace function public.booking_ranges_overlap(
  p_a_start timestamptz,
  p_a_end timestamptz,
  p_b_start timestamptz,
  p_b_end timestamptz
)
returns boolean
language sql
immutable
as $$
  select p_a_start < p_b_end and p_a_end > p_b_start;
$$;

grant execute on function public.booking_host_has_booking_tag(uuid) to authenticated;
grant execute on function public.booking_last_bookable_day(uuid) to authenticated;
grant execute on function public.booking_resolve_staff_day_window(uuid, date) to authenticated;
