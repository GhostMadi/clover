-- Booking: единый источник правды — booking_status_blocks_slot(status).
-- Исправляет рассинхрон после visit-flow (client_arrived, in_progress).

-- --------------------------------------------------------------------------- EXCLUDE + partial indexes
alter table public.bookings
  drop constraint if exists bookings_staff_time_no_overlap;

alter table public.bookings
  add constraint bookings_staff_time_no_overlap
  exclude using gist (
    staff_id with =,
    tstzrange(starts_at, ends_at, '[)') with &&
  )
  where (public.booking_status_blocks_slot(status));

drop index if exists public.bookings_staff_starts_idx;
create index bookings_staff_starts_idx
  on public.bookings (staff_id, starts_at)
  where public.booking_status_blocks_slot(status);

drop index if exists public.bookings_service_future_active_idx;
create index bookings_service_future_active_idx
  on public.bookings (service_id, starts_at)
  where public.booking_status_blocks_slot(status);

-- --------------------------------------------------------------------------- deactivate guard (trigger)
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
         and public.booking_status_blocks_slot(b.status)
         and b.starts_at > now()
     ) then
    raise exception 'service_has_future_bookings' using errcode = 'P0026';
  end if;

  return new;
end;
$$;

-- --------------------------------------------------------------------------- create_booking (client conflict check)
create or replace function public.create_booking(
  p_host_id uuid,
  p_service_id uuid,
  p_staff_id uuid,
  p_starts_at timestamptz,
  p_participants_count int default 1,
  p_client_notes text default null
)
returns uuid
language plpgsql
security definer
set search_path = public
set row_security to off
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

  select * into v_settings
  from public.booking_schedule_settings
  where host_id = p_host_id;

  if found then
    v_tz := v_settings.timezone;
    v_step := v_settings.slot_step_minutes;
  end if;

  if p_starts_at < now() - interval '1 minute' then
    raise exception 'starts_at_in_past' using errcode = 'P0024';
  end if;

  v_day := (p_starts_at at time zone v_tz)::date;

  if v_day > public.booking_last_bookable_day(p_host_id) then
    raise exception 'outside_horizon' using errcode = 'P0024';
  end if;

  select * into v_window
  from public.booking_resolve_staff_day_window(p_staff_id, v_day);

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
    client_notes
  )
  values (
    p_host_id,
    uid,
    p_service_id,
    p_staff_id,
    'pending'::public.booking_status,
    p_starts_at,
    v_slot_end,
    v_service.title,
    v_service.emoji_text,
    v_service.duration_minutes,
    v_service.buffer_after_minutes,
    v_service.price,
    v_service.max_participants,
    coalesce(p_participants_count, 1),
    v_notes
  )
  returning id into v_booking_id;

  insert into public.booking_history (booking_id, actor_id, action, old_status, new_status)
  values (
    v_booking_id,
    uid,
    'created'::public.booking_history_action,
    null,
    'pending'::public.booking_status
  );

  return v_booking_id;
exception
  when exclusion_violation then
    raise exception 'slot_conflict' using errcode = 'P0021';
end;
$$;

-- --------------------------------------------------------------------------- get_booking_availability (host_busy / my_conflict)
create or replace function public.get_booking_availability(
  p_host_id uuid,
  p_service_id uuid,
  p_staff_id uuid,
  p_day date
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
begin
  uid := public.booking_assert_authenticated();

  if p_host_id is null or p_service_id is null or p_staff_id is null or p_day is null then
    raise exception 'invalid_arguments' using errcode = 'P0007';
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

  if not exists (
    select 1
    from public.booking_staff st
    where st.id = p_staff_id
      and st.host_id = p_host_id
      and st.is_active = true
  ) then
    raise exception 'invalid_staff' using errcode = 'P0023';
  end if;

  select * into v_settings
  from public.booking_schedule_settings
  where host_id = p_host_id;

  if found then
    v_tz := v_settings.timezone;
    v_step := v_settings.slot_step_minutes;
  end if;

  if p_day > public.booking_last_bookable_day(p_host_id) then
    return jsonb_build_object(
      'day_unavailable_reason', 'beyond_horizon',
      'slots', '[]'::jsonb,
      'work_start', null,
      'work_end', null,
      'slot_step_minutes', v_step
    );
  end if;

  select * into v_window
  from public.booking_resolve_staff_day_window(p_staff_id, p_day);

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
    v_slot_end := v_cursor + make_interval(mins => v_service.duration_minutes + v_service.buffer_after_minutes);

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
          and public.booking_status_blocks_slot(b.status)
          and public.booking_ranges_overlap(v_cursor, v_slot_end, b.starts_at, b.ends_at)
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
            and public.booking_status_blocks_slot(b.status)
            and public.booking_ranges_overlap(v_cursor, v_slot_end, b.starts_at, b.ends_at)
        )
        or exists (
          select 1
          from public.booking_blocked_slots bs
          where bs.staff_id = p_staff_id
            and public.booking_ranges_overlap(v_cursor, v_slot_end, bs.starts_at, bs.ends_at)
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

-- --------------------------------------------------------------------------- deactivate_booking_service
create or replace function public.deactivate_booking_service(p_service_id uuid)
returns void
language plpgsql
security definer
set search_path = public
set row_security to off
as $$
declare
  uid uuid;
begin
  uid := public.booking_assert_authenticated();

  if exists (
    select 1
    from public.bookings b
    where b.service_id = p_service_id
      and public.booking_status_blocks_slot(b.status)
      and b.starts_at > now()
  ) then
    raise exception 'service_has_future_bookings' using errcode = 'P0026';
  end if;

  update public.booking_services s
  set is_active = false
  where s.id = p_service_id
    and s.host_id = uid;

  if not found then
    raise exception 'service_not_found' using errcode = 'P0008';
  end if;
end;
$$;

notify pgrst, 'reload schema';
