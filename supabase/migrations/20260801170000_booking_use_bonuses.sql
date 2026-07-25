-- Booking: client preference to pay with bonuses (default on).

alter table public.bookings
  add column if not exists use_bonuses boolean not null default true;

comment on column public.bookings.use_bonuses is
  'Клиент разрешил списание бонусов при оплате этой записи.';

create or replace function public.create_booking(
  p_host_id uuid,
  p_service_id uuid,
  p_staff_id uuid,
  p_starts_at timestamptz,
  p_participants_count int default 1,
  p_client_notes text default null,
  p_use_bonuses boolean default true
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
    client_notes,
    service_bonus_earn_amount,
    use_bonuses
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
    v_notes,
    greatest(coalesce(v_service.bonus_earn_amount, 0), 0),
    coalesce(p_use_bonuses, true)
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

grant execute on function public.create_booking(uuid, uuid, uuid, timestamptz, int, text, boolean) to authenticated;

notify pgrst, 'reload schema';
