-- Attendance tag powers: attendance (admin) + attendanceWork (worker).
-- Product: docs/business/attendance-tz.md · docs/business/tag-powers.md
-- Parity with booking: booking_host_has_booking_tag.

-- --------------------------------------------------------------------------- catalog
insert into public.marker_tags (key, group_key)
values
  ('attendance', 'admin'),
  ('attendanceWork', 'worker')
on conflict (key) do update
set group_key = excluded.group_key;

-- --------------------------------------------------------------------------- helpers
create or replace function public.profile_has_marker_tag(
  p_profile_id uuid,
  p_tag_key text
)
returns boolean
language sql
stable
security definer
set search_path = public
set row_security to off
as $$
  select exists (
    select 1
    from public.profiles p
    join public.profile_tag_links ptl on ptl.id = p.tag_link_id
    join public.marker_tags mt on mt.id = any (ptl.tag_ids)
    where p.id = p_profile_id
      and mt.key = p_tag_key
  );
$$;

comment on function public.profile_has_marker_tag(uuid, text) is
  'True if profile has the given marker_tags.key (account power tags included).';

create or replace function public.booking_host_has_booking_tag(p_host_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
set row_security to off
as $$
  select public.profile_has_marker_tag(p_host_id, 'booking');
$$;

create or replace function public.attendance_host_has_attendance_tag(p_profile_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
set row_security to off
as $$
  select public.profile_has_marker_tag(p_profile_id, 'attendance');
$$;

comment on function public.attendance_host_has_attendance_tag(uuid) is
  'Admin attendance ops require account tag attendance.';

create or replace function public.attendance_profile_has_attendance_work_tag(p_profile_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
set row_security to off
as $$
  select public.profile_has_marker_tag(p_profile_id, 'attendanceWork');
$$;

comment on function public.attendance_profile_has_attendance_work_tag(uuid) is
  'Punch / full worker UX requires account tag attendanceWork.';

create or replace function public.attendance_assert_has_attendance_tag(p_uid uuid)
returns void
language plpgsql
stable
security definer
set search_path = public
set row_security to off
as $$
begin
  if not public.attendance_host_has_attendance_tag(p_uid) then
    raise exception 'missing_attendance_tag' using errcode = 'P0111';
  end if;
end;
$$;

-- --------------------------------------------------------------------------- create workplace
create or replace function public.attendance_create_workplace(
  p_name text,
  p_folder_id uuid default null,
  p_lat double precision default null,
  p_lng double precision default null,
  p_geofence_radius_m int default 150
)
returns uuid
language plpgsql
security definer
set search_path = public
set row_security to off
as $$
declare
  uid uuid;
  v_id uuid;
  v_loc geography(point, 4326);
begin
  uid := public.attendance_assert_authenticated();
  perform public.attendance_assert_has_attendance_tag(uid);

  if p_name is null or char_length(trim(p_name)) = 0 then
    raise exception 'invalid_arguments' using errcode = 'P0101';
  end if;

  if p_folder_id is not null and not exists (
    select 1 from public.attendance_folders f where f.id = p_folder_id and f.owner_id = uid
  ) then
    raise exception 'not_found' using errcode = 'P0103';
  end if;

  if p_lat is not null and p_lng is not null then
    v_loc := st_setsrid(st_makepoint(p_lng, p_lat), 4326)::geography;
  end if;

  insert into public.attendance_workplaces (
    owner_id, folder_id, name, location, geofence_radius_m
  ) values (
    uid, p_folder_id, trim(p_name), v_loc, coalesce(p_geofence_radius_m, 150)
  )
  returning id into v_id;

  insert into public.attendance_memberships (
    workplace_id, profile_id, status, ack_version, invited_by
  ) values (
    v_id, uid, 'active'::public.attendance_membership_status, 1, uid
  );

  perform public.attendance_ensure_group_chat(v_id);
  return v_id;
end;
$$;

-- --------------------------------------------------------------------------- invite
create or replace function public.attendance_invite_member(
  p_workplace_id uuid,
  p_profile_id uuid
)
returns uuid
language plpgsql
security definer
set search_path = public
set row_security to off
as $$
declare
  uid uuid;
  v_id uuid;
  v_status public.attendance_membership_status;
begin
  uid := public.attendance_assert_authenticated();
  perform public.attendance_assert_has_attendance_tag(uid);

  if p_workplace_id is null or p_profile_id is null then
    raise exception 'invalid_arguments' using errcode = 'P0101';
  end if;
  if not public.attendance_is_workplace_owner(p_workplace_id, uid) then
    raise exception 'forbidden' using errcode = 'P0102';
  end if;
  if not exists (select 1 from public.profiles p where p.id = p_profile_id) then
    raise exception 'not_found' using errcode = 'P0103';
  end if;

  select m.id, m.status into v_id, v_status
  from public.attendance_memberships m
  where m.workplace_id = p_workplace_id and m.profile_id = p_profile_id;

  if found then
    if v_status = 'active' then
      raise exception 'already_member' using errcode = 'P0104';
    end if;
    update public.attendance_memberships
    set status = 'pending', invited_by = uid, ack_version = 0
    where id = v_id;
  else
    insert into public.attendance_memberships (
      workplace_id, profile_id, status, ack_version, invited_by
    ) values (
      p_workplace_id, p_profile_id, 'pending', 0, uid
    )
    returning id into v_id;
  end if;

  perform public.attendance_send_invite_dm_card(v_id, uid);
  return v_id;
end;
$$;

-- --------------------------------------------------------------------------- update settings
create or replace function public.attendance_update_workplace_settings(
  p_workplace_id uuid,
  p_name text default null,
  p_lat double precision default null,
  p_lng double precision default null,
  p_geofence_radius_m int default null,
  p_clock_in_enabled boolean default null,
  p_clock_out_enabled boolean default null,
  p_clock_in_scheduled time default null,
  p_clock_out_scheduled time default null,
  p_bump_config boolean default true
)
returns void
language plpgsql
security definer
set search_path = public
set row_security to off
as $$
declare
  uid uuid;
  v_w public.attendance_workplaces%rowtype;
  v_bump boolean := false;
  v_old_cfg int;
begin
  uid := public.attendance_assert_authenticated();
  perform public.attendance_assert_has_attendance_tag(uid);

  select * into v_w from public.attendance_workplaces where id = p_workplace_id;
  if not found then
    raise exception 'not_found' using errcode = 'P0103';
  end if;
  if v_w.owner_id <> uid then
    raise exception 'forbidden' using errcode = 'P0102';
  end if;

  v_old_cfg := v_w.config_version;

  if p_lat is not null and p_lng is not null then
    v_w.location := st_setsrid(st_makepoint(p_lng, p_lat), 4326)::geography;
    v_bump := true;
  end if;
  if p_geofence_radius_m is not null then
    v_w.geofence_radius_m := p_geofence_radius_m;
    v_bump := true;
  end if;
  if p_clock_in_enabled is not null then
    v_w.clock_in_enabled := p_clock_in_enabled;
    v_bump := true;
  end if;
  if p_clock_out_enabled is not null then
    v_w.clock_out_enabled := p_clock_out_enabled;
    v_bump := true;
  end if;
  if p_clock_in_scheduled is not null then
    v_w.clock_in_scheduled := p_clock_in_scheduled;
    v_bump := true;
  end if;
  if p_clock_out_scheduled is not null then
    v_w.clock_out_scheduled := p_clock_out_scheduled;
    v_bump := true;
  end if;
  if p_name is not null and char_length(trim(p_name)) > 0 then
    v_w.name := trim(p_name);
  end if;

  if p_bump_config and v_bump then
    v_w.config_version := v_w.config_version + 1;
  end if;

  update public.attendance_workplaces w
  set
    name = v_w.name,
    location = v_w.location,
    geofence_radius_m = v_w.geofence_radius_m,
    clock_in_enabled = v_w.clock_in_enabled,
    clock_out_enabled = v_w.clock_out_enabled,
    clock_in_scheduled = v_w.clock_in_scheduled,
    clock_out_scheduled = v_w.clock_out_scheduled,
    config_version = v_w.config_version,
    updated_at = now()
  where w.id = p_workplace_id;

  if v_w.config_version > v_old_cfg then
    perform public.attendance_broadcast_rules_card(p_workplace_id);
  end if;
end;
$$;

-- --------------------------------------------------------------------------- punch
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

  if not public.attendance_profile_has_attendance_work_tag(uid) then
    raise exception 'missing_attendance_work_tag' using errcode = 'P0112';
  end if;

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

-- --------------------------------------------------------------------------- bootstrap: has_attendance_work_tag on memberships
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

grant execute on function public.profile_has_marker_tag(uuid, text) to authenticated;
grant execute on function public.attendance_host_has_attendance_tag(uuid) to authenticated;
grant execute on function public.attendance_profile_has_attendance_work_tag(uuid) to authenticated;

notify pgrst, 'reload schema';
