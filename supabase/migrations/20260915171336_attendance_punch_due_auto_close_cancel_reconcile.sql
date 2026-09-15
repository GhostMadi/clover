-- Attendance cycle: punch_due FCM, hanging shift auto_close, cancel/revision reconcile.
-- Process: docs/business/attendance.md § Цикл доработок посещаемости
-- Spec: docs/supabase/SPEC_ATTENDANCE_SYSTEM.md

-- --------------------------------------------------------------------------- schema: close_reason on punches
alter table public.attendance_punches
  add column if not exists close_reason text;

alter table public.attendance_punches
  drop constraint if exists attendance_punches_close_reason_check;

alter table public.attendance_punches
  add constraint attendance_punches_close_reason_check check (
    close_reason is null
    or close_reason in ('auto_closed', 'admin_closed')
  );

comment on column public.attendance_punches.close_reason is
  'EN: auto_closed (cron day rollover) | admin_closed; null = normal punch.';

-- --------------------------------------------------------------------------- kind: attendance_punch_due
alter table public.notifications
  drop constraint if exists notifications_kind_check;

alter table public.notifications
  add constraint notifications_kind_check check (kind in (
    'post_like',
    'post_dislike',
    'post_comment',
    'comment_reply',
    'comment_like',
    'comment_dislike',
    'user_follow',
    'booking_created_host',
    'booking_booked_client',
    'booking_reminder_client',
    'booking_visit_started',
    'booking_visit_needs_close',
    'booking_cancelled_host',
    'booking_cancelled_client',
    'booking_completed_client',
    'booking_no_show_client',
    'booking_rescheduled',
    'attendance_invite',
    'attendance_rules_ack',
    'attendance_duty',
    'attendance_correction',
    'attendance_punch_due',
    'account_login'
  ));

-- --------------------------------------------------------------------------- notify: EN keys for punch_due
create or replace function public.attendance_notify(
  p_recipient_id uuid,
  p_actor_id uuid,
  p_kind text,
  p_dedupe_key text,
  p_title text,
  p_body text,
  p_payload jsonb default '{}'::jsonb
)
returns void
language plpgsql
security definer
set search_path = public
set row_security to off
as $$
declare
  v_kind text := coalesce(nullif(trim(p_kind), ''), 'attendance');
  v_title text;
  v_body text;
  v_payload jsonb := coalesce(p_payload, '{}'::jsonb);
  v_wp_id uuid;
  v_wp_name text;
  v_status text;
  v_due text;
begin
  if p_recipient_id is null or p_recipient_id = p_actor_id then
    return;
  end if;

  begin
    v_wp_id := nullif(v_payload->>'workplace_id', '')::uuid;
  exception when others then
    v_wp_id := null;
  end;

  if v_wp_id is not null and nullif(trim(v_payload->>'workplace_name'), '') is null then
    select w.name into v_wp_name
    from public.attendance_workplaces w
    where w.id = v_wp_id;
    if v_wp_name is not null then
      v_payload := v_payload || jsonb_build_object('workplace_name', v_wp_name);
    end if;
  end if;

  v_status := lower(coalesce(nullif(trim(v_payload->>'status'), ''), ''));
  v_due := lower(coalesce(nullif(trim(v_payload->>'due_kind'), ''), ''));

  case v_kind
    when 'attendance_invite' then
      v_title := 'team_invite';
      v_body := 'invited_to_workplace';
    when 'attendance_rules_ack' then
      v_title := 'company_rules';
      v_body := 'accept_rules';
    when 'attendance_duty' then
      v_title := 'duty';
      v_body := 'duty_roster_updated';
    when 'attendance_correction' then
      v_title := 'punch_correction';
      v_body := case
        when v_status in ('approved', 'approve') then 'correction_approved'
        when v_status in ('rejected', 'reject') then 'correction_rejected'
        else 'correction_requested'
      end;
    when 'attendance_punch_due' then
      v_title := 'punch_due';
      v_body := case
        when v_due = 'clock_out' then 'time_to_clock_out'
        when v_due = 'auto_closed' then 'shift_auto_closed'
        else 'time_to_clock_in'
      end;
    else
      v_title := coalesce(nullif(trim(p_title), ''), v_kind);
      v_body := coalesce(nullif(trim(p_body), ''), v_kind);
  end case;

  perform public.upsert_notification(
    p_recipient_id,
    p_actor_id,
    p_kind,
    p_dedupe_key,
    null,
    null,
    v_payload,
    null
  );

  insert into public.push_outbox (user_id, kind, title, body, payload)
  values (
    p_recipient_id,
    v_kind,
    v_title,
    v_body,
    v_payload
  );
exception
  when undefined_table then null;
end;
$$;

-- --------------------------------------------------------------------------- workplace json: timezone
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
    'timezone', coalesce(nullif(trim(p_w.timezone), ''), 'Asia/Almaty'),
    'config_version', p_w.config_version,
    'payroll_rules', coalesce(p_w.payroll_rules, '{}'::jsonb),
    'duty_roster', coalesce(p_w.duty_roster, '{}'::jsonb),
    'duty_only_punch', coalesce(p_w.duty_only_punch, false),
    'group_conversation_id', p_w.group_conversation_id,
    'is_admin', p_w.owner_id = auth.uid(),
    'updated_at', p_w.updated_at
  );
$$;

-- --------------------------------------------------------------------------- revision: cancelled_at + owner sees member punches
create or replace function public.attendance_revision_me()
returns text
language plpgsql
stable
security definer
set search_path = public
set row_security to off
as $$
declare
  uid uuid;
  v_rev timestamptz;
begin
  uid := public.attendance_assert_authenticated();

  select max(x.ts) into v_rev
  from (
    select w.updated_at as ts
    from public.attendance_workplaces w
    where w.owner_id = uid
       or exists (
         select 1 from public.attendance_memberships m
         where m.workplace_id = w.id and m.profile_id = uid
           and m.status in ('active', 'pending')
       )
    union all
    select m.updated_at
    from public.attendance_memberships m
    where m.profile_id = uid
       or exists (
         select 1 from public.attendance_workplaces w
         where w.id = m.workplace_id and w.owner_id = uid
       )
    union all
    select greatest(p.created_at, coalesce(p.cancelled_at, p.created_at))
    from public.attendance_punches p
    where p.punched_at > now() - interval '14 days'
      and (
        p.profile_id = uid
        or public.attendance_is_workplace_owner(p.workplace_id, uid)
      )
    union all
    select a.updated_at
    from public.attendance_absences a
    where a.profile_id = uid
       or public.attendance_is_workplace_owner(a.workplace_id, uid)
  ) x;

  return coalesce(v_rev, to_timestamp(0))::text;
end;
$$;

-- --------------------------------------------------------------------------- cancel: by id or client_punch_id; bump membership
create or replace function public.cancel_attendance_punch(
  p_punch_id uuid default null,
  p_note text default null,
  p_client_punch_id text default null
)
returns void
language plpgsql
security definer
set search_path = public
set row_security to off
as $$
declare
  uid uuid;
  v_p public.attendance_punches%rowtype;
  v_client text := nullif(trim(coalesce(p_client_punch_id, '')), '');
begin
  uid := public.attendance_assert_authenticated();

  if p_punch_id is not null then
    select * into v_p from public.attendance_punches where id = p_punch_id;
  elsif v_client is not null then
    select * into v_p
    from public.attendance_punches
    where profile_id = uid
      and client_punch_id = v_client
    order by punched_at desc
    limit 1;
  else
    raise exception 'invalid_arguments' using errcode = 'P0101';
  end if;

  if not found then
    raise exception 'not_found' using errcode = 'P0103';
  end if;
  if v_p.profile_id <> uid then
    raise exception 'forbidden' using errcode = 'P0102';
  end if;
  if v_p.cancelled_at is not null then
    return;
  end if;

  if exists (
    select 1 from public.attendance_punches x
    where x.membership_id = v_p.membership_id
      and x.cancelled_at is null
      and x.punched_at > v_p.punched_at
  ) then
    raise exception 'invalid_punch' using errcode = 'P0108';
  end if;

  update public.attendance_punches
  set cancelled_at = now(),
      cancel_note = nullif(trim(coalesce(p_note, '')), '')
  where id = v_p.id;

  update public.attendance_memberships
  set updated_at = now()
  where id = v_p.membership_id;
end;
$$;

revoke all on function public.cancel_attendance_punch(uuid, text) from public;
revoke all on function public.cancel_attendance_punch(uuid, text, text) from public;
drop function if exists public.cancel_attendance_punch(uuid, text);
grant execute on function public.cancel_attendance_punch(uuid, text, text) to authenticated;

-- --------------------------------------------------------------------------- punch_due scan
create or replace function public.attendance_notifications_scan_punch_due()
returns int
language plpgsql
security definer
set search_path = public
set row_security to off
as $$
declare
  v_row record;
  v_count int := 0;
  v_tz text;
  v_local_ts timestamp;
  v_local_date date;
  v_target timestamp;
  v_open boolean;
  v_dedupe text;
  v_payload jsonb;
  v_due text;
begin
  for v_row in
    select
      m.id as membership_id,
      m.profile_id,
      w.id as workplace_id,
      w.name as workplace_name,
      w.owner_id,
      w.timezone,
      w.clock_in_enabled,
      w.clock_out_enabled,
      w.clock_in_scheduled,
      w.clock_out_scheduled,
      coalesce(w.duty_only_punch, false) as duty_only_punch,
      w.duty_roster
    from public.attendance_memberships m
    join public.attendance_workplaces w on w.id = m.workplace_id
    where m.status = 'active'
      and public.profile_has_marker_tag(m.profile_id, 'attendanceWork')
  loop
    v_tz := coalesce(nullif(trim(v_row.timezone), ''), 'Asia/Almaty');
    v_local_ts := timezone(v_tz, now());
    v_local_date := v_local_ts::date;
    v_open := public.attendance_shift_is_open(v_row.membership_id);

    -- Skip absence day.
    if exists (
      select 1 from public.attendance_absences a
      where a.workplace_id = v_row.workplace_id
        and a.profile_id = v_row.profile_id
        and a.start_date <= v_local_date
        and a.end_date >= v_local_date
    ) then
      continue;
    end if;

    if v_row.duty_only_punch
       and not public.attendance_is_on_duty_today(v_row.duty_roster, v_row.profile_id, v_local_date) then
      continue;
    end if;

    -- clock_in window
    if v_row.clock_in_enabled
       and v_row.clock_in_scheduled is not null
       and not v_open then
      v_target := v_local_date + v_row.clock_in_scheduled;
      if v_local_ts >= v_target and v_local_ts < v_target + interval '20 minutes' then
        v_due := 'clock_in';
        v_dedupe := 'attendance:' || v_row.workplace_id::text || ':' || v_row.profile_id::text
          || ':punch_due:' || v_local_date::text || ':clock_in';
        if not exists (select 1 from public.notifications n where n.dedupe_key = v_dedupe) then
          v_payload := jsonb_build_object(
            'workplace_id', v_row.workplace_id,
            'workplace_name', v_row.workplace_name,
            'due_kind', v_due
          );
          perform public.attendance_notify(
            v_row.profile_id,
            v_row.owner_id,
            'attendance_punch_due',
            v_dedupe,
            'punch_due',
            'time_to_clock_in',
            v_payload
          );
          v_count := v_count + 1;
        end if;
      end if;
    end if;

    -- clock_out window
    if v_row.clock_out_enabled
       and v_row.clock_out_scheduled is not null
       and v_open then
      v_target := v_local_date + v_row.clock_out_scheduled;
      if v_local_ts >= v_target and v_local_ts < v_target + interval '20 minutes' then
        v_due := 'clock_out';
        v_dedupe := 'attendance:' || v_row.workplace_id::text || ':' || v_row.profile_id::text
          || ':punch_due:' || v_local_date::text || ':clock_out';
        if not exists (select 1 from public.notifications n where n.dedupe_key = v_dedupe) then
          v_payload := jsonb_build_object(
            'workplace_id', v_row.workplace_id,
            'workplace_name', v_row.workplace_name,
            'due_kind', v_due
          );
          perform public.attendance_notify(
            v_row.profile_id,
            v_row.owner_id,
            'attendance_punch_due',
            v_dedupe,
            'punch_due',
            'time_to_clock_out',
            v_payload
          );
          v_count := v_count + 1;
        end if;
      end if;
    end if;
  end loop;

  return v_count;
end;
$$;

comment on function public.attendance_notifications_scan_punch_due() is
  'Cron: punch_due in-app+FCM for clock_in/out scheduled windows (workplace TZ).';

revoke all on function public.attendance_notifications_scan_punch_due() from public;
grant execute on function public.attendance_notifications_scan_punch_due() to service_role;

-- --------------------------------------------------------------------------- auto-close hanging shifts (company day rolled)
create or replace function public.attendance_auto_close_hanging_shifts()
returns int
language plpgsql
security definer
set search_path = public
set row_security to off
as $$
declare
  v_row record;
  v_count int := 0;
  v_tz text;
  v_local_now timestamp;
  v_in_local_date date;
  v_today date;
  v_close_at timestamptz;
  v_close_local timestamp;
  v_new_id uuid;
  v_client text;
  v_payload jsonb;
begin
  for v_row in
    select
      m.id as membership_id,
      m.profile_id,
      w.id as workplace_id,
      w.name as workplace_name,
      w.owner_id,
      w.timezone,
      w.clock_out_scheduled,
      pin.id as in_punch_id,
      pin.punched_at as in_punched_at
    from public.attendance_memberships m
    join public.attendance_workplaces w on w.id = m.workplace_id
    join lateral (
      select p.*
      from public.attendance_punches p
      where p.membership_id = m.id
        and p.cancelled_at is null
      order by p.punched_at desc
      limit 1
    ) pin on true
    where m.status = 'active'
      and pin.punch_kind = 'clock_in'::public.attendance_punch_kind
  loop
    v_tz := coalesce(nullif(trim(v_row.timezone), ''), 'Asia/Almaty');
    v_local_now := timezone(v_tz, now());
    v_today := v_local_now::date;
    v_in_local_date := timezone(v_tz, v_row.in_punched_at)::date;

    if v_today <= v_in_local_date then
      continue;
    end if;

    -- Close at scheduled out on the clock-in day, else end of that local day.
    if v_row.clock_out_scheduled is not null then
      v_close_local := v_in_local_date + v_row.clock_out_scheduled;
    else
      v_close_local := v_in_local_date + time '23:59';
    end if;
    if v_close_local <= timezone(v_tz, v_row.in_punched_at) then
      v_close_local := timezone(v_tz, v_row.in_punched_at) + interval '1 minute';
    end if;
    v_close_at := v_close_local at time zone v_tz;

    v_client := 'auto_close:' || v_row.in_punch_id::text;
    if exists (
      select 1 from public.attendance_punches x
      where x.profile_id = v_row.profile_id
        and x.client_punch_id = v_client
    ) then
      continue;
    end if;

    insert into public.attendance_punches (
      workplace_id,
      membership_id,
      profile_id,
      punch_kind,
      punched_at,
      client_punch_id,
      close_reason
    ) values (
      v_row.workplace_id,
      v_row.membership_id,
      v_row.profile_id,
      'clock_out'::public.attendance_punch_kind,
      v_close_at,
      v_client,
      'auto_closed'
    )
    returning id into v_new_id;

    update public.attendance_memberships
    set updated_at = now()
    where id = v_row.membership_id;

    -- Drop stale due keys for that in-day.
    delete from public.notifications
    where dedupe_key like 'attendance:' || v_row.workplace_id::text || ':' || v_row.profile_id::text
      || ':punch_due:' || v_in_local_date::text || ':%';

    v_payload := jsonb_build_object(
      'workplace_id', v_row.workplace_id,
      'workplace_name', v_row.workplace_name,
      'due_kind', 'auto_closed',
      'punch_id', v_new_id
    );
    perform public.attendance_notify(
      v_row.profile_id,
      v_row.owner_id,
      'attendance_punch_due',
      'attendance:' || v_row.workplace_id::text || ':' || v_row.profile_id::text
        || ':auto_closed:' || v_row.in_punch_id::text,
      'punch_due',
      'shift_auto_closed',
      v_payload
    );

    v_count := v_count + 1;
  end loop;

  return v_count;
end;
$$;

comment on function public.attendance_auto_close_hanging_shifts() is
  'Cron: synthetic clock_out with close_reason=auto_closed after company-day rollover.';

revoke all on function public.attendance_auto_close_hanging_shifts() from public;
grant execute on function public.attendance_auto_close_hanging_shifts() to service_role;

-- --------------------------------------------------------------------------- scheduled wrapper + cron
create or replace function public.attendance_notifications_scan_scheduled()
returns int
language plpgsql
security definer
set search_path = public
set row_security to off
as $$
declare
  v_total int := 0;
begin
  v_total := v_total + public.attendance_notifications_scan_punch_due();
  v_total := v_total + public.attendance_auto_close_hanging_shifts();
  return v_total;
end;
$$;

revoke all on function public.attendance_notifications_scan_scheduled() from public;
grant execute on function public.attendance_notifications_scan_scheduled() to service_role;

do $$
begin
  perform cron.unschedule('attendance_notifications_scan_scheduled');
exception
  when undefined_function then null;
  when undefined_table then null;
  when others then null;
end $$;

do $$
begin
  perform cron.schedule(
    'attendance_notifications_scan_scheduled',
    '*/15 * * * *',
    $cron$select public.attendance_notifications_scan_scheduled();$cron$
  );
exception
  when undefined_function then null;
  when undefined_table then null;
  when others then null;
end $$;

-- --------------------------------------------------------------------------- bootstrap punches include close_reason
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
      'has_attendance_work_tag', public.attendance_profile_has_attendance_work_tag(m.profile_id),
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
      'cancel_note', p.cancel_note,
      'close_reason', p.close_reason
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
