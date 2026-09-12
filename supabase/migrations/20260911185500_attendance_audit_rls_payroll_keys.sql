-- Attendance audit: tag powers at RLS (no PostgREST bypass) + EN keys in payroll preview.
-- Plan: docs/supabase/_backend-audit-plan.md

-- 1) Workplaces / memberships: DML only via SECURITY DEFINER RPCs
revoke insert, update, delete on public.attendance_workplaces from authenticated;
revoke insert on public.attendance_memberships from authenticated;

drop policy if exists attendance_workplaces_insert_own on public.attendance_workplaces;
drop policy if exists attendance_workplaces_update_own on public.attendance_workplaces;
drop policy if exists attendance_workplaces_delete_own on public.attendance_workplaces;
drop policy if exists attendance_memberships_insert_owner on public.attendance_memberships;

-- Keep SELECT policies; owner/member still read via RLS.
-- Defense in depth: if grants restored, still require attendance tag.
create policy attendance_workplaces_insert_own
  on public.attendance_workplaces for insert to authenticated
  with check (
    owner_id = auth.uid()
    and public.profile_has_marker_tag(auth.uid(), 'attendance')
  );

create policy attendance_workplaces_update_own
  on public.attendance_workplaces for update to authenticated
  using (
    owner_id = auth.uid()
    and public.profile_has_marker_tag(auth.uid(), 'attendance')
  )
  with check (
    owner_id = auth.uid()
    and public.profile_has_marker_tag(auth.uid(), 'attendance')
  );

create policy attendance_workplaces_delete_own
  on public.attendance_workplaces for delete to authenticated
  using (
    owner_id = auth.uid()
    and public.profile_has_marker_tag(auth.uid(), 'attendance')
  );

create policy attendance_memberships_insert_owner
  on public.attendance_memberships for insert to authenticated
  with check (
    public.attendance_is_workplace_owner(workplace_id, auth.uid())
    and status = 'pending'::public.attendance_membership_status
    and public.profile_has_marker_tag(auth.uid(), 'attendance')
  );

-- 2) payroll preview: English keys only (localize on clients)
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
set row_security = off
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
  v_period_key text;
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

  v_period_key := to_char(p_start, 'YYYY-MM');

  for v_worker in
    select
      m.profile_id as worker_id,
      coalesce(
        nullif(trim(p.full_name), ''),
        nullif(trim(p.username), ''),
        ''
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

    select string_agg(kind::text, ',' order by kind::text)
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
        'label', 'late',
        'detail', format('%s|%s|%s', v_late_rate, v_late_minutes_total, v_late_days),
        'amount', -(v_late_rate * v_late_minutes_total),
        'kind', 'deduction'
      ));
      v_deduction_amount := v_deduction_amount + (v_late_rate * v_late_minutes_total);
    end if;

    if v_absence_deducts and v_absent_days > 0 then
      v_lines := v_lines || jsonb_build_array(jsonb_build_object(
        'label', 'missed_shift',
        'detail', format('%s|%s', v_absence_rate, v_absent_days),
        'amount', -(v_absence_rate * v_absent_days),
        'kind', 'deduction'
      ));
      v_deduction_amount := v_deduction_amount + (v_absence_rate * v_absent_days);
    end if;

    if v_absence_kinds is not null then
      v_lines := v_lines || jsonb_build_array(jsonb_build_object(
        'label', 'absence_recorded',
        'detail', v_absence_kinds,
        'amount', 0,
        'kind', 'base'
      ));
    end if;

    if v_partial_deducts and v_partial_days > 0 then
      v_late_minutes := round(
        (v_base_salary / 22.0) * v_partial_percent / 100.0 * v_partial_days
      )::int;
      v_lines := v_lines || jsonb_build_array(jsonb_build_object(
        'label', 'partial_day',
        'detail', format('%s|%s', v_partial_percent, v_partial_days),
        'amount', -v_late_minutes,
        'kind', 'deduction'
      ));
      v_deduction_amount := v_deduction_amount + v_late_minutes;
    end if;

    if v_overtime_adds and v_overtime_hours > 0 then
      v_lines := v_lines || jsonb_build_array(jsonb_build_object(
        'label', 'overtime_approved',
        'detail', format('%s|%s', v_overtime_rate, v_overtime_hours),
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
    'period_label', v_period_key,
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

comment on function public.attendance_payroll_preview(uuid, date, date, jsonb) is
  'Payroll preview for owner. Labels/period are EN keys; localize on clients.';
