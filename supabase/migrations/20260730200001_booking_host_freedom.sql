-- Booking: свобода для Host, bulk complete, auto-close, reschedule.
-- Enum no_show добавлен в 20260730200000_booking_no_show_enum.sql

alter table public.booking_schedule_settings
  add column if not exists auto_close_hours_after_visit int not null default 3
    constraint booking_schedule_auto_close_hours_nonneg check (auto_close_hours_after_visit >= 0),
  add column if not exists auto_close_target public.booking_status not null default 'completed'::public.booking_status
    constraint booking_schedule_auto_close_target_allowed check (
      auto_close_target in (
        'completed'::public.booking_status,
        'no_show'::public.booking_status
      )
    ),
  add column if not exists client_cancel_hours_before int not null default 0
    constraint booking_schedule_client_cancel_hours_nonneg check (client_cancel_hours_before >= 0);

comment on column public.booking_schedule_settings.auto_close_hours_after_visit is
  'Через сколько часов после ends_at авто-закрыть «зависшие» pending/confirmed записи.';
comment on column public.booking_schedule_settings.auto_close_target is
  'Куда переводить при авто-закрытии: completed или no_show.';
comment on column public.booking_schedule_settings.client_cancel_hours_before is
  'Клиент может отменить не позднее чем за N часов до starts_at (0 = до начала).';

-- --------------------------------------------------------------------------- helpers
create or replace function public.booking_status_is_terminal(p_status public.booking_status)
returns boolean
language sql
immutable
as $$
  select p_status in (
    'completed'::public.booking_status,
    'cancelled'::public.booking_status,
    'no_show'::public.booking_status
  );
$$;

create or replace function public.booking_status_blocks_slot(p_status public.booking_status)
returns boolean
language sql
immutable
as $$
  select p_status in (
    'pending'::public.booking_status,
    'confirmed'::public.booking_status,
    'client_arrived'::public.booking_status,
    'in_progress'::public.booking_status
  );
$$;

create or replace function public.booking_assert_staff_slot_available(
  p_staff_id uuid,
  p_starts_at timestamptz,
  p_ends_at timestamptz,
  p_exclude_booking_id uuid default null
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

-- --------------------------------------------------------------------------- update_booking_status (host freedom)
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

    select coalesce(s.client_cancel_hours_before, 0)
    into v_cancel_hours
    from public.booking_schedule_settings s
    where s.host_id = v_booking.host_id;

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

-- --------------------------------------------------------------------------- reschedule_booking
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
  v_old_starts timestamptz;
  v_old_ends timestamptz;
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

  if v_booking.host_id <> uid then
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

  v_old_starts := v_booking.starts_at;
  v_old_ends := v_booking.ends_at;

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

  -- Доп. audit через comment в action не нужен — old/new time в metadata позже; v1 достаточно rescheduled.
end;
$$;

revoke all on function public.reschedule_booking(uuid, uuid, timestamptz, public.booking_status) from public;
grant execute on function public.reschedule_booking(uuid, uuid, timestamptz, public.booking_status) to authenticated;

-- --------------------------------------------------------------------------- auto-close stale visits
create or replace function public.booking_auto_close_stale_visits()
returns int
language plpgsql
security definer
set search_path = public
set row_security to off
as $$
declare
  v_row record;
  v_closed int := 0;
  v_target public.booking_status;
  v_now timestamptz := now();
begin
  for v_row in
    select
      b.id,
      b.status,
      coalesce(s.auto_close_hours_after_visit, 3) as close_hours,
      coalesce(s.auto_close_target, 'completed'::public.booking_status) as close_target
    from public.bookings b
    left join public.booking_schedule_settings s on s.host_id = b.host_id
    where b.status in (
      'pending'::public.booking_status,
      'confirmed'::public.booking_status
    )
      and b.ends_at + make_interval(hours => coalesce(s.auto_close_hours_after_visit, 3)) <= v_now
    for update skip locked
  loop
    v_target := v_row.close_target;

    if v_target = 'no_show'::public.booking_status then
      update public.bookings
      set status = v_target,
          no_show_at = v_now
      where id = v_row.id;
    else
      update public.bookings
      set status = 'completed'::public.booking_status,
          confirmed_at = coalesce(confirmed_at, v_now),
          client_arrived_at = coalesce(client_arrived_at, v_now),
          service_started_at = coalesce(service_started_at, v_now),
          completed_at = v_now
      where id = v_row.id;
      v_target := 'completed'::public.booking_status;
    end if;

    insert into public.booking_history (booking_id, actor_id, action, old_status, new_status)
    values (
      v_row.id,
      null,
      'auto_closed'::public.booking_history_action,
      v_row.status,
      v_target
    );

    v_closed := v_closed + 1;
  end loop;

  return v_closed;
end;
$$;

revoke all on function public.booking_auto_close_stale_visits() from public;
grant execute on function public.booking_auto_close_stale_visits() to service_role;

-- Cron (best-effort): каждый час.
do $$
begin
  perform cron.unschedule('booking_auto_close_stale_visits');
exception
  when undefined_function then null;
  when undefined_table then null;
  when others then null;
end $$;

do $$
begin
  perform cron.schedule(
    'booking_auto_close_stale_visits',
    '0 * * * *',
    $cron$select public.booking_auto_close_stale_visits();$cron$
  );
exception
  when undefined_function then null;
  when undefined_table then null;
end $$;

notify pgrst, 'reload schema';
