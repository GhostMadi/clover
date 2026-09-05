-- Attendance module: SECURITY DEFINER RPC (bootstrap, invite, punch, absence).

create or replace function public.attendance_assert_authenticated()
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

-- --------------------------------------------------------------------------- workplace JSON helpers
create or replace function public.attendance_workplace_to_json(p_w public.attendance_workplaces)
returns jsonb
language sql
stable
as $$
  select jsonb_build_object(
    'id', p_w.id,
    'owner_id', p_w.owner_id,
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
    'timezone', p_w.timezone,
    'updated_at', p_w.updated_at,
    'is_admin', p_w.owner_id = auth.uid()
  );
$$;

-- --------------------------------------------------------------------------- attendance_revision_me
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
    union all
    select p.created_at
    from public.attendance_punches p
    where p.profile_id = uid
      and p.punched_at > now() - interval '14 days'
    union all
    select a.updated_at
    from public.attendance_absences a
    where a.profile_id = uid
       or public.attendance_is_workplace_owner(a.workplace_id, uid)
  ) x;

  return coalesce(v_rev, to_timestamp(0))::text;
end;
$$;

-- --------------------------------------------------------------------------- attendance_bootstrap_me
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
begin
  uid := public.attendance_assert_authenticated();

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

  return jsonb_build_object(
    'workplaces', v_workplaces,
    'memberships', v_memberships,
    'punch_types', v_types,
    'punches', v_punches,
    'absences', v_absences,
    'revision', public.attendance_revision_me()
  );
end;
$$;

-- --------------------------------------------------------------------------- attendance_create_workplace
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

  -- Owner as active member (self), ack current config.
  insert into public.attendance_memberships (
    workplace_id, profile_id, status, ack_version, invited_by
  ) values (
    v_id, uid, 'active'::public.attendance_membership_status, 1, uid
  );

  return v_id;
end;
$$;

-- --------------------------------------------------------------------------- attendance_update_workplace_settings
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
begin
  uid := public.attendance_assert_authenticated();

  select * into v_w from public.attendance_workplaces where id = p_workplace_id;
  if not found then
    raise exception 'not_found' using errcode = 'P0103';
  end if;
  if v_w.owner_id <> uid then
    raise exception 'forbidden' using errcode = 'P0102';
  end if;

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
    config_version = v_w.config_version
  where w.id = p_workplace_id;
end;
$$;

-- --------------------------------------------------------------------------- invite lifecycle
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
    return v_id;
  end if;

  insert into public.attendance_memberships (
    workplace_id, profile_id, status, ack_version, invited_by
  ) values (
    p_workplace_id, p_profile_id, 'pending', 0, uid
  )
  returning id into v_id;

  return v_id;
end;
$$;

create or replace function public.attendance_accept_invite(p_membership_id uuid)
returns void
language plpgsql
security definer
set search_path = public
set row_security to off
as $$
declare
  uid uuid;
  v_m public.attendance_memberships%rowtype;
  v_cfg int;
begin
  uid := public.attendance_assert_authenticated();

  select * into v_m from public.attendance_memberships where id = p_membership_id;
  if not found then
    raise exception 'not_found' using errcode = 'P0103';
  end if;
  if v_m.profile_id <> uid then
    raise exception 'forbidden' using errcode = 'P0102';
  end if;
  if v_m.status <> 'pending' then
    raise exception 'invalid_status' using errcode = 'P0104';
  end if;

  select config_version into v_cfg from public.attendance_workplaces where id = v_m.workplace_id;

  update public.attendance_memberships
  set status = 'active', ack_version = coalesce(v_cfg, 1)
  where id = p_membership_id;
end;
$$;

create or replace function public.attendance_reject_invite(p_membership_id uuid)
returns void
language plpgsql
security definer
set search_path = public
set row_security to off
as $$
declare
  uid uuid;
  v_m public.attendance_memberships%rowtype;
begin
  uid := public.attendance_assert_authenticated();

  select * into v_m from public.attendance_memberships where id = p_membership_id;
  if not found then
    raise exception 'not_found' using errcode = 'P0103';
  end if;
  if v_m.profile_id <> uid then
    raise exception 'forbidden' using errcode = 'P0102';
  end if;
  if v_m.status <> 'pending' then
    raise exception 'invalid_status' using errcode = 'P0104';
  end if;

  update public.attendance_memberships
  set status = 'declined'
  where id = p_membership_id;
end;
$$;

create or replace function public.attendance_archive_member(p_membership_id uuid)
returns void
language plpgsql
security definer
set search_path = public
set row_security to off
as $$
declare
  uid uuid;
  v_m public.attendance_memberships%rowtype;
begin
  uid := public.attendance_assert_authenticated();

  select * into v_m from public.attendance_memberships where id = p_membership_id;
  if not found then
    raise exception 'not_found' using errcode = 'P0103';
  end if;
  if not public.attendance_is_workplace_owner(v_m.workplace_id, uid) then
    raise exception 'forbidden' using errcode = 'P0102';
  end if;
  if v_m.status <> 'active' then
    raise exception 'invalid_status' using errcode = 'P0104';
  end if;

  update public.attendance_memberships
  set status = 'archived'
  where id = p_membership_id;
end;
$$;

create or replace function public.attendance_reinvite_member(p_membership_id uuid)
returns void
language plpgsql
security definer
set search_path = public
set row_security to off
as $$
declare
  uid uuid;
  v_m public.attendance_memberships%rowtype;
begin
  uid := public.attendance_assert_authenticated();

  select * into v_m from public.attendance_memberships where id = p_membership_id;
  if not found then
    raise exception 'not_found' using errcode = 'P0103';
  end if;
  if not public.attendance_is_workplace_owner(v_m.workplace_id, uid) then
    raise exception 'forbidden' using errcode = 'P0102';
  end if;
  if v_m.status not in ('archived', 'declined') then
    raise exception 'invalid_status' using errcode = 'P0104';
  end if;

  update public.attendance_memberships
  set status = 'pending', invited_by = uid, ack_version = 0
  where id = p_membership_id;
end;
$$;

create or replace function public.attendance_ack_config(p_workplace_id uuid)
returns void
language plpgsql
security definer
set search_path = public
set row_security to off
as $$
declare
  uid uuid;
  v_cfg int;
  v_m public.attendance_memberships%rowtype;
begin
  uid := public.attendance_assert_authenticated();

  select * into v_m
  from public.attendance_memberships
  where workplace_id = p_workplace_id and profile_id = uid;

  if not found or v_m.status <> 'active' then
    raise exception 'not_active_member' using errcode = 'P0104';
  end if;

  select config_version into v_cfg from public.attendance_workplaces where id = p_workplace_id;

  update public.attendance_memberships
  set ack_version = v_cfg
  where id = v_m.id;
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

create or replace function public.cancel_attendance_punch(
  p_punch_id uuid,
  p_note text default null
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
begin
  uid := public.attendance_assert_authenticated();

  select * into v_p from public.attendance_punches where id = p_punch_id;
  if not found then
    raise exception 'not_found' using errcode = 'P0103';
  end if;
  if v_p.profile_id <> uid then
    raise exception 'forbidden' using errcode = 'P0102';
  end if;
  if v_p.cancelled_at is not null then
    return;
  end if;

  -- Only cancel the latest non-cancelled punch for this membership.
  if exists (
    select 1 from public.attendance_punches x
    where x.membership_id = v_p.membership_id
      and x.cancelled_at is null
      and x.punched_at > v_p.punched_at
  ) then
    raise exception 'invalid_punch' using errcode = 'P0108';
  end if;

  update public.attendance_punches
  set cancelled_at = now(), cancel_note = nullif(trim(coalesce(p_note, '')), '')
  where id = p_punch_id;
end;
$$;

-- --------------------------------------------------------------------------- absence
create or replace function public.attendance_upsert_absence(
  p_workplace_id uuid,
  p_profile_id uuid,
  p_kind public.attendance_absence_kind,
  p_start_date date,
  p_end_date date,
  p_note text default null,
  p_absence_id uuid default null
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
begin
  uid := public.attendance_assert_authenticated();

  if not public.attendance_is_workplace_owner(p_workplace_id, uid) then
    raise exception 'forbidden' using errcode = 'P0102';
  end if;
  if p_profile_id is null or p_kind is null or p_start_date is null or p_end_date is null then
    raise exception 'invalid_arguments' using errcode = 'P0101';
  end if;
  if p_end_date < p_start_date then
    raise exception 'invalid_arguments' using errcode = 'P0101';
  end if;
  if not exists (
    select 1 from public.attendance_memberships m
    where m.workplace_id = p_workplace_id and m.profile_id = p_profile_id
      and m.status = 'active'
  ) then
    raise exception 'not_active_member' using errcode = 'P0104';
  end if;

  if p_absence_id is not null then
    update public.attendance_absences
    set kind = p_kind,
        start_date = p_start_date,
        end_date = p_end_date,
        note = p_note,
        profile_id = p_profile_id
    where id = p_absence_id and workplace_id = p_workplace_id
    returning id into v_id;
    if v_id is null then
      raise exception 'not_found' using errcode = 'P0103';
    end if;
    return v_id;
  end if;

  insert into public.attendance_absences (
    workplace_id, profile_id, kind, start_date, end_date, note, created_by
  ) values (
    p_workplace_id, p_profile_id, p_kind, p_start_date, p_end_date, p_note, uid
  )
  returning id into v_id;

  return v_id;
end;
$$;

-- --------------------------------------------------------------------------- grants
grant execute on function public.attendance_assert_authenticated() to authenticated;
grant execute on function public.attendance_workplace_to_json(public.attendance_workplaces) to authenticated;
grant execute on function public.attendance_revision_me() to authenticated;
grant execute on function public.attendance_bootstrap_me(timestamptz) to authenticated;
grant execute on function public.attendance_create_workplace(text, uuid, double precision, double precision, int) to authenticated;
grant execute on function public.attendance_update_workplace_settings(uuid, text, double precision, double precision, int, boolean, boolean, time, time, boolean) to authenticated;
grant execute on function public.attendance_invite_member(uuid, uuid) to authenticated;
grant execute on function public.attendance_accept_invite(uuid) to authenticated;
grant execute on function public.attendance_reject_invite(uuid) to authenticated;
grant execute on function public.attendance_archive_member(uuid) to authenticated;
grant execute on function public.attendance_reinvite_member(uuid) to authenticated;
grant execute on function public.attendance_ack_config(uuid) to authenticated;
grant execute on function public.submit_attendance_punch(uuid, public.attendance_punch_kind, double precision, double precision, uuid, text, timestamptz) to authenticated;
grant execute on function public.cancel_attendance_punch(uuid, text) to authenticated;
grant execute on function public.attendance_upsert_absence(uuid, uuid, public.attendance_absence_kind, date, date, text, uuid) to authenticated;
