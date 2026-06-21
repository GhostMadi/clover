-- Booking module: SECURITY DEFINER RPC (mutations + enriched lists + availability + analytics).

create or replace function public.booking_assert_authenticated()
returns uuid
language plpgsql
stable
security definer
set search_path = public
set row_security to off
as $$
declare
  uid uuid;
begin
  uid := auth.uid();
  if uid is null then
    raise exception 'not_authenticated' using errcode = 'P0003';
  end if;
  return uid;
end;
$$;

-- --------------------------------------------------------------------------- create_booking
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
    and b.status in ('pending'::public.booking_status, 'confirmed'::public.booking_status)
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

-- --------------------------------------------------------------------------- get_booking_availability
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
          and b.status in ('pending'::public.booking_status, 'confirmed'::public.booking_status)
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
            and b.status in ('pending'::public.booking_status, 'confirmed'::public.booking_status)
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

-- --------------------------------------------------------------------------- list_host_bookings_enriched
create or replace function public.list_host_bookings_enriched(
  p_from timestamptz,
  p_to timestamptz,
  p_query text default null,
  p_cursor jsonb default null,
  p_limit int default 50
)
returns setof jsonb
language plpgsql
stable
security definer
set search_path = public
set row_security to off
as $$
declare
  uid uuid;
  v_limit int;
  v_q text;
begin
  uid := public.booking_assert_authenticated();
  v_limit := greatest(1, least(coalesce(p_limit, 50), 100));
  v_q := nullif(trim(coalesce(p_query, '')), '');

  return query
  select jsonb_build_object(
    'id', b.id,
    'client_name', coalesce(cp.full_name, ''),
    'client_username', cp.username,
    'client_phone', cp.phone,
    'service_title', b.service_title,
    'service_emoji', b.service_emoji,
    'duration_minutes', b.duration_minutes,
    'price', b.price,
    'executor_name', st.display_name,
    'starts_at', b.starts_at,
    'status', b.status,
    'notes', b.client_notes,
    'participants_count', b.participants_count,
    'created_at', b.created_at
  )
  from public.bookings b
  join public.profiles cp on cp.id = b.client_id
  join public.booking_staff st on st.id = b.staff_id
  where b.host_id = uid
    and b.starts_at >= coalesce(p_from, '-infinity'::timestamptz)
    and b.starts_at <= coalesce(p_to, 'infinity'::timestamptz)
    and (
      v_q is null
      or char_length(v_q) < 2
      or cp.full_name ilike ('%' || v_q || '%')
      or cp.username ilike ('%' || v_q || '%')
      or cp.phone ilike ('%' || v_q || '%')
      or b.service_title ilike ('%' || v_q || '%')
    )
    and (
      p_cursor is null
      or b.starts_at > coalesce((p_cursor ->> 'starts_at')::timestamptz, '-infinity'::timestamptz)
      or (
        b.starts_at = (p_cursor ->> 'starts_at')::timestamptz
        and b.id > coalesce((p_cursor ->> 'id')::uuid, '00000000-0000-0000-0000-000000000000'::uuid)
      )
    )
  order by b.starts_at asc, b.id asc
  limit v_limit;
end;
$$;

-- --------------------------------------------------------------------------- list_my_bookings_enriched
create or replace function public.list_my_bookings_enriched(
  p_from timestamptz,
  p_to timestamptz,
  p_cursor jsonb default null,
  p_limit int default 50
)
returns setof jsonb
language plpgsql
stable
security definer
set search_path = public
set row_security to off
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
    'service_title', b.service_title,
    'service_emoji', b.service_emoji,
    'duration_minutes', b.duration_minutes,
    'price', b.price,
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
        and b.id > coalesce((p_cursor ->> 'id')::uuid, '00000000-0000-0000-0000-000000000000'::uuid)
      )
    )
  order by b.starts_at asc, b.id asc
  limit v_limit;
end;
$$;

-- --------------------------------------------------------------------------- update_booking_status
create or replace function public.update_booking_status(
  p_booking_id uuid,
  p_status public.booking_status
)
returns void
language plpgsql
security definer
set search_path = public
set row_security to off
as $$
declare
  uid uuid;
  v_booking public.bookings%rowtype;
  v_is_host boolean;
  v_is_client boolean;
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

  if p_status = 'confirmed'::public.booking_status then
    if not v_is_host or v_booking.status <> 'pending'::public.booking_status then
      raise exception 'invalid_status_transition' using errcode = 'P0011';
    end if;
    update public.bookings
    set status = p_status,
        confirmed_at = now()
    where id = p_booking_id;

  elsif p_status = 'completed'::public.booking_status then
    if not v_is_host or v_booking.status <> 'confirmed'::public.booking_status then
      raise exception 'invalid_status_transition' using errcode = 'P0011';
    end if;
    update public.bookings
    set status = p_status,
        completed_at = now()
    where id = p_booking_id;

  elsif p_status = 'cancelled'::public.booking_status then
    if v_booking.status in ('completed'::public.booking_status, 'cancelled'::public.booking_status) then
      raise exception 'invalid_status_transition' using errcode = 'P0011';
    end if;

    if v_is_client and not v_is_host then
      if v_booking.status not in ('pending'::public.booking_status, 'confirmed'::public.booking_status) then
        raise exception 'invalid_status_transition' using errcode = 'P0011';
      end if;
      if v_booking.starts_at <= now() then
        raise exception 'cancel_too_late' using errcode = 'P0011';
      end if;
    end if;

    update public.bookings
    set status = p_status,
        cancelled_at = now(),
        cancelled_by = uid
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
      and b.status in ('pending'::public.booking_status, 'confirmed'::public.booking_status)
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

-- --------------------------------------------------------------------------- get_booking_analytics
create or replace function public.get_booking_analytics(
  p_from date,
  p_to date,
  p_staff_id uuid default null
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
begin
  uid := public.booking_assert_authenticated();

  select
    count(*)::bigint,
    count(*) filter (where b.status = 'pending')::bigint,
    count(*) filter (where b.status = 'confirmed')::bigint,
    count(*) filter (where b.status = 'completed')::bigint,
    count(*) filter (where b.status = 'cancelled')::bigint,
    coalesce(sum(b.price) filter (where b.status = 'completed'), 0)
  into v_total, v_pending, v_confirmed, v_completed, v_cancelled, v_revenue
  from public.bookings b
  where b.host_id = uid
    and (b.starts_at at time zone coalesce(
      (select timezone from public.booking_schedule_settings where host_id = uid),
      'Asia/Almaty'
    ))::date between p_from and p_to
    and (p_staff_id is null or b.staff_id = p_staff_id);

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
    where b.host_id = uid
      and (b.starts_at at time zone coalesce(
        (select timezone from public.booking_schedule_settings where host_id = uid),
        'Asia/Almaty'
      ))::date between p_from and p_to
      and (p_staff_id is null or b.staff_id = p_staff_id)
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
    where b.host_id = uid
      and (b.starts_at at time zone coalesce(
        (select timezone from public.booking_schedule_settings where host_id = uid),
        'Asia/Almaty'
      ))::date between p_from and p_to
      and (p_staff_id is null or b.staff_id = p_staff_id)
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

-- --------------------------------------------------------------------------- grants
grant execute on function public.booking_assert_authenticated() to authenticated;
grant execute on function public.create_booking(uuid, uuid, uuid, timestamptz, int, text) to authenticated;
grant execute on function public.get_booking_availability(uuid, uuid, uuid, date) to authenticated;
grant execute on function public.list_host_bookings_enriched(timestamptz, timestamptz, text, jsonb, int) to authenticated;
grant execute on function public.list_my_bookings_enriched(timestamptz, timestamptz, jsonb, int) to authenticated;
grant execute on function public.update_booking_status(uuid, public.booking_status) to authenticated;
grant execute on function public.deactivate_booking_service(uuid) to authenticated;
grant execute on function public.get_booking_analytics(date, date, uuid) to authenticated;
