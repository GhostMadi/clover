-- Booking push_outbox + client reschedule; attendance duty_only + folders bootstrap.
-- Process: docs/business/booking.md, docs/business/attendance.md

-- --------------------------------------------------------------------------- booking: enqueue push with in-app
create or replace function public.booking_enqueue_push(
  p_user_id uuid,
  p_kind text,
  p_title text,
  p_body text,
  p_payload jsonb
)
returns void
language plpgsql
security definer
set search_path = public
set row_security to off
as $$
begin
  if p_user_id is null then
    return;
  end if;
  insert into public.push_outbox (user_id, kind, title, body, payload)
  values (
    p_user_id,
    coalesce(nullif(trim(p_kind), ''), 'booking'),
    coalesce(nullif(trim(p_title), ''), 'Clover'),
    coalesce(nullif(trim(p_body), ''), ''),
    coalesce(p_payload, '{}'::jsonb)
  );
exception
  when undefined_table then null;
end;
$$;

create or replace function public.booking_notify_created(p_booking public.bookings)
returns void
language plpgsql
security definer
set search_path = public
set row_security to off
as $$
declare
  v_payload jsonb := public.booking_notification_payload(p_booking);
begin
  perform public.upsert_notification(
    p_recipient_id := p_booking.host_id,
    p_actor_id := p_booking.client_id,
    p_kind := 'booking_created_host',
    p_dedupe_key := 'booking:' || p_booking.id::text || ':created:host',
    p_payload := v_payload,
    p_booking_id := p_booking.id
  );
  perform public.booking_enqueue_push(
    p_booking.host_id,
    'booking_created_host',
    'Новая запись',
    'Клиент записался на «' || coalesce(p_booking.service_title, 'услугу') || '»',
    v_payload
  );

  perform public.upsert_notification(
    p_recipient_id := p_booking.client_id,
    p_actor_id := p_booking.host_id,
    p_kind := 'booking_booked_client',
    p_dedupe_key := 'booking:' || p_booking.id::text || ':created:client',
    p_payload := v_payload,
    p_booking_id := p_booking.id
  );
  perform public.booking_enqueue_push(
    p_booking.client_id,
    'booking_booked_client',
    'Запись подтверждена',
    'Вы записаны на «' || coalesce(p_booking.service_title, 'услугу') || '»',
    v_payload
  );
end;
$$;

create or replace function public.booking_notify_status_change(
  p_booking public.bookings,
  p_old_status public.booking_status
)
returns void
language plpgsql
security definer
set search_path = public
set row_security to off
as $$
declare
  v_payload jsonb := public.booking_notification_payload(p_booking);
begin
  if p_old_status = p_booking.status then
    return;
  end if;

  if public.booking_status_is_terminal(p_booking.status) then
    perform public.booking_notification_clear_visit_reminders(p_booking.id);
  end if;

  if p_booking.status = 'cancelled'::public.booking_status then
    if p_booking.cancelled_by = p_booking.client_id then
      perform public.upsert_notification(
        p_recipient_id := p_booking.host_id,
        p_actor_id := p_booking.client_id,
        p_kind := 'booking_cancelled_host',
        p_dedupe_key := 'booking:' || p_booking.id::text || ':cancelled:host',
        p_payload := v_payload,
        p_booking_id := p_booking.id
      );
      perform public.booking_enqueue_push(
        p_booking.host_id, 'booking_cancelled_host', 'Запись отменена',
        'Клиент отменил «' || coalesce(p_booking.service_title, 'услугу') || '»', v_payload
      );
    elsif p_booking.cancelled_by = p_booking.host_id then
      perform public.upsert_notification(
        p_recipient_id := p_booking.client_id,
        p_actor_id := p_booking.host_id,
        p_kind := 'booking_cancelled_client',
        p_dedupe_key := 'booking:' || p_booking.id::text || ':cancelled:client',
        p_payload := v_payload,
        p_booking_id := p_booking.id
      );
      perform public.booking_enqueue_push(
        p_booking.client_id, 'booking_cancelled_client', 'Запись отменена',
        'Хозяин отменил «' || coalesce(p_booking.service_title, 'услугу') || '»', v_payload
      );
    end if;
    return;
  end if;

  if p_booking.status = 'completed'::public.booking_status then
    perform public.upsert_notification(
      p_recipient_id := p_booking.client_id,
      p_actor_id := p_booking.host_id,
      p_kind := 'booking_completed_client',
      p_dedupe_key := 'booking:' || p_booking.id::text || ':completed:client',
      p_payload := v_payload,
      p_booking_id := p_booking.id
    );
    perform public.booking_enqueue_push(
      p_booking.client_id, 'booking_completed_client', 'Визит завершён',
      '«' || coalesce(p_booking.service_title, 'Услуга') || '» отмечена как оказанная', v_payload
    );
    return;
  end if;

  if p_booking.status = 'no_show'::public.booking_status then
    perform public.upsert_notification(
      p_recipient_id := p_booking.client_id,
      p_actor_id := p_booking.host_id,
      p_kind := 'booking_no_show_client',
      p_dedupe_key := 'booking:' || p_booking.id::text || ':no_show:client',
      p_payload := v_payload,
      p_booking_id := p_booking.id
    );
    perform public.booking_enqueue_push(
      p_booking.client_id, 'booking_no_show_client', 'Неявка',
      'Запись отмечена как «не пришёл»', v_payload
    );
  end if;
end;
$$;

-- Client or host may reschedule (client: own future confirmed/pending, same staff, cancel-window)
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
set row_security to off
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

  if v_is_client and not v_is_host then
    if v_booking.status not in (
      'pending'::public.booking_status,
      'confirmed'::public.booking_status
    ) then
      raise exception 'invalid_status_transition' using errcode = 'P0011';
    end if;
    select coalesce(s.client_cancel_hours_before, 0) into v_cancel_hours
    from public.booking_schedule_settings s where s.host_id = v_booking.host_id;
    v_cancel_hours := coalesce(v_cancel_hours, 0);
    if v_booking.starts_at <= now() + make_interval(hours => v_cancel_hours) then
      raise exception 'forbidden' using errcode = 'P0009';
    end if;
    p_staff_id := v_booking.staff_id;
  end if;

  select * into v_service
  from public.booking_services s
  where s.id = v_booking.service_id
    and s.host_id = v_booking.host_id
    and s.is_active = true;

  if not found then
    raise exception 'invalid_service' using errcode = 'P0022';
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

  select * into v_settings
  from public.booking_schedule_settings
  where host_id = v_booking.host_id;

  if found then
    v_tz := v_settings.timezone;
    v_step := v_settings.slot_step_minutes;
  end if;

  if p_starts_at < now() - interval '1 minute' then
    raise exception 'starts_at_in_past' using errcode = 'P0024';
  end if;

  v_day := (p_starts_at at time zone v_tz)::date;

  if v_day > public.booking_last_bookable_day(v_booking.host_id) then
    raise exception 'outside_horizon' using errcode = 'P0024';
  end if;

  select * into v_window
  from public.booking_resolve_staff_day_window(p_staff_id, v_day);

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
    'staff_id', b.staff_id,
    'client_cancel_hours_before', coalesce((
      select s.client_cancel_hours_before from public.booking_schedule_settings s
      where s.host_id = b.host_id
    ), 0),
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

-- --------------------------------------------------------------------------- attendance: duty_only + folders
alter table public.attendance_workplaces
  add column if not exists duty_only_punch boolean not null default false;

comment on column public.attendance_workplaces.duty_only_punch is
  'When true, only today''s on-duty worker may punch (clock_in/out/custom).';

create or replace function public.attendance_is_on_duty_today(
  p_roster jsonb,
  p_profile_id uuid,
  p_day date default (timezone('Asia/Almaty', now()))::date
)
returns boolean
language plpgsql
stable
security definer
set search_path = public
set row_security to off
as $$
declare
  ids jsonb;
  days jsonb;
  start_raw text;
  start_d date;
  cursor_d date;
  idx int := 0;
  n int;
  wd int;
begin
  if p_roster is null or p_profile_id is null then
    return false;
  end if;
  ids := coalesce(p_roster->'worker_ids', '[]'::jsonb);
  n := jsonb_array_length(ids);
  if n = 0 then
    return false;
  end if;
  days := coalesce(p_roster->'working_weekdays', '[1,2,3,4,5]'::jsonb);
  wd := extract(isodow from p_day)::int;
  if not (days @> to_jsonb(wd)) then
    return false;
  end if;
  start_raw := nullif(p_roster->>'start_date', '');
  start_d := coalesce(start_raw::date, date_trunc('month', p_day)::date);
  cursor_d := start_d;
  while cursor_d < p_day loop
    if days @> to_jsonb(extract(isodow from cursor_d)::int) then
      idx := idx + 1;
    end if;
    cursor_d := cursor_d + 1;
  end loop;
  return (ids ->> (idx % n)) = p_profile_id::text;
end;
$$;

create or replace function public.attendance_workplace_to_json(p_w public.attendance_workplaces)
returns jsonb
language sql
stable
security definer
set search_path = public
set row_security to off
as $$
  select jsonb_build_object(
    'id', p_w.id,
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
    'payroll_rules', coalesce(p_w.payroll_rules, '{}'::jsonb),
    'duty_roster', coalesce(p_w.duty_roster, '{}'::jsonb),
    'duty_only_punch', coalesce(p_w.duty_only_punch, false),
    'group_conversation_id', p_w.group_conversation_id,
    'is_admin', p_w.owner_id = auth.uid(),
    'updated_at', p_w.updated_at
  );
$$;

create or replace function public.attendance_create_folder(p_name text)
returns uuid
language plpgsql
security definer
set search_path = public
set row_security to off
as $$
declare
  uid uuid;
  v_id uuid;
  v_name text;
begin
  uid := public.attendance_assert_authenticated();
  v_name := nullif(trim(coalesce(p_name, '')), '');
  if v_name is null then
    raise exception 'invalid_arguments' using errcode = 'P0101';
  end if;
  insert into public.attendance_folders (owner_id, name)
  values (uid, left(v_name, 80))
  returning id into v_id;
  return v_id;
end;
$$;

grant execute on function public.attendance_create_folder(text) to authenticated;

create or replace function public.attendance_set_workplace_folder(
  p_workplace_id uuid,
  p_folder_id uuid default null
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
  if p_workplace_id is null then
    raise exception 'invalid_arguments' using errcode = 'P0101';
  end if;
  if not public.attendance_is_workplace_owner(p_workplace_id, uid) then
    raise exception 'forbidden' using errcode = 'P0102';
  end if;
  if p_folder_id is not null and not exists (
    select 1 from public.attendance_folders f where f.id = p_folder_id and f.owner_id = uid
  ) then
    raise exception 'not_found' using errcode = 'P0103';
  end if;
  update public.attendance_workplaces set folder_id = p_folder_id where id = p_workplace_id;
end;
$$;

grant execute on function public.attendance_set_workplace_folder(uuid, uuid) to authenticated;



-- --------------------------------------------------------------------------- submit punch: duty_only gate
create or replace function public.submit_attendance_punch(
  p_workplace_id uuid,
  p_punch_kind public.attendance_punch_kind,
  p_lat double precision,
  p_lng double precision,
  p_punch_type_id uuid default null,
  p_client_punch_id text default null,
  p_punched_at timestamptz default null
)
returns uuid
language plpgsql
security definer
set search_path = public
set row_security to off
as $$
declare
  uid uuid;
  v_w public.attendance_workplaces%rowtype;
  v_m public.attendance_memberships%rowtype;
  v_id uuid;
  v_open boolean;
  v_at timestamptz;
  v_user_loc geography(point, 4326);
begin
  uid := public.attendance_assert_authenticated();

  if p_workplace_id is null or p_punch_kind is null then
    raise exception 'invalid_arguments' using errcode = 'P0101';
  end if;

  if p_client_punch_id is not null then
    select id into v_id
    from public.attendance_punches
    where profile_id = uid and client_punch_id = p_client_punch_id;
    if found then
      return v_id;
    end if;
  end if;

  select * into v_w from public.attendance_workplaces where id = p_workplace_id;
  if not found then
    raise exception 'not_found' using errcode = 'P0103';
  end if;

  select * into v_m
  from public.attendance_memberships
  where workplace_id = p_workplace_id and profile_id = uid;

  if not found or v_m.status <> 'active' then
    raise exception 'not_active_member' using errcode = 'P0104';
  end if;

  if v_m.ack_version < v_w.config_version then
    raise exception 'needs_ack' using errcode = 'P0105';
  end if;

  if coalesce(v_w.duty_only_punch, false)
     and not public.attendance_is_on_duty_today(v_w.duty_roster, uid) then
    raise exception 'not_on_duty' using errcode = 'P0110';
  end if;

  if v_w.location is null then
    raise exception 'location_required' using errcode = 'P0107';
  end if;
  if p_lat is null or p_lng is null then
    raise exception 'location_required' using errcode = 'P0107';
  end if;

  v_user_loc := st_setsrid(st_makepoint(p_lng, p_lat), 4326)::geography;
  if not st_dwithin(v_w.location, v_user_loc, v_w.geofence_radius_m) then
    raise exception 'outside_geofence' using errcode = 'P0106';
  end if;

  if p_punch_kind = 'clock_in' and not v_w.clock_in_enabled then
    raise exception 'invalid_punch' using errcode = 'P0108';
  end if;
  if p_punch_kind = 'clock_out' and not v_w.clock_out_enabled then
    raise exception 'invalid_punch' using errcode = 'P0108';
  end if;
  if p_punch_kind = 'custom' then
    if p_punch_type_id is null or not exists (
      select 1 from public.attendance_punch_type_defs t
      where t.id = p_punch_type_id and t.workplace_id = p_workplace_id and t.is_active
    ) then
      raise exception 'punch_type_invalid' using errcode = 'P0109';
    end if;
  elsif p_punch_type_id is not null then
    raise exception 'punch_type_invalid' using errcode = 'P0109';
  end if;

  v_open := public.attendance_shift_is_open(v_m.id);
  if p_punch_kind = 'clock_in' and v_open then
    raise exception 'invalid_punch' using errcode = 'P0108';
  end if;
  if p_punch_kind = 'clock_out' and not v_open then
    raise exception 'invalid_punch' using errcode = 'P0108';
  end if;

  v_at := coalesce(p_punched_at, now());
  if v_at > now() + interval '2 minutes' then
    raise exception 'invalid_arguments' using errcode = 'P0101';
  end if;

  insert into public.attendance_punches (
    workplace_id, membership_id, profile_id, punch_kind, punch_type_id, punched_at, client_punch_id
  ) values (
    p_workplace_id, v_m.id, uid, p_punch_kind, p_punch_type_id, v_at, p_client_punch_id
  )
  returning id into v_id;

  return v_id;
end;
$$;

create or replace function public.attendance_set_duty_only_punch(
  p_workplace_id uuid,
  p_duty_only_punch boolean
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
  if p_workplace_id is null or p_duty_only_punch is null then
    raise exception 'invalid_arguments' using errcode = 'P0101';
  end if;
  if not public.attendance_is_workplace_owner(p_workplace_id, uid) then
    raise exception 'forbidden' using errcode = 'P0102';
  end if;
  update public.attendance_workplaces
  set duty_only_punch = p_duty_only_punch,
      updated_at = now()
  where id = p_workplace_id;
end;
$$;

grant execute on function public.attendance_set_duty_only_punch(uuid, boolean) to authenticated;
grant execute on function public.attendance_is_on_duty_today(jsonb, uuid, date) to authenticated;

-- --------------------------------------------------------------------------- bootstrap: folders
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
  v_folders jsonb;
begin
  uid := public.attendance_assert_authenticated();

  select coalesce(jsonb_agg(jsonb_build_object(
      'id', f.id,
      'name', f.name
    ) order by f.name), '[]'::jsonb)
  into v_folders
  from public.attendance_folders f
  where f.owner_id = uid;

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
    'folders', v_folders,
    'memberships', v_memberships,
    'punch_types', v_types,
    'punches', v_punches,
    'absences', v_absences,
    'overtime_entries', v_overtime,
    'revision', public.attendance_revision_me()
  );
end;
$$;

notify pgrst, 'reload schema';
