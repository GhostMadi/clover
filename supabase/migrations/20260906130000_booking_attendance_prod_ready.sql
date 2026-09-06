-- Booking + attendance production-ready RPCs.
-- Product: docs/business/booking.md, docs/business/attendance.md
-- Specs: docs/supabase/SPEC_BOOKING_SYSTEM.md, docs/supabase/SPEC_ATTENDANCE_SYSTEM.md
--
-- Notes:
-- * Custom punch types are replaced atomically and bump workplace config_version.
-- * Payroll preview is owner-only and computes server-side from active memberships,
--   punches, formal absences, approved overtime, and workplace/override rules.
-- * Booking enriched payloads expose service_id (and staff_id in detail payloads).
-- * Availability accepts an optional booking id to exclude during rescheduling.

-- --------------------------------------------------------------------------- attendance: replace custom punch types
create or replace function public.attendance_replace_punch_types(
  p_workplace_id uuid,
  p_types jsonb
)
returns void
language plpgsql
security definer
set search_path = public
set row_security to off
as $$
declare
  uid uuid;
  v_item jsonb;
  v_ordinality bigint;
  v_id uuid;
  v_label text;
  v_scheduled_text text;
  v_scheduled_time time;
  v_sort_order int;
  v_keep_ids uuid[] := array[]::uuid[];
begin
  uid := public.attendance_assert_authenticated();

  if p_workplace_id is null
     or p_types is null
     or jsonb_typeof(p_types) <> 'array' then
    raise exception 'invalid_arguments' using errcode = 'P0101';
  end if;

  if not public.attendance_is_workplace_owner(p_workplace_id, uid) then
    raise exception 'forbidden' using errcode = 'P0102';
  end if;

  -- Validate the whole payload before changing any row, and collect only ids
  -- that already belong to this workplace.
  for v_item, v_ordinality in
    select value, ordinality
    from jsonb_array_elements(p_types) with ordinality
  loop
    if jsonb_typeof(v_item) <> 'object' then
      raise exception 'invalid_arguments' using errcode = 'P0101';
    end if;

    v_label := trim(coalesce(v_item ->> 'label', ''));
    if v_label = '' then
      raise exception 'invalid_arguments' using errcode = 'P0101';
    end if;

    v_id := null;
    if v_item ? 'id' and jsonb_typeof(v_item -> 'id') <> 'null' then
      begin
        v_id := (v_item ->> 'id')::uuid;
      exception
        when invalid_text_representation then
          raise exception 'invalid_arguments' using errcode = 'P0101';
      end;
    end if;

    v_scheduled_text := nullif(trim(coalesce(v_item ->> 'scheduled_time', '')), '');
    if v_scheduled_text is not null then
      if v_scheduled_text !~ '^(?:[01][0-9]|2[0-3]):[0-5][0-9](?::[0-5][0-9])?$' then
        raise exception 'invalid_arguments' using errcode = 'P0101';
      end if;
      v_scheduled_time := v_scheduled_text::time;
    else
      v_scheduled_time := null;
    end if;

    if v_item ? 'sort_order' and jsonb_typeof(v_item -> 'sort_order') <> 'null' then
      if jsonb_typeof(v_item -> 'sort_order') <> 'number'
         or (v_item ->> 'sort_order') !~ '^-?[0-9]+$' then
        raise exception 'invalid_arguments' using errcode = 'P0101';
      end if;
      begin
        v_sort_order := (v_item ->> 'sort_order')::int;
      exception
        when numeric_value_out_of_range then
          raise exception 'invalid_arguments' using errcode = 'P0101';
      end;
    else
      v_sort_order := (v_ordinality - 1)::int;
    end if;

    if v_id is not null and exists (
      select 1
      from public.attendance_punch_type_defs t
      where t.id = v_id
        and t.workplace_id = p_workplace_id
    ) then
      v_keep_ids := array_append(v_keep_ids, v_id);
    end if;
  end loop;

  update public.attendance_punch_type_defs t
  set is_active = false
  where t.workplace_id = p_workplace_id
    and t.is_active
    and not (t.id = any(v_keep_ids));

  for v_item, v_ordinality in
    select value, ordinality
    from jsonb_array_elements(p_types) with ordinality
  loop
    v_id := null;
    if v_item ? 'id' and jsonb_typeof(v_item -> 'id') <> 'null' then
      v_id := (v_item ->> 'id')::uuid;
    end if;

    v_label := trim(v_item ->> 'label');
    v_scheduled_text := nullif(trim(coalesce(v_item ->> 'scheduled_time', '')), '');
    v_scheduled_time := case
      when v_scheduled_text is null then null
      else v_scheduled_text::time
    end;
    v_sort_order := case
      when v_item ? 'sort_order' and jsonb_typeof(v_item -> 'sort_order') <> 'null'
        then (v_item ->> 'sort_order')::int
      else (v_ordinality - 1)::int
    end;

    update public.attendance_punch_type_defs t
    set label = v_label,
        scheduled_time = v_scheduled_time,
        sort_order = v_sort_order,
        is_active = true
    where t.id = v_id
      and t.workplace_id = p_workplace_id;

    if not found then
      -- Preserve a client-provided id only when it is globally unused. A foreign
      -- workplace id must never be moved or overwritten.
      if v_id is not null and exists (
        select 1 from public.attendance_punch_type_defs t where t.id = v_id
      ) then
        v_id := gen_random_uuid();
      end if;

      insert into public.attendance_punch_type_defs (
        id,
        workplace_id,
        label,
        scheduled_time,
        sort_order,
        is_active
      )
      values (
        coalesce(v_id, gen_random_uuid()),
        p_workplace_id,
        v_label,
        v_scheduled_time,
        v_sort_order,
        true
      );
    end if;
  end loop;

  update public.attendance_workplaces
  set config_version = config_version + 1,
      updated_at = now()
  where id = p_workplace_id;
end;
$$;

-- --------------------------------------------------------------------------- attendance: payroll preview
create or replace function public.attendance_payroll_preview(
  p_workplace_id uuid,
  p_start date,
  p_end date,
  p_rules jsonb default null
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
  v_workplace public.attendance_workplaces%rowtype;
  v_rules jsonb;
  v_late_deducts boolean;
  v_overtime_adds boolean;
  v_absence_deducts boolean;
  v_partial_deducts boolean;
  v_late_rate int;
  v_overtime_rate int;
  v_absence_rate int;
  v_partial_percent int;
  v_period_label text;
  v_workers jsonb := '[]'::jsonb;
  v_worker record;
  v_day date;
  v_clock_in timestamptz;
  v_clock_out timestamptz;
  v_has_absence boolean;
  v_late_minutes int;
  v_late_minutes_total int;
  v_late_days int;
  v_absent_days int;
  v_partial_days int;
  v_overtime_hours int;
  v_absence_kinds text;
  v_base_salary int;
  v_lines jsonb;
  v_deduction_amount int;
  v_bonus_amount int;
  v_net_pay int;
  v_team_base bigint := 0;
  v_team_deductions bigint := 0;
  v_team_bonuses bigint := 0;
  v_team_net bigint := 0;
begin
  uid := public.attendance_assert_authenticated();

  if p_workplace_id is null
     or p_start is null
     or p_end is null
     or p_end < p_start
     or (p_rules is not null and jsonb_typeof(p_rules) <> 'object') then
    raise exception 'invalid_arguments' using errcode = 'P0101';
  end if;

  if not public.attendance_is_workplace_owner(p_workplace_id, uid) then
    raise exception 'forbidden' using errcode = 'P0102';
  end if;

  select *
  into v_workplace
  from public.attendance_workplaces w
  where w.id = p_workplace_id;

  if not found then
    raise exception 'forbidden' using errcode = 'P0102';
  end if;

  v_rules := jsonb_build_object(
    'late_deducts_pay', false,
    'overtime_adds_pay', false,
    'absence_deducts_pay', true,
    'partial_day_deducts_pay', false,
    'late_deduct_per_minute', 50,
    'overtime_bonus_per_hour', 1500,
    'absence_deduct_per_day', 12000,
    'partial_day_deduct_percent', 50
  ) || coalesce(p_rules, v_workplace.payroll_rules, '{}'::jsonb);

  begin
    v_late_deducts := coalesce((v_rules ->> 'late_deducts_pay')::boolean, false);
    v_overtime_adds := coalesce((v_rules ->> 'overtime_adds_pay')::boolean, false);
    v_absence_deducts := coalesce((v_rules ->> 'absence_deducts_pay')::boolean, true);
    v_partial_deducts := coalesce((v_rules ->> 'partial_day_deducts_pay')::boolean, false);
    v_late_rate := coalesce((v_rules ->> 'late_deduct_per_minute')::int, 50);
    v_overtime_rate := coalesce((v_rules ->> 'overtime_bonus_per_hour')::int, 1500);
    v_absence_rate := coalesce((v_rules ->> 'absence_deduct_per_day')::int, 12000);
    v_partial_percent := coalesce((v_rules ->> 'partial_day_deduct_percent')::int, 50);
  exception
    when invalid_text_representation or numeric_value_out_of_range then
      raise exception 'invalid_arguments' using errcode = 'P0101';
  end;

  if v_late_rate < 0
     or v_overtime_rate < 0
     or v_absence_rate < 0
     or v_partial_percent < 0
     or v_partial_percent > 100 then
    raise exception 'invalid_arguments' using errcode = 'P0101';
  end if;

  v_period_label := (
    case extract(month from p_start)::int
      when 1 then 'Январь'
      when 2 then 'Февраль'
      when 3 then 'Март'
      when 4 then 'Апрель'
      when 5 then 'Май'
      when 6 then 'Июнь'
      when 7 then 'Июль'
      when 8 then 'Август'
      when 9 then 'Сентябрь'
      when 10 then 'Октябрь'
      when 11 then 'Ноябрь'
      when 12 then 'Декабрь'
    end
  ) || ' ' || extract(year from p_start)::int::text;

  for v_worker in
    select
      m.profile_id as worker_id,
      coalesce(
        nullif(trim(p.full_name), ''),
        nullif(trim(p.username), ''),
        'Работник'
      ) as display_name,
      coalesce(p.username, '') as username,
      m.base_salary_tenge
    from public.attendance_memberships m
    join public.profiles p on p.id = m.profile_id
    where m.workplace_id = p_workplace_id
      and m.status = 'active'::public.attendance_membership_status
    order by coalesce(nullif(trim(p.full_name), ''), p.username, m.profile_id::text)
  loop
    v_base_salary := case
      when v_worker.base_salary_tenge = 0 then 250000
      else v_worker.base_salary_tenge
    end;
    v_late_minutes_total := 0;
    v_late_days := 0;
    v_absent_days := 0;
    v_partial_days := 0;

    select coalesce(sum(o.hours), 0)::int
    into v_overtime_hours
    from public.attendance_overtime_entries o
    where o.workplace_id = p_workplace_id
      and o.profile_id = v_worker.worker_id
      and o.status = 'approved'::public.attendance_overtime_status
      and o.work_date between p_start and p_end;

    select string_agg(
      case kind
        when 'day_off'::public.attendance_absence_kind then 'Выходной'
        when 'vacation'::public.attendance_absence_kind then 'Отпуск'
        when 'sick'::public.attendance_absence_kind then 'Больничный'
      end,
      ', '
      order by kind::text
    )
    into v_absence_kinds
    from (
      select distinct a.kind
      from public.attendance_absences a
      where a.workplace_id = p_workplace_id
        and a.profile_id = v_worker.worker_id
        and a.start_date <= p_end
        and a.end_date >= p_start
    ) absence_kinds;

    for v_day in
      select d::date
      from generate_series(p_start::timestamp, p_end::timestamp, interval '1 day') d
    loop
      select exists (
        select 1
        from public.attendance_absences a
        where a.workplace_id = p_workplace_id
          and a.profile_id = v_worker.worker_id
          and v_day between a.start_date and a.end_date
      )
      into v_has_absence;

      select min(p.punched_at)
      into v_clock_in
      from public.attendance_punches p
      where p.workplace_id = p_workplace_id
        and p.profile_id = v_worker.worker_id
        and p.punch_kind = 'clock_in'::public.attendance_punch_kind
        and p.cancelled_at is null
        and (p.punched_at at time zone v_workplace.timezone)::date = v_day;

      select max(p.punched_at)
      into v_clock_out
      from public.attendance_punches p
      where p.workplace_id = p_workplace_id
        and p.profile_id = v_worker.worker_id
        and p.punch_kind = 'clock_out'::public.attendance_punch_kind
        and p.cancelled_at is null
        and (p.punched_at at time zone v_workplace.timezone)::date = v_day;

      if v_has_absence then
        continue;
      end if;

      if v_clock_in is null then
        if extract(isodow from v_day)::int between 1 and 5 then
          v_absent_days := v_absent_days + 1;
        end if;
        continue;
      end if;

      if v_clock_out is null then
        v_partial_days := v_partial_days + 1;
      end if;

      if v_workplace.clock_in_scheduled is not null
         and (v_clock_in at time zone v_workplace.timezone)::time
             > v_workplace.clock_in_scheduled then
        v_late_minutes := floor(
          extract(epoch from (
            (v_clock_in at time zone v_workplace.timezone)
            - (v_day::timestamp + v_workplace.clock_in_scheduled)
          )) / 60
        )::int;
        if v_late_minutes > 0 then
          v_late_days := v_late_days + 1;
          v_late_minutes_total := v_late_minutes_total + v_late_minutes;
        end if;
      end if;
    end loop;

    v_lines := '[]'::jsonb;
    v_deduction_amount := 0;
    v_bonus_amount := 0;

    if v_late_deducts and v_late_minutes_total > 0 then
      v_lines := v_lines || jsonb_build_array(jsonb_build_object(
        'label', 'Опоздания',
        'detail', format(
          '%s ₸ × %s мин · %s дн.',
          v_late_rate,
          v_late_minutes_total,
          v_late_days
        ),
        'amount', -(v_late_rate * v_late_minutes_total),
        'kind', 'deduction'
      ));
      v_deduction_amount := v_deduction_amount + (v_late_rate * v_late_minutes_total);
    end if;

    if v_absence_deducts and v_absent_days > 0 then
      v_lines := v_lines || jsonb_build_array(jsonb_build_object(
        'label', 'Пропуск смены',
        'detail', format('%s ₸ × %s дн.', v_absence_rate, v_absent_days),
        'amount', -(v_absence_rate * v_absent_days),
        'kind', 'deduction'
      ));
      v_deduction_amount := v_deduction_amount + (v_absence_rate * v_absent_days);
    end if;

    if v_absence_kinds is not null then
      v_lines := v_lines || jsonb_build_array(jsonb_build_object(
        'label', 'Отсутствие оформлено',
        'detail', v_absence_kinds || ' — не штраф за пропуск',
        'amount', 0,
        'kind', 'base'
      ));
    end if;

    if v_partial_deducts and v_partial_days > 0 then
      v_late_minutes := round(
        (v_base_salary / 22.0) * v_partial_percent / 100.0 * v_partial_days
      )::int;
      v_lines := v_lines || jsonb_build_array(jsonb_build_object(
        'label', 'Неполный день',
        'detail', format(
          '%s%% от дневной ставки · %s',
          v_partial_percent,
          v_partial_days
        ),
        'amount', -v_late_minutes,
        'kind', 'deduction'
      ));
      v_deduction_amount := v_deduction_amount + v_late_minutes;
    end if;

    if v_overtime_adds and v_overtime_hours > 0 then
      v_lines := v_lines || jsonb_build_array(jsonb_build_object(
        'label', 'Переработка (утверждено)',
        'detail', format('%s ₸ × %s ч', v_overtime_rate, v_overtime_hours),
        'amount', v_overtime_rate * v_overtime_hours,
        'kind', 'bonus'
      ));
      v_bonus_amount := v_bonus_amount + (v_overtime_rate * v_overtime_hours);
    end if;

    v_net_pay := v_base_salary - v_deduction_amount + v_bonus_amount;
    v_workers := v_workers || jsonb_build_array(jsonb_build_object(
      'worker_id', v_worker.worker_id,
      'display_name', v_worker.display_name,
      'username', v_worker.username,
      'base_salary', v_base_salary,
      'lines', v_lines,
      'net_pay', v_net_pay
    ));

    v_team_base := v_team_base + v_base_salary;
    v_team_deductions := v_team_deductions + v_deduction_amount;
    v_team_bonuses := v_team_bonuses + v_bonus_amount;
    v_team_net := v_team_net + v_net_pay;
  end loop;

  return jsonb_build_object(
    'period_label', v_period_label,
    'workers', v_workers,
    'team', jsonb_build_object(
      'base_total', v_team_base,
      'deductions_total', v_team_deductions,
      'bonuses_total', v_team_bonuses,
      'net_total', v_team_net
    )
  );
end;
$$;

-- --------------------------------------------------------------------------- booking: enriched lists
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
    'client_id', b.client_id,
    'client_name', coalesce(cp.full_name, ''),
    'client_username', cp.username,
    'client_phone', cp.phone,
    'service_id', b.service_id,
    'service_title', b.service_title,
    'service_emoji', b.service_emoji,
    'duration_minutes', b.duration_minutes,
    'price', b.price,
    'staff_id', b.staff_id,
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
    'service_id', b.service_id,
    'service_title', b.service_title,
    'service_emoji', b.service_emoji,
    'duration_minutes', b.duration_minutes,
    'price', b.price,
    'staff_id', b.staff_id,
    'client_cancel_hours_before', coalesce((
      select s.client_cancel_hours_before
      from public.booking_schedule_settings s
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

create or replace function public.get_booking_enriched_for_viewer(p_booking_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
set row_security to off
as $$
declare
  uid uuid;
  b public.bookings%rowtype;
begin
  uid := public.booking_assert_authenticated();

  select *
  into b
  from public.bookings
  where id = p_booking_id;

  if not found then
    return null;
  end if;

  if b.client_id = uid then
    return jsonb_build_object(
      'role', 'client',
      'item', jsonb_build_object(
        'id', b.id,
        'host_id', b.host_id,
        'host_display_name', coalesce((
          select p.full_name from public.profiles p where p.id = b.host_id
        ), ''),
        'host_username', (
          select p.username from public.profiles p where p.id = b.host_id
        ),
        'service_id', b.service_id,
        'service_title', b.service_title,
        'service_emoji', b.service_emoji,
        'duration_minutes', b.duration_minutes,
        'price', b.price,
        'staff_id', b.staff_id,
        'executor_name', (
          select st.display_name from public.booking_staff st where st.id = b.staff_id
        ),
        'starts_at', b.starts_at,
        'status', b.status,
        'notes', b.client_notes,
        'created_at', b.created_at
      )
    );
  end if;

  if b.host_id = uid then
    return jsonb_build_object(
      'role', 'host',
      'item', jsonb_build_object(
        'id', b.id,
        'client_id', b.client_id,
        'client_name', coalesce((
          select p.full_name from public.profiles p where p.id = b.client_id
        ), ''),
        'client_username', (
          select p.username from public.profiles p where p.id = b.client_id
        ),
        'client_phone', (
          select p.phone from public.profiles p where p.id = b.client_id
        ),
        'service_id', b.service_id,
        'service_title', b.service_title,
        'service_emoji', b.service_emoji,
        'duration_minutes', b.duration_minutes,
        'price', b.price,
        'staff_id', b.staff_id,
        'executor_name', (
          select st.display_name from public.booking_staff st where st.id = b.staff_id
        ),
        'starts_at', b.starts_at,
        'status', b.status,
        'notes', b.client_notes,
        'participants_count', b.participants_count,
        'created_at', b.created_at
      )
    );
  end if;

  return null;
end;
$$;

-- --------------------------------------------------------------------------- booking: availability with reschedule exclusion
drop function if exists public.get_booking_availability(uuid, uuid, uuid, date);

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

  select *
  into v_settings
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

  select *
  into v_window
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

revoke all on function public.attendance_replace_punch_types(uuid, jsonb) from public;
revoke all on function public.attendance_payroll_preview(uuid, date, date, jsonb) from public;
revoke all on function public.get_booking_availability(uuid, uuid, uuid, date, uuid) from public;
revoke all on function public.list_host_bookings_enriched(
  timestamptz,
  timestamptz,
  text,
  jsonb,
  int
) from public;
revoke all on function public.list_my_bookings_enriched(
  timestamptz,
  timestamptz,
  jsonb,
  int
) from public;
revoke all on function public.get_booking_enriched_for_viewer(uuid) from public;

grant execute on function public.attendance_replace_punch_types(uuid, jsonb) to authenticated;
grant execute on function public.attendance_payroll_preview(uuid, date, date, jsonb) to authenticated;
grant execute on function public.get_booking_availability(uuid, uuid, uuid, date, uuid) to authenticated;
grant execute on function public.list_host_bookings_enriched(
  timestamptz,
  timestamptz,
  text,
  jsonb,
  int
) to authenticated;
grant execute on function public.list_my_bookings_enriched(
  timestamptz,
  timestamptz,
  jsonb,
  int
) to authenticated;
grant execute on function public.get_booking_enriched_for_viewer(uuid) to authenticated;

notify pgrst, 'reload schema';
