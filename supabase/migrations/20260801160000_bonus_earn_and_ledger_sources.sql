-- Bonus: service earn amount + extensible ledger sources + booking completion earn.

-- --------------------------------------------------------------------------- service earn column
alter table public.booking_services
  add column if not exists bonus_earn_amount int not null default 0;

alter table public.booking_services
  drop constraint if exists booking_services_bonus_earn_amount_nonneg;

alter table public.booking_services
  add constraint booking_services_bonus_earn_amount_nonneg
  check (bonus_earn_amount >= 0);

comment on column public.booking_services.bonus_earn_amount is
  'Сколько бонусов клиент получит за завершённый визит по этой услуге.';

-- Snapshot on booking for historical correctness.
alter table public.bookings
  add column if not exists service_bonus_earn_amount int not null default 0;

comment on column public.bookings.service_bonus_earn_amount is
  'Снапшот bonus_earn_amount услуги на момент создания записи.';

-- --------------------------------------------------------------------------- ledger source (extensible)
do $$ begin
  create type public.bonus_ledger_source as enum (
    'booking_service',
    'booking_payment',
    'manual',
    'promo',
    'welcome'
  );
exception
  when duplicate_object then null;
end $$;

comment on type public.bonus_ledger_source is
  'Источник операции: booking_service — начисление за визит; booking_payment — оплата бонусами; promo/welcome — будущие каналы.';

alter table public.bonus_ledger
  drop column if exists ref_type,
  drop column if exists ref_id;

alter table public.bonus_ledger
  add column if not exists source public.bonus_ledger_source,
  add column if not exists source_id uuid;

update public.bonus_ledger
set source = 'manual'::public.bonus_ledger_source
where source is null;

alter table public.bonus_ledger
  alter column source set not null;

create unique index if not exists bonus_ledger_idempotent_uq
  on public.bonus_ledger (wallet_id, kind, source, source_id)
  where source_id is not null;

create index if not exists bonus_ledger_source_idx
  on public.bonus_ledger (wallet_id, source, created_at desc);

-- --------------------------------------------------------------------------- ensure wallet
create or replace function public.bonus_ensure_wallet(
  p_client_id uuid,
  p_host_id uuid
)
returns uuid
language plpgsql
security definer
set search_path = public
set row_security to off
as $$
declare
  v_wallet_id uuid;
begin
  if p_client_id is null or p_host_id is null or p_client_id = p_host_id then
    raise exception 'invalid_wallet_parties';
  end if;

  insert into public.bonus_wallets (client_id, host_id)
  values (p_client_id, p_host_id)
  on conflict (client_id, host_id) do nothing;

  select w.id into v_wallet_id
  from public.bonus_wallets w
  where w.client_id = p_client_id
    and w.host_id = p_host_id;

  return v_wallet_id;
end;
$$;

revoke all on function public.bonus_ensure_wallet(uuid, uuid) from public;
grant execute on function public.bonus_ensure_wallet(uuid, uuid) to service_role;

-- --------------------------------------------------------------------------- post ledger entry (single write path)
create or replace function public.bonus_post_ledger_entry(
  p_client_id uuid,
  p_host_id uuid,
  p_kind public.bonus_ledger_kind,
  p_amount bigint,
  p_title text,
  p_subtitle text default null,
  p_source public.bonus_ledger_source default 'manual',
  p_source_id uuid default null
)
returns uuid
language plpgsql
security definer
set search_path = public
set row_security to off
as $$
declare
  v_wallet_id uuid;
  v_ledger_id uuid;
begin
  if p_amount is null or p_amount <= 0 then
    return null;
  end if;

  if nullif(trim(coalesce(p_title, '')), '') is null then
    raise exception 'bonus_ledger_title_required';
  end if;

  v_wallet_id := public.bonus_ensure_wallet(p_client_id, p_host_id);
  if v_wallet_id is null then
    raise exception 'bonus_wallet_not_found';
  end if;

  if p_source_id is not null then
    select l.id into v_ledger_id
    from public.bonus_ledger l
    where l.wallet_id = v_wallet_id
      and l.kind = p_kind
      and l.source = p_source
      and l.source_id = p_source_id
    limit 1;

    if v_ledger_id is not null then
      return v_ledger_id;
    end if;
  end if;

  insert into public.bonus_ledger (
    wallet_id,
    kind,
    amount,
    balance_after,
    title,
    subtitle,
    source,
    source_id
  )
  values (
    v_wallet_id,
    p_kind,
    p_amount,
    0,
    trim(p_title),
    nullif(trim(coalesce(p_subtitle, '')), ''),
    p_source,
    p_source_id
  )
  returning id into v_ledger_id;

  return v_ledger_id;
end;
$$;

revoke all on function public.bonus_post_ledger_entry(uuid, uuid, public.bonus_ledger_kind, bigint, text, text, public.bonus_ledger_source, uuid) from public;
grant execute on function public.bonus_post_ledger_entry(uuid, uuid, public.bonus_ledger_kind, bigint, text, text, public.bonus_ledger_source, uuid) to service_role;

-- --------------------------------------------------------------------------- earn on completed booking (booking_service source)
create or replace function public.bonus_apply_booking_service_earn(p_booking_id uuid)
returns uuid
language plpgsql
security definer
set search_path = public
set row_security to off
as $$
declare
  v_booking public.bookings%rowtype;
  v_program public.bonus_program_status;
  v_amount bigint;
begin
  if p_booking_id is null then
    return null;
  end if;

  select * into v_booking
  from public.bookings b
  where b.id = p_booking_id;

  if not found then
    return null;
  end if;

  if v_booking.status <> 'completed'::public.booking_status then
    return null;
  end if;

  v_amount := greatest(coalesce(v_booking.service_bonus_earn_amount, 0), 0);
  if v_amount <= 0 then
    return null;
  end if;

  select pr.bonus_program_status into v_program
  from public.profiles pr
  where pr.id = v_booking.host_id;

  if v_program is distinct from 'active'::public.bonus_program_status then
    return null;
  end if;

  return public.bonus_post_ledger_entry(
    p_client_id => v_booking.client_id,
    p_host_id => v_booking.host_id,
    p_kind => 'earn'::public.bonus_ledger_kind,
    p_amount => v_amount,
    p_title => 'Начисление за визит',
    p_subtitle => v_booking.service_title,
    p_source => 'booking_service'::public.bonus_ledger_source,
    p_source_id => v_booking.id
  );
end;
$$;

revoke all on function public.bonus_apply_booking_service_earn(uuid) from public;
grant execute on function public.bonus_apply_booking_service_earn(uuid) to service_role;

create or replace function public.bonus_on_booking_completed_trigger()
returns trigger
language plpgsql
security definer
set search_path = public
set row_security to off
as $$
begin
  if new.status = 'completed'::public.booking_status
     and old.status is distinct from new.status then
    perform public.bonus_apply_booking_service_earn(new.id);
  end if;
  return new;
end;
$$;

drop trigger if exists trg_bookings_bonus_on_completed on public.bookings;
create trigger trg_bookings_bonus_on_completed
  after update of status on public.bookings
  for each row
  execute function public.bonus_on_booking_completed_trigger();

-- --------------------------------------------------------------------------- create_booking: snapshot bonus_earn_amount
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
    client_notes,
    service_bonus_earn_amount
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
    greatest(coalesce(v_service.bonus_earn_amount, 0), 0)
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

grant execute on function public.create_booking(uuid, uuid, uuid, timestamptz, int, text) to authenticated;

-- --------------------------------------------------------------------------- list_bonus_ledger_cursor (with source)
create or replace function public.list_bonus_ledger_cursor(
  p_host_id uuid,
  p_limit int default 50,
  p_cursor_created_at timestamptz default null,
  p_cursor_id uuid default null
)
returns jsonb
language plpgsql
stable
security invoker
set search_path = public
as $$
declare
  v_wallet_id uuid;
  v_balance bigint := 0;
  v_limit int := least(greatest(coalesce(p_limit, 50), 1), 100);
  v_items jsonb;
  v_count int;
begin
  select w.id, w.balance
  into v_wallet_id, v_balance
  from public.bonus_wallets w
  where w.client_id = auth.uid()
    and w.host_id = p_host_id;

  if v_wallet_id is null then
    return jsonb_build_object(
      'balance', 0,
      'items', '[]'::jsonb,
      'has_more', false
    );
  end if;

  select coalesce(jsonb_agg(row_to_json(e)::jsonb order by e.created_at desc, e.id desc), '[]'::jsonb)
  into v_items
  from (
    select
      l.id,
      l.kind::text as kind,
      l.source::text as source,
      l.source_id,
      l.amount,
      l.balance_after,
      l.title,
      l.subtitle,
      l.created_at
    from public.bonus_ledger l
    where l.wallet_id = v_wallet_id
      and (
        p_cursor_id is null
        or (l.created_at, l.id) < (p_cursor_created_at, p_cursor_id)
      )
    order by l.created_at desc, l.id desc
    limit v_limit + 1
  ) e;

  v_count := jsonb_array_length(v_items);

  if v_count > v_limit then
    v_items := (
      select coalesce(jsonb_agg(elem), '[]'::jsonb)
      from (
        select elem
        from jsonb_array_elements(v_items) with ordinality as t(elem, ord)
        where ord <= v_limit
      ) s
    );
    return jsonb_build_object(
      'balance', v_balance,
      'items', v_items,
      'has_more', true
    );
  end if;

  return jsonb_build_object(
    'balance', v_balance,
    'items', v_items,
    'has_more', false
  );
end;
$$;

notify pgrst, 'reload schema';
