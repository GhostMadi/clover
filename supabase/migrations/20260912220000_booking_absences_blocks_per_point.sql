-- Absences + blocked slots scoped to booking_points.
-- Product: docs/business/booking-points.md · SPEC booking-points.md

-- --------------------------------------------------------------------------- columns
alter table public.booking_staff_absences
  add column if not exists point_id uuid references public.booking_points (id) on delete cascade;

alter table public.booking_blocked_slots
  add column if not exists point_id uuid references public.booking_points (id) on delete cascade;

-- Backfill → host default point
update public.booking_staff_absences a
set point_id = public.booking_default_point_id(a.host_id)
where a.point_id is null
  and public.booking_default_point_id(a.host_id) is not null;

update public.booking_blocked_slots b
set point_id = public.booking_default_point_id(b.host_id)
where b.point_id is null
  and public.booking_default_point_id(b.host_id) is not null;

-- Drop rows that cannot be assigned (no point) — rare
delete from public.booking_staff_absences where point_id is null;
delete from public.booking_blocked_slots where point_id is null;

alter table public.booking_staff_absences
  alter column point_id set not null;

alter table public.booking_blocked_slots
  alter column point_id set not null;

create index if not exists booking_staff_absences_point_dates_idx
  on public.booking_staff_absences (point_id, staff_id, start_date, end_date);

create index if not exists booking_blocked_slots_point_staff_starts_idx
  on public.booking_blocked_slots (point_id, staff_id, starts_at);

-- Overlap exclude per point (same staff can block different points in parallel)
alter table public.booking_blocked_slots
  drop constraint if exists booking_blocked_slots_no_overlap;

alter table public.booking_blocked_slots
  add constraint booking_blocked_slots_no_overlap
  exclude using gist (
    staff_id with =,
    point_id with =,
    tstzrange(starts_at, ends_at, '[)') with &&
  );

comment on column public.booking_staff_absences.point_id is
  'Absence applies only at this booking point.';
comment on column public.booking_blocked_slots.point_id is
  'Blocked interval applies only at this booking point.';

-- --------------------------------------------------------------------------- replace absences (per point)
drop function if exists public.replace_booking_staff_absences(jsonb);

create or replace function public.replace_booking_staff_absences(
  p_point_id uuid,
  p_absences jsonb
)
returns void
language plpgsql
security definer
set search_path = public
set row_security to off
as $$
declare
  v_uid uuid := auth.uid();
  v_item jsonb;
  v_staff uuid;
  v_start date;
  v_end date;
  v_note text;
begin
  if v_uid is null then
    raise exception 'not_authenticated' using errcode = '42501';
  end if;

  if p_point_id is null then
    raise exception 'point_required' using errcode = '22023';
  end if;

  if not exists (
    select 1 from public.booking_points p
    where p.id = p_point_id
      and p.host_id = v_uid
      and p.archived_at is null
  ) then
    raise exception 'point_forbidden' using errcode = '42501';
  end if;

  delete from public.booking_staff_absences
  where host_id = v_uid
    and point_id = p_point_id;

  if p_absences is null or jsonb_typeof(p_absences) <> 'array' then
    return;
  end if;

  for v_item in select * from jsonb_array_elements(p_absences)
  loop
    v_staff := nullif(v_item ->> 'staff_id', '')::uuid;
    v_start := nullif(v_item ->> 'start_date', '')::date;
    v_end := nullif(v_item ->> 'end_date', '')::date;
    v_note := nullif(trim(coalesce(v_item ->> 'note', '')), '');

    if v_staff is null or v_start is null or v_end is null then
      raise exception 'invalid_absence_payload' using errcode = '22023';
    end if;
    if v_end < v_start then
      raise exception 'invalid_absence_dates' using errcode = '22023';
    end if;
    if not exists (
      select 1 from public.booking_staff s
      where s.id = v_staff and s.host_id = v_uid
    ) then
      raise exception 'staff_forbidden' using errcode = '42501';
    end if;

    insert into public.booking_staff_absences (host_id, point_id, staff_id, start_date, end_date, note)
    values (v_uid, p_point_id, v_staff, v_start, v_end, v_note);
  end loop;
end;
$$;

revoke all on function public.replace_booking_staff_absences(uuid, jsonb) from public;
grant execute on function public.replace_booking_staff_absences(uuid, jsonb) to authenticated;

comment on function public.replace_booking_staff_absences(uuid, jsonb) is
  'Host: replace booking_staff_absences for one point in one transaction.';

-- --------------------------------------------------------------------------- day window: absences only for point
create or replace function public.booking_resolve_staff_day_window(
  p_staff_id uuid,
  p_day date,
  p_point_id uuid default null
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
    and a.point_id = v_point
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


-- --------------------------------------------------------------------------- availability: blocked slots only for service point
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
set row_security to off
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
            and bs.point_id = v_point
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

-- --------------------------------------------------------------------------- assert slot: optional point scope
drop function if exists public.booking_assert_staff_slot_available(uuid, timestamptz, timestamptz, uuid);

create or replace function public.booking_assert_staff_slot_available(
  p_staff_id uuid,
  p_starts_at timestamptz,
  p_ends_at timestamptz,
  p_exclude_booking_id uuid default null,
  p_point_id uuid default null
)
returns void
language plpgsql
stable
set search_path = public
as $$
begin
  if exists (
    select 1
    from public.booking_blocked_slots bs
    where bs.staff_id = p_staff_id
      and (p_point_id is null or bs.point_id = p_point_id)
      and public.booking_ranges_overlap(p_starts_at, p_ends_at, bs.starts_at, bs.ends_at)
  ) then
    raise exception 'slot_conflict' using errcode = 'P0021';
  end if;

  if exists (
    select 1
    from public.bookings b
    where b.staff_id = p_staff_id
      and b.id is distinct from p_exclude_booking_id
      and public.booking_status_blocks_slot(b.status)
      and public.booking_ranges_overlap(p_starts_at, p_ends_at, b.starts_at, b.ends_at)
  ) then
    raise exception 'slot_conflict' using errcode = 'P0021';
  end if;
end;
$$;

-- --------------------------------------------------------------------------- create_booking: blocked slots per point (bonus overload)
create or replace function public.create_booking(
  p_host_id uuid,
  p_service_id uuid,
  p_staff_id uuid,
  p_starts_at timestamp with time zone,
  p_participants_count integer default 1,
  p_client_notes text default null,
  p_use_bonuses boolean default true
)
returns uuid
language plpgsql
security definer
set search_path to 'public'
set row_security to 'off'
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
      and bs.point_id = v_point
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

-- --------------------------------------------------------------------------- reschedule: assert with point
create or replace function public.reschedule_booking(
  p_booking_id uuid,
  p_staff_id uuid,
  p_starts_at timestamp with time zone,
  p_reset_status booking_status default 'confirmed'::booking_status
)
returns void
language plpgsql
security definer
set search_path to 'public'
set row_security to 'off'
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
    p_booking_id,
    v_point
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

-- --------------------------------------------------------------------------- analytics optional point (via service.point_id)
drop function if exists public.get_booking_analytics(date, date, uuid);

create or replace function public.get_booking_analytics(
  p_from date,
  p_to date,
  p_staff_id uuid default null,
  p_point_id uuid default null
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
  v_total bigint;
  v_pending bigint;
  v_confirmed bigint;
  v_completed bigint;
  v_cancelled bigint;
  v_revenue numeric;
  v_avg numeric;
  v_popular jsonb;
  v_top_staff jsonb;
  v_tz text := 'Asia/Almaty';
begin
  uid := public.booking_assert_authenticated();

  if p_point_id is not null then
    if not exists (
      select 1 from public.booking_points p
      where p.id = p_point_id and p.host_id = uid and p.archived_at is null
    ) then
      raise exception 'point_forbidden' using errcode = '42501';
    end if;
    v_tz := coalesce(
      (select s.timezone from public.booking_schedule_settings s where s.point_id = p_point_id),
      v_tz
    );
  else
    v_tz := coalesce(
      (select s.timezone from public.booking_schedule_settings s where s.host_id = uid limit 1),
      v_tz
    );
  end if;

  select
    count(*)::bigint,
    count(*) filter (where b.status = 'pending')::bigint,
    count(*) filter (where b.status = 'confirmed')::bigint,
    count(*) filter (where b.status = 'completed')::bigint,
    count(*) filter (where b.status = 'cancelled')::bigint,
    coalesce(sum(b.price) filter (where b.status = 'completed'), 0)
  into v_total, v_pending, v_confirmed, v_completed, v_cancelled, v_revenue
  from public.bookings b
  left join public.booking_services svc on svc.id = b.service_id
  where b.host_id = uid
    and (b.starts_at at time zone v_tz)::date between p_from and p_to
    and (p_staff_id is null or b.staff_id = p_staff_id)
    and (p_point_id is null or svc.point_id = p_point_id);

  v_avg := case when v_completed > 0 then v_revenue / v_completed else 0 end;

  select coalesce(jsonb_agg(row_to_json(t)::jsonb order by t.booking_count desc), '[]'::jsonb)
  into v_popular
  from (
    select
      b.service_id,
      b.service_title as title,
      b.service_emoji as emoji_text,
      count(*)::int as booking_count,
      coalesce(sum(b.price) filter (where b.status = 'completed'), 0) as revenue
    from public.bookings b
    left join public.booking_services svc on svc.id = b.service_id
    where b.host_id = uid
      and (b.starts_at at time zone v_tz)::date between p_from and p_to
      and (p_staff_id is null or b.staff_id = p_staff_id)
      and (p_point_id is null or svc.point_id = p_point_id)
    group by b.service_id, b.service_title, b.service_emoji
    order by count(*) desc
    limit 10
  ) t;

  select coalesce(jsonb_agg(row_to_json(t)::jsonb order by t.booking_count desc), '[]'::jsonb)
  into v_top_staff
  from (
    select
      st.id as staff_id,
      st.display_name,
      count(*)::int as booking_count,
      coalesce(sum(b.price) filter (where b.status = 'completed'), 0) as revenue,
      count(*) filter (where b.status = 'completed')::int as completed_count
    from public.bookings b
    join public.booking_staff st on st.id = b.staff_id
    left join public.booking_services svc on svc.id = b.service_id
    where b.host_id = uid
      and (b.starts_at at time zone v_tz)::date between p_from and p_to
      and (p_staff_id is null or b.staff_id = p_staff_id)
      and (p_point_id is null or svc.point_id = p_point_id)
    group by st.id, st.display_name
    order by count(*) desc
    limit 10
  ) t;

  return jsonb_build_object(
    'total_bookings', v_total,
    'pending_bookings', v_pending,
    'confirmed_bookings', v_confirmed,
    'completed_bookings', v_completed,
    'cancelled_bookings', v_cancelled,
    'revenue', v_revenue,
    'avg_check', v_avg,
    'popular_services', v_popular,
    'top_staff', v_top_staff
  );
end;
$$;

revoke all on function public.get_booking_analytics(date, date, uuid, uuid) from public;
grant execute on function public.get_booking_analytics(date, date, uuid, uuid) to authenticated;
