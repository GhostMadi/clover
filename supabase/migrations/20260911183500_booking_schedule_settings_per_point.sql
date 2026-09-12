-- Schedule settings per booking_point (like attendance settings per workplace).
-- Product: docs/business/booking-points.md

-- 1) point_id column + backfill
alter table public.booking_schedule_settings
  add column if not exists point_id uuid references public.booking_points (id) on delete cascade;

-- Hosts with settings but no point yet → ensure default point
insert into public.booking_points (host_id, name)
select distinct s.host_id, 'Основная'
from public.booking_schedule_settings s
where not exists (
  select 1
  from public.booking_points p
  where p.host_id = s.host_id
    and p.archived_at is null
);

-- Attach existing host row to earliest point
update public.booking_schedule_settings s
set point_id = p.id
from (
  select distinct on (host_id) id, host_id
  from public.booking_points
  where archived_at is null
  order by host_id, created_at asc
) p
where s.point_id is null
  and p.host_id = s.host_id;

-- Drop orphan host rows without point (should be none)
delete from public.booking_schedule_settings where point_id is null;

-- Switch PK host → point before inserting more rows per host
alter table public.booking_schedule_settings
  alter column point_id set not null;

alter table public.booking_schedule_settings
  drop constraint if exists booking_schedule_settings_pkey;

alter table public.booking_schedule_settings
  add primary key (point_id);

create index if not exists booking_schedule_settings_host_id_idx
  on public.booking_schedule_settings (host_id);

-- Copy settings to other points of the same host (start equal, then diverge in UI)
insert into public.booking_schedule_settings (
  host_id,
  point_id,
  rest_weekdays,
  horizon_kind,
  max_booking_days_ahead,
  max_booking_until_date,
  default_work_start_time,
  default_work_end_time,
  slot_step_minutes,
  timezone,
  updated_at,
  auto_close_hours_after_visit,
  auto_close_target,
  client_cancel_hours_before
)
select distinct on (p.id)
  s.host_id,
  p.id,
  s.rest_weekdays,
  s.horizon_kind,
  s.max_booking_days_ahead,
  s.max_booking_until_date,
  s.default_work_start_time,
  s.default_work_end_time,
  s.slot_step_minutes,
  s.timezone,
  now(),
  s.auto_close_hours_after_visit,
  s.auto_close_target,
  s.client_cancel_hours_before
from public.booking_points p
join public.booking_schedule_settings s
  on s.host_id = p.host_id
where p.archived_at is null
  and not exists (
    select 1
    from public.booking_schedule_settings x
    where x.point_id = p.id
  )
order by p.id, s.updated_at desc;

-- Default row for points that never had host settings
insert into public.booking_schedule_settings (host_id, point_id)
select p.host_id, p.id
from public.booking_points p
where p.archived_at is null
  and not exists (
    select 1 from public.booking_schedule_settings s where s.point_id = p.id
  );

comment on table public.booking_schedule_settings is
  'Настройки записи на точку (point): горизонт, часы, отмена. Как attendance settings на компанию.';

-- 2) Auto-create settings when a point is created
create or replace function public.booking_points_after_insert_settings()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.booking_schedule_settings (host_id, point_id)
  values (new.host_id, new.id)
  on conflict (point_id) do nothing;
  return new;
end;
$$;

drop trigger if exists trg_booking_points_after_insert_settings on public.booking_points;
create trigger trg_booking_points_after_insert_settings
  after insert on public.booking_points
  for each row
  execute function public.booking_points_after_insert_settings();

-- 3) Helpers
create or replace function public.booking_schedule_settings_for_point(p_point_id uuid)
returns public.booking_schedule_settings
language sql
stable
security definer
set search_path = public
set row_security = off
as $$
  select s.*
  from public.booking_schedule_settings s
  where s.point_id = p_point_id;
$$;

create or replace function public.booking_default_point_id(p_host_id uuid)
returns uuid
language sql
stable
security definer
set search_path = public
set row_security = off
as $$
  select p.id
  from public.booking_points p
  where p.host_id = p_host_id
    and p.archived_at is null
  order by p.created_at asc
  limit 1;
$$;

create or replace function public.booking_schedule_settings_for_host(p_host_id uuid)
returns public.booking_schedule_settings
language sql
stable
security definer
set search_path = public
set row_security = off
as $$
  select public.booking_schedule_settings_for_point(
    public.booking_default_point_id(p_host_id)
  );
$$;

create or replace function public.booking_schedule_settings_for_service(p_service_id uuid)
returns public.booking_schedule_settings
language sql
stable
security definer
set search_path = public
set row_security = off
as $$
  select public.booking_schedule_settings_for_point(svc.point_id)
  from public.booking_services svc
  where svc.id = p_service_id
    and svc.point_id is not null;
$$;

revoke all on function public.booking_schedule_settings_for_point(uuid) from public;
revoke all on function public.booking_default_point_id(uuid) from public;
revoke all on function public.booking_schedule_settings_for_host(uuid) from public;
revoke all on function public.booking_schedule_settings_for_service(uuid) from public;
grant execute on function public.booking_schedule_settings_for_point(uuid) to authenticated;
grant execute on function public.booking_default_point_id(uuid) to authenticated;
grant execute on function public.booking_schedule_settings_for_host(uuid) to authenticated;
grant execute on function public.booking_schedule_settings_for_service(uuid) to authenticated;

-- 4) Core helpers rewritten for point scope
create or replace function public.booking_last_bookable_day(p_host_id uuid)
returns date
language plpgsql
stable
security definer
set search_path = public
set row_security = off
as $$
declare
  v_settings public.booking_schedule_settings%rowtype;
  v_today date;
begin
  v_settings := public.booking_schedule_settings_for_host(p_host_id);
  v_today := (now() at time zone coalesce(v_settings.timezone, 'Asia/Almaty'))::date;

  if v_settings.point_id is null then
    return v_today + 14;
  end if;

  if v_settings.horizon_kind = 'until_date'::public.booking_horizon_kind then
    return coalesce(v_settings.max_booking_until_date, v_today + 14);
  end if;

  return v_today + v_settings.max_booking_days_ahead;
end;
$$;

create or replace function public.booking_last_bookable_day_for_point(p_point_id uuid)
returns date
language plpgsql
stable
security definer
set search_path = public
set row_security = off
as $$
declare
  v_settings public.booking_schedule_settings%rowtype;
  v_today date;
begin
  v_settings := public.booking_schedule_settings_for_point(p_point_id);
  v_today := (now() at time zone coalesce(v_settings.timezone, 'Asia/Almaty'))::date;

  if v_settings.point_id is null then
    return v_today + 14;
  end if;

  if v_settings.horizon_kind = 'until_date'::public.booking_horizon_kind then
    return coalesce(v_settings.max_booking_until_date, v_today + 14);
  end if;

  return v_today + v_settings.max_booking_days_ahead;
end;
$$;

revoke all on function public.booking_last_bookable_day_for_point(uuid) from public;
grant execute on function public.booking_last_bookable_day_for_point(uuid) to authenticated;

-- Optional point: availability passes service.point_id; legacy 2-arg uses default point
drop function if exists public.booking_resolve_staff_day_window(uuid, date);

create or replace function public.booking_resolve_staff_day_window(
  p_staff_id uuid,
  p_day date,
  p_point_id uuid default null
)
returns table (
  is_working boolean,
  work_start time without time zone,
  work_end time without time zone,
  unavailable_reason text
)
language plpgsql
stable
security definer
set search_path = public
set row_security = off
as $$
declare
  v_host_id uuid;
  v_weekday int;
  v_settings public.booking_schedule_settings%rowtype;
  v_has_settings boolean := false;
  v_sched public.booking_staff_schedule%rowtype;
  v_absence_note text;
  v_point uuid;
begin
  select s.host_id into v_host_id
  from public.booking_staff s
  where s.id = p_staff_id
    and s.is_active = true;

  if v_host_id is null then
    return query select false, null::time, null::time, 'invalid_staff'::text;
    return;
  end if;

  v_point := coalesce(p_point_id, public.booking_default_point_id(v_host_id));
  if v_point is not null then
    v_settings := public.booking_schedule_settings_for_point(v_point);
    v_has_settings := v_settings.point_id is not null;
  end if;

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

create or replace function public.get_booking_availability(
  p_host_id uuid,
  p_service_id uuid,
  p_staff_id uuid,
  p_day date,
  p_exclude_booking_id uuid default null
)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
set row_security = off
as $$
declare
  uid uuid;
  v_service public.booking_services%rowtype;
  v_settings public.booking_schedule_settings%rowtype;
  v_window record;
  v_tz text := 'Asia/Almaty';
  v_step int := 30;
  v_cursor timestamptz;
  v_day_start timestamptz;
  v_day_end timestamptz;
  v_slot_end timestamptz;
  v_slots jsonb := '[]'::jsonb;
  v_status text;
  v_label text;
  v_rec record;
  v_point uuid;
begin
  uid := public.booking_assert_authenticated();

  if p_host_id is null or p_service_id is null or p_staff_id is null or p_day is null then
    raise exception 'invalid_arguments' using errcode = 'P0007';
  end if;

  if not public.booking_host_has_booking_tag(p_host_id) then
    raise exception 'host_booking_disabled' using errcode = 'P0025';
  end if;

  select *
  into v_service
  from public.booking_services s
  where s.id = p_service_id
    and s.host_id = p_host_id
    and s.is_active = true;

  if not found then
    raise exception 'invalid_service' using errcode = 'P0022';
  end if;

  if not exists (
    select 1
    from public.booking_staff st
    where st.id = p_staff_id
      and st.host_id = p_host_id
      and st.is_active = true
  ) then
    raise exception 'invalid_staff' using errcode = 'P0023';
  end if;

  v_point := coalesce(v_service.point_id, public.booking_default_point_id(p_host_id));
  if v_point is not null then
    v_settings := public.booking_schedule_settings_for_point(v_point);
    if v_settings.point_id is not null then
      v_tz := v_settings.timezone;
      v_step := v_settings.slot_step_minutes;
    end if;
  end if;

  if v_point is not null and p_day > public.booking_last_bookable_day_for_point(v_point) then
    return jsonb_build_object(
      'day_unavailable_reason', 'beyond_horizon',
      'slots', '[]'::jsonb,
      'work_start', null,
      'work_end', null,
      'slot_step_minutes', v_step
    );
  end if;

  select *
  into v_window
  from public.booking_resolve_staff_day_window(p_staff_id, p_day, v_point);

  if not v_window.is_working then
    return jsonb_build_object(
      'day_unavailable_reason', coalesce(v_window.unavailable_reason, 'not_working'),
      'slots', '[]'::jsonb,
      'work_start', null,
      'work_end', null,
      'slot_step_minutes', v_step
    );
  end if;

  v_day_start := (p_day::timestamp + v_window.work_start) at time zone v_tz;
  v_day_end := (p_day::timestamp + v_window.work_end) at time zone v_tz;
  v_cursor := v_day_start;

  while v_cursor < v_day_end loop
    v_slot_end := v_cursor + make_interval(
      mins => v_service.duration_minutes + v_service.buffer_after_minutes
    );

    if v_slot_end <= v_day_end and v_cursor >= now() - interval '1 minute' then
      v_status := 'available';
      v_label := null;

      for v_rec in
        select
          coalesce(nullif(trim(p.full_name), ''), 'Запись') as host_name,
          b.starts_at,
          b.ends_at
        from public.bookings b
        join public.profiles p on p.id = b.host_id
        where b.client_id = uid
          and (p_exclude_booking_id is null or b.id <> p_exclude_booking_id)
          and public.booking_status_blocks_slot(b.status)
          and public.booking_ranges_overlap(
            v_cursor,
            v_slot_end,
            b.starts_at,
            b.ends_at
          )
        limit 1
      loop
        v_status := 'my_conflict';
        v_label := format(
          'У вас запись: %s · %s — %s',
          v_rec.host_name,
          to_char(v_rec.starts_at at time zone v_tz, 'HH24:MI'),
          to_char(v_rec.ends_at at time zone v_tz, 'HH24:MI')
        );
      end loop;

      if v_status = 'available' then
        if exists (
          select 1
          from public.bookings b
          where b.staff_id = p_staff_id
            and (p_exclude_booking_id is null or b.id <> p_exclude_booking_id)
            and public.booking_status_blocks_slot(b.status)
            and public.booking_ranges_overlap(
              v_cursor,
              v_slot_end,
              b.starts_at,
              b.ends_at
            )
        )
        or exists (
          select 1
          from public.booking_blocked_slots bs
          where bs.staff_id = p_staff_id
            and public.booking_ranges_overlap(
              v_cursor,
              v_slot_end,
              bs.starts_at,
              bs.ends_at
            )
        ) then
          v_status := 'host_busy';
        end if;
      end if;

      v_slots := v_slots || jsonb_build_array(
        jsonb_strip_nulls(jsonb_build_object(
          'starts_at', v_cursor,
          'status', v_status,
          'conflict_label', v_label
        ))
      );
    end if;

    v_cursor := v_cursor + make_interval(mins => v_step);
  end loop;

  return jsonb_build_object(
    'day_unavailable_reason', null,
    'slots', v_slots,
    'work_start', to_char(v_window.work_start, 'HH24:MI'),
    'work_end', to_char(v_window.work_end, 'HH24:MI'),
    'slot_step_minutes', v_step
  );
end;
$$;

create or replace function public.list_my_bookings_enriched(
  p_from timestamptz,
  p_to timestamptz,
  p_cursor jsonb default null,
  p_limit integer default 50
)
returns setof jsonb
language plpgsql
stable
security definer
set search_path = public
set row_security = off
as $$
declare
  uid uuid;
  v_limit int;
begin
  uid := public.booking_assert_authenticated();
  v_limit := greatest(1, least(coalesce(p_limit, 50), 100));

  return query
  select jsonb_build_object(
    'id', b.id,
    'host_id', b.host_id,
    'host_display_name', coalesce(hp.full_name, ''),
    'host_username', hp.username,
    'service_id', b.service_id,
    'service_title', b.service_title,
    'service_emoji', b.service_emoji,
    'duration_minutes', b.duration_minutes,
    'price', b.price,
    'staff_id', b.staff_id,
    'client_cancel_hours_before', coalesce(
      (
        select s.client_cancel_hours_before
        from public.booking_services svc
        join public.booking_schedule_settings s on s.point_id = svc.point_id
        where svc.id = b.service_id
      ),
      (
        select (public.booking_schedule_settings_for_host(b.host_id)).client_cancel_hours_before
      ),
      0
    ),
    'executor_name', st.display_name,
    'starts_at', b.starts_at,
    'status', b.status,
    'notes', b.client_notes,
    'created_at', b.created_at
  )
  from public.bookings b
  join public.profiles hp on hp.id = b.host_id
  join public.booking_staff st on st.id = b.staff_id
  where b.client_id = uid
    and b.starts_at >= coalesce(p_from, '-infinity'::timestamptz)
    and b.starts_at <= coalesce(p_to, 'infinity'::timestamptz)
    and (
      p_cursor is null
      or b.starts_at > coalesce((p_cursor ->> 'starts_at')::timestamptz, '-infinity'::timestamptz)
      or (
        b.starts_at = (p_cursor ->> 'starts_at')::timestamptz
        and b.id > coalesce(
          (p_cursor ->> 'id')::uuid,
          '00000000-0000-0000-0000-000000000000'::uuid
        )
      )
    )
  order by b.starts_at asc, b.id asc
  limit v_limit;
end;
$$;

create or replace function public.booking_auto_close_stale_visits()
returns integer
language plpgsql
security definer
set search_path = public
set row_security = off
as $$
declare
  v_row record;
  v_closed int := 0;
  v_now timestamptz := now();
  v_hours int;
begin
  for v_row in
    select
      b.id,
      b.status,
      coalesce(s.auto_close_hours_after_visit, h.auto_close_hours_after_visit, 0) as close_hours
    from public.bookings b
    left join public.booking_services svc on svc.id = b.service_id
    left join public.booking_schedule_settings s on s.point_id = svc.point_id
    left join lateral (
      select x.auto_close_hours_after_visit
      from public.booking_schedule_settings x
      where x.host_id = b.host_id
      order by x.updated_at desc
      limit 1
    ) h on true
    where b.status in (
      'pending'::public.booking_status,
      'confirmed'::public.booking_status
    )
      and coalesce(s.auto_close_hours_after_visit, h.auto_close_hours_after_visit, 0) > 0
      and b.ends_at + make_interval(
        hours => coalesce(s.auto_close_hours_after_visit, h.auto_close_hours_after_visit, 0)
      ) <= v_now
    for update of b skip locked
  loop
    v_hours := v_row.close_hours;
    if v_hours <= 0 then
      continue;
    end if;

    update public.bookings
    set status = 'no_show'::public.booking_status,
        no_show_at = v_now
    where id = v_row.id;

    insert into public.booking_history (booking_id, actor_id, action, old_status, new_status)
    values (
      v_row.id,
      null,
      'auto_closed'::public.booking_history_action,
      v_row.status,
      'no_show'::public.booking_status
    );

    v_closed := v_closed + 1;
  end loop;

  return v_closed;
end;
$$;


-- 5) create_booking: settings from service.point_id
create or replace function public.create_booking(
  p_host_id uuid,
  p_service_id uuid,
  p_staff_id uuid,
  p_starts_at timestamptz,
  p_participants_count integer default 1,
  p_client_notes text default null,
  p_use_bonuses boolean default true
)
returns uuid
language plpgsql
security definer
set search_path = public
set row_security = off
as $$
declare
  uid uuid;
  v_service public.booking_services%rowtype;
  v_staff public.booking_staff%rowtype;
  v_settings public.booking_schedule_settings%rowtype;
  v_window record;
  v_tz text := 'Asia/Almaty';
  v_day date;
  v_slot_end timestamptz;
  v_day_end timestamptz;
  v_notes text;
  v_local_ts timestamp;
  v_local_minutes int;
  v_start_minutes int;
  v_step int := 30;
  v_booking_id uuid;
  v_conflict record;
  v_point uuid;
begin
  uid := public.booking_assert_authenticated();

  if p_host_id is null or p_service_id is null or p_staff_id is null or p_starts_at is null then
    raise exception 'invalid_arguments' using errcode = 'P0007';
  end if;

  if uid = p_host_id then
    raise exception 'self_booking_not_allowed' using errcode = 'P0027';
  end if;

  if not public.booking_host_has_booking_tag(p_host_id) then
    raise exception 'host_booking_disabled' using errcode = 'P0025';
  end if;

  select * into v_service
  from public.booking_services s
  where s.id = p_service_id
    and s.host_id = p_host_id
    and s.is_active = true;

  if not found then
    raise exception 'invalid_service' using errcode = 'P0022';
  end if;

  select * into v_staff
  from public.booking_staff st
  where st.id = p_staff_id
    and st.host_id = p_host_id
    and st.is_active = true;

  if not found then
    raise exception 'invalid_staff' using errcode = 'P0023';
  end if;

  if not exists (
    select 1
    from public.booking_service_staff bss
    where bss.service_id = p_service_id
      and bss.staff_id = p_staff_id
  ) then
    raise exception 'staff_not_linked_to_service' using errcode = 'P0023';
  end if;

  if coalesce(p_participants_count, 1) < 1
     or coalesce(p_participants_count, 1) > v_service.max_participants then
    raise exception 'invalid_participants_count' using errcode = 'P0007';
  end if;

  v_notes := nullif(trim(coalesce(p_client_notes, '')), '');
  if v_notes is not null and char_length(v_notes) > 300 then
    raise exception 'client_notes_too_long' using errcode = 'P0007';
  end if;

  v_point := coalesce(v_service.point_id, public.booking_default_point_id(p_host_id));
  if v_point is not null then
    v_settings := public.booking_schedule_settings_for_point(v_point);
    if v_settings.point_id is not null then
      v_tz := v_settings.timezone;
      v_step := v_settings.slot_step_minutes;
    end if;
  end if;

  if p_starts_at < now() - interval '1 minute' then
    raise exception 'starts_at_in_past' using errcode = 'P0024';
  end if;

  v_day := (p_starts_at at time zone v_tz)::date;

  if v_point is not null and v_day > public.booking_last_bookable_day_for_point(v_point) then
    raise exception 'outside_horizon' using errcode = 'P0024';
  end if;

  select * into v_window
  from public.booking_resolve_staff_day_window(p_staff_id, v_day, v_point);

  if not v_window.is_working then
    raise exception 'booking_not_available' using errcode = 'P0020';
  end if;

  v_day_end := (v_day::timestamp + v_window.work_end) at time zone v_tz;
  v_slot_end := p_starts_at + make_interval(mins => v_service.duration_minutes + v_service.buffer_after_minutes);

  if p_starts_at < (v_day::timestamp + v_window.work_start) at time zone v_tz
     or v_slot_end > v_day_end then
    raise exception 'outside_schedule' using errcode = 'P0024';
  end if;

  v_local_ts := p_starts_at at time zone v_tz;
  v_local_minutes := (extract(hour from v_local_ts)::int * 60) + extract(minute from v_local_ts)::int;
  v_start_minutes := (extract(hour from v_window.work_start)::int * 60) + extract(minute from v_window.work_start)::int;

  if mod(v_local_minutes - v_start_minutes, v_step) <> 0 then
    raise exception 'slot_not_aligned' using errcode = 'P0024';
  end if;

  if exists (
    select 1
    from public.booking_blocked_slots bs
    where bs.staff_id = p_staff_id
      and public.booking_ranges_overlap(p_starts_at, v_slot_end, bs.starts_at, bs.ends_at)
  ) then
    raise exception 'slot_conflict' using errcode = 'P0021';
  end if;

  select b.id, b.starts_at, b.ends_at into v_conflict
  from public.bookings b
  where b.client_id = uid
    and public.booking_status_blocks_slot(b.status)
    and public.booking_ranges_overlap(p_starts_at, v_slot_end, b.starts_at, b.ends_at)
  limit 1;

  if found then
    raise exception 'client_slot_conflict' using errcode = 'P0021';
  end if;

  insert into public.bookings (
    host_id,
    client_id,
    service_id,
    staff_id,
    status,
    starts_at,
    ends_at,
    service_title,
    service_emoji,
    duration_minutes,
    buffer_after_minutes,
    price,
    max_participants,
    participants_count,
    client_notes,
    service_bonus_earn_amount,
    service_bonus_pay_percent,
    use_bonuses,
    confirmed_at
  )
  values (
    p_host_id,
    uid,
    p_service_id,
    p_staff_id,
    'confirmed'::public.booking_status,
    p_starts_at,
    v_slot_end,
    v_service.title,
    v_service.emoji_text,
    v_service.duration_minutes,
    v_service.buffer_after_minutes,
    v_service.price,
    v_service.max_participants,
    coalesce(p_participants_count, 1),
    v_notes,
    greatest(coalesce(v_service.bonus_earn_amount, 0), 0),
    greatest(least(coalesce(v_service.bonus_pay_percent, 0), 100), 0),
    coalesce(p_use_bonuses, true),
    now()
  )
  returning id into v_booking_id;

  insert into public.booking_history (booking_id, actor_id, action, old_status, new_status)
  values (
    v_booking_id,
    uid,
    'created'::public.booking_history_action,
    null,
    'confirmed'::public.booking_status
  );

  return v_booking_id;
exception
  when exclusion_violation then
    raise exception 'slot_conflict' using errcode = 'P0021';
end;
$$;


-- 6) reschedule_booking: settings from booking service point
create or replace function public.reschedule_booking(
  p_booking_id uuid,
  p_staff_id uuid,
  p_starts_at timestamptz,
  p_reset_status public.booking_status default 'confirmed'::public.booking_status
)
returns void
language plpgsql
security definer
set search_path = public
set row_security = off
as $$
declare
  uid uuid;
  v_booking public.bookings%rowtype;
  v_service public.booking_services%rowtype;
  v_settings public.booking_schedule_settings%rowtype;
  v_window record;
  v_tz text := 'Asia/Almaty';
  v_day date;
  v_slot_end timestamptz;
  v_day_end timestamptz;
  v_local_ts timestamp;
  v_local_minutes int;
  v_start_minutes int;
  v_step int := 30;
  v_is_host boolean;
  v_is_client boolean;
  v_cancel_hours int := 0;
  v_point uuid;
begin
  uid := public.booking_assert_authenticated();

  if p_booking_id is null or p_staff_id is null or p_starts_at is null then
    raise exception 'invalid_arguments' using errcode = 'P0007';
  end if;

  if p_reset_status not in (
    'pending'::public.booking_status,
    'confirmed'::public.booking_status
  ) then
    raise exception 'invalid_arguments' using errcode = 'P0007';
  end if;

  select * into v_booking
  from public.bookings b
  where b.id = p_booking_id
  for update;

  if not found then
    raise exception 'booking_not_found' using errcode = 'P0008';
  end if;

  v_is_host := v_booking.host_id = uid;
  v_is_client := v_booking.client_id = uid;
  if not (v_is_host or v_is_client) then
    raise exception 'forbidden' using errcode = 'P0009';
  end if;

  if public.booking_status_is_terminal(v_booking.status) then
    raise exception 'invalid_status_transition' using errcode = 'P0011';
  end if;

  select * into v_service
  from public.booking_services s
  where s.id = v_booking.service_id
    and s.host_id = v_booking.host_id
    and s.is_active = true;

  if not found then
    raise exception 'invalid_service' using errcode = 'P0022';
  end if;

  v_point := coalesce(v_service.point_id, public.booking_default_point_id(v_booking.host_id));
  if v_point is not null then
    v_settings := public.booking_schedule_settings_for_point(v_point);
    if v_settings.point_id is not null then
      v_tz := v_settings.timezone;
      v_step := v_settings.slot_step_minutes;
      v_cancel_hours := coalesce(v_settings.client_cancel_hours_before, 0);
    end if;
  end if;

  if v_is_client and not v_is_host then
    if v_booking.status not in (
      'pending'::public.booking_status,
      'confirmed'::public.booking_status
    ) then
      raise exception 'invalid_status_transition' using errcode = 'P0011';
    end if;
    if v_booking.starts_at <= now() + make_interval(hours => v_cancel_hours) then
      raise exception 'forbidden' using errcode = 'P0009';
    end if;
    p_staff_id := v_booking.staff_id;
  end if;

  if not exists (
    select 1
    from public.booking_staff st
    where st.id = p_staff_id
      and st.host_id = v_booking.host_id
      and st.is_active = true
  ) then
    raise exception 'invalid_staff' using errcode = 'P0023';
  end if;

  if not exists (
    select 1
    from public.booking_service_staff bss
    where bss.service_id = v_booking.service_id
      and bss.staff_id = p_staff_id
  ) then
    raise exception 'staff_not_linked_to_service' using errcode = 'P0023';
  end if;

  if p_starts_at < now() - interval '1 minute' then
    raise exception 'starts_at_in_past' using errcode = 'P0024';
  end if;

  v_day := (p_starts_at at time zone v_tz)::date;

  if v_point is not null and v_day > public.booking_last_bookable_day_for_point(v_point) then
    raise exception 'outside_horizon' using errcode = 'P0024';
  end if;

  select * into v_window
  from public.booking_resolve_staff_day_window(p_staff_id, v_day, v_point);

  if not v_window.is_working then
    raise exception 'booking_not_available' using errcode = 'P0020';
  end if;

  v_day_end := (v_day::timestamp + v_window.work_end) at time zone v_tz;
  v_slot_end := p_starts_at + make_interval(
    mins => v_booking.duration_minutes + v_booking.buffer_after_minutes
  );

  if p_starts_at < (v_day::timestamp + v_window.work_start) at time zone v_tz
     or v_slot_end > v_day_end then
    raise exception 'outside_schedule' using errcode = 'P0024';
  end if;

  v_local_ts := p_starts_at at time zone v_tz;
  v_local_minutes := (extract(hour from v_local_ts)::int * 60) + extract(minute from v_local_ts)::int;
  v_start_minutes := (extract(hour from v_window.work_start)::int * 60) + extract(minute from v_window.work_start)::int;

  if mod(v_local_minutes - v_start_minutes, v_step) <> 0 then
    raise exception 'slot_not_aligned' using errcode = 'P0024';
  end if;

  perform public.booking_assert_staff_slot_available(
    p_staff_id,
    p_starts_at,
    v_slot_end,
    p_booking_id
  );

  update public.bookings
  set staff_id = p_staff_id,
      starts_at = p_starts_at,
      ends_at = v_slot_end,
      status = p_reset_status,
      confirmed_at = case when p_reset_status = 'confirmed'::public.booking_status then now() else null end,
      client_arrived_at = null,
      service_started_at = null,
      completed_at = null,
      no_show_at = null,
      cancelled_at = null,
      cancelled_by = null
  where id = p_booking_id;

  insert into public.booking_history (booking_id, actor_id, action, old_status, new_status)
  values (
    p_booking_id,
    uid,
    'rescheduled'::public.booking_history_action,
    v_booking.status,
    p_reset_status
  );

  perform public.booking_enqueue_push(
    case when v_is_client then v_booking.host_id else v_booking.client_id end,
    'booking_rescheduled',
    'Запись перенесена',
    'Новое время: ' || to_char(timezone(v_tz, p_starts_at), 'DD.MM HH24:MI'),
    public.booking_notification_payload((select b from public.bookings b where b.id = p_booking_id))
  );
end;
$$;

-- 7) update_booking_status cancel hours from point
CREATE OR REPLACE FUNCTION public.update_booking_status(p_booking_id uuid, p_status booking_status)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
 SET row_security TO 'off'
AS $$
declare
  uid uuid;
  v_booking public.bookings%rowtype;
  v_is_host boolean;
  v_is_client boolean;
  v_cancel_hours int := 0;
  v_now timestamptz := now();
begin
  uid := public.booking_assert_authenticated();

  select * into v_booking
  from public.bookings b
  where b.id = p_booking_id
  for update;

  if not found then
    raise exception 'booking_not_found' using errcode = 'P0008';
  end if;

  v_is_host := v_booking.host_id = uid;
  v_is_client := v_booking.client_id = uid;

  if not v_is_host and not v_is_client then
    raise exception 'forbidden' using errcode = 'P0009';
  end if;

  if v_booking.status = p_status then
    return;
  end if;

  if public.booking_status_is_terminal(v_booking.status) then
    raise exception 'invalid_status_transition' using errcode = 'P0011';
  end if;

  -- Клиент: только отмена по правилам платформы.
  if v_is_client and not v_is_host then
    if p_status <> 'cancelled'::public.booking_status then
      raise exception 'forbidden' using errcode = 'P0009';
    end if;

    if v_booking.status not in (
      'pending'::public.booking_status,
      'confirmed'::public.booking_status
    ) then
      raise exception 'invalid_status_transition' using errcode = 'P0011';
    end if;

    select coalesce(
      (
        select s.client_cancel_hours_before
        from public.booking_services svc
        join public.booking_schedule_settings s on s.point_id = svc.point_id
        where svc.id = v_booking.service_id
      ),
      (
        select (public.booking_schedule_settings_for_host(v_booking.host_id)).client_cancel_hours_before
      ),
      0
    )
    into v_cancel_hours;

    if v_booking.starts_at <= v_now + make_interval(hours => v_cancel_hours) then
      raise exception 'cancel_too_late' using errcode = 'P0011';
    end if;

    update public.bookings
    set status = p_status,
        cancelled_at = v_now,
        cancelled_by = uid
    where id = p_booking_id;

    insert into public.booking_history (booking_id, actor_id, action, old_status, new_status)
    values (
      p_booking_id,
      uid,
      'status_changed'::public.booking_history_action,
      v_booking.status,
      p_status
    );
    return;
  end if;

  -- Host: полная свобода (кроме терминальных исходов → другой терминальный).
  if not v_is_host then
    raise exception 'forbidden' using errcode = 'P0009';
  end if;

  if p_status = 'cancelled'::public.booking_status then
    update public.bookings
    set status = p_status,
        cancelled_at = v_now,
        cancelled_by = uid
    where id = p_booking_id;

  elsif p_status = 'completed'::public.booking_status then
    update public.bookings
    set status = p_status,
        confirmed_at = coalesce(confirmed_at, v_now),
        client_arrived_at = coalesce(client_arrived_at, v_now),
        service_started_at = coalesce(service_started_at, v_now),
        completed_at = v_now
    where id = p_booking_id;

  elsif p_status = 'no_show'::public.booking_status then
    if v_booking.status not in (
      'pending'::public.booking_status,
      'confirmed'::public.booking_status
    ) then
      raise exception 'invalid_status_transition' using errcode = 'P0011';
    end if;

    if v_booking.starts_at > v_now then
      raise exception 'no_show_too_early' using errcode = 'P0011';
    end if;

    update public.bookings
    set status = p_status,
        no_show_at = v_now
    where id = p_booking_id;

  elsif p_status = 'confirmed'::public.booking_status then
    if v_booking.status <> 'pending'::public.booking_status then
      raise exception 'invalid_status_transition' using errcode = 'P0011';
    end if;
    update public.bookings
    set status = p_status,
        confirmed_at = v_now
    where id = p_booking_id;

  elsif p_status = 'client_arrived'::public.booking_status then
    if v_booking.status not in (
      'pending'::public.booking_status,
      'confirmed'::public.booking_status
    ) then
      raise exception 'invalid_status_transition' using errcode = 'P0011';
    end if;
    update public.bookings
    set status = p_status,
        confirmed_at = coalesce(confirmed_at, v_now),
        client_arrived_at = coalesce(client_arrived_at, v_now)
    where id = p_booking_id;

  elsif p_status = 'in_progress'::public.booking_status then
    if v_booking.status = 'in_progress'::public.booking_status then
      raise exception 'invalid_status_transition' using errcode = 'P0011';
    end if;
    update public.bookings
    set status = p_status,
        confirmed_at = coalesce(confirmed_at, v_now),
        client_arrived_at = coalesce(client_arrived_at, v_now),
        service_started_at = coalesce(service_started_at, v_now)
    where id = p_booking_id;

  else
    raise exception 'invalid_status_transition' using errcode = 'P0011';
  end if;

  insert into public.booking_history (booking_id, actor_id, action, old_status, new_status)
  values (
    p_booking_id,
    uid,
    'status_changed'::public.booking_history_action,
    v_booking.status,
    p_status
  );
end;
$$;

