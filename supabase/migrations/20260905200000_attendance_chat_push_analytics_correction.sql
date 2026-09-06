-- Attendance v1.2: chat cards + company group + in-app/push outbox + analytics/timesheet RPC + punch correction.
-- Process: docs/business/attendance.md
-- Spec: docs/supabase/SPEC_ATTENDANCE_SYSTEM.md

-- --------------------------------------------------------------------------- workplace ↔ group chat
alter table public.attendance_workplaces
  add column if not exists group_conversation_id uuid
    references public.chat_conversations(id) on delete set null;

create unique index if not exists attendance_workplaces_group_conversation_uidx
  on public.attendance_workplaces (group_conversation_id)
  where group_conversation_id is not null;

comment on column public.attendance_workplaces.group_conversation_id is
  'Групповой чат компании (invite/rules cards + служебные сообщения).';

-- --------------------------------------------------------------------------- correction status
do $$
begin
  create type public.attendance_correction_status as enum ('pending', 'approved', 'rejected');
exception
  when duplicate_object then null;
end $$;

create table if not exists public.attendance_punch_correction_requests (
  id uuid primary key default gen_random_uuid(),
  workplace_id uuid not null references public.attendance_workplaces(id) on delete cascade,
  punch_id uuid not null references public.attendance_punches(id) on delete cascade,
  profile_id uuid not null references public.profiles(id) on delete cascade,
  note text null,
  proposed_punched_at timestamptz null,
  status public.attendance_correction_status not null default 'pending',
  created_at timestamptz not null default now(),
  resolved_at timestamptz null,
  resolved_by uuid null references public.profiles(id) on delete set null,
  constraint attendance_correction_note_len check (note is null or char_length(note) <= 500)
);

create index if not exists attendance_correction_workplace_status_idx
  on public.attendance_punch_correction_requests (workplace_id, status, created_at desc);

create index if not exists attendance_correction_profile_idx
  on public.attendance_punch_correction_requests (profile_id, created_at desc);

alter table public.attendance_punch_correction_requests enable row level security;

drop policy if exists attendance_correction_select on public.attendance_punch_correction_requests;
create policy attendance_correction_select on public.attendance_punch_correction_requests
  for select to authenticated
  using (
    profile_id = auth.uid()
    or public.attendance_is_workplace_owner(workplace_id, auth.uid())
  );

revoke insert, update, delete on public.attendance_punch_correction_requests from authenticated, anon;

-- --------------------------------------------------------------------------- push outbox (FCM worker later)
create table if not exists public.push_outbox (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  kind text not null,
  title text not null,
  body text not null,
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  sent_at timestamptz null,
  attempts int not null default 0,
  last_error text null
);

create index if not exists push_outbox_pending_idx
  on public.push_outbox (created_at asc)
  where sent_at is null;

alter table public.push_outbox enable row level security;
-- no client policies: service role / worker only
revoke all on public.push_outbox from authenticated, anon;

-- --------------------------------------------------------------------------- notification kinds
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
    'attendance_invite',
    'attendance_rules_ack',
    'attendance_duty',
    'attendance_correction'
  ));

-- --------------------------------------------------------------------------- helpers: notify + push queue
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
begin
  if p_recipient_id is null or p_recipient_id = p_actor_id then
    return;
  end if;

  perform public.upsert_notification(
    p_recipient_id,
    p_actor_id,
    p_kind,
    p_dedupe_key,
    null,
    null,
    coalesce(p_payload, '{}'::jsonb),
    null
  );

  insert into public.push_outbox (user_id, kind, title, body, payload)
  values (
    p_recipient_id,
    p_kind,
    coalesce(nullif(trim(p_title), ''), 'Clover'),
    coalesce(nullif(trim(p_body), ''), ''),
    coalesce(p_payload, '{}'::jsonb)
  );
end;
$$;

revoke all on function public.attendance_notify(uuid, uuid, text, text, text, text, jsonb) from public;

-- --------------------------------------------------------------------------- helpers: system card in chat
create or replace function public.attendance_post_chat_card(
  p_conversation_id uuid,
  p_sender_id uuid,
  p_payload jsonb,
  p_fallback_text text
)
returns uuid
language plpgsql
security definer
set search_path = public
set row_security to off
as $$
declare
  mid uuid;
  body text;
begin
  if p_conversation_id is null or p_sender_id is null then
    return null;
  end if;

  body := 'CLOVER_CARD:' || coalesce(p_payload, '{}'::jsonb)::text;
  if char_length(body) > 4000 then
    body := left(coalesce(nullif(trim(p_fallback_text), ''), 'Посещаемость'), 4000);
  end if;

  insert into public.chat_messages (conversation_id, sender_id, kind, text)
  values (
    p_conversation_id,
    p_sender_id,
    'system'::public.chat_message_kind,
    body
  )
  returning id into mid;

  return mid;
end;
$$;

revoke all on function public.attendance_post_chat_card(uuid, uuid, jsonb, text) from public;

create or replace function public.attendance_ensure_group_chat(p_workplace_id uuid)
returns uuid
language plpgsql
security definer
set search_path = public
set row_security to off
as $$
declare
  v_w public.attendance_workplaces%rowtype;
  cid uuid;
begin
  select * into v_w from public.attendance_workplaces where id = p_workplace_id;
  if not found then
    raise exception 'not_found' using errcode = 'P0103';
  end if;

  if v_w.group_conversation_id is not null then
    return v_w.group_conversation_id;
  end if;

  insert into public.chat_conversations (type, title, created_by)
  values ('group', 'Посещаемость · ' || v_w.name, v_w.owner_id)
  returning id into cid;

  insert into public.chat_participants (conversation_id, user_id, role)
  values (cid, v_w.owner_id, 'admin')
  on conflict do nothing;

  update public.attendance_workplaces
  set group_conversation_id = cid
  where id = p_workplace_id;

  return cid;
end;
$$;

revoke all on function public.attendance_ensure_group_chat(uuid) from public;

create or replace function public.attendance_add_to_group_chat(
  p_workplace_id uuid,
  p_profile_id uuid
)
returns void
language plpgsql
security definer
set search_path = public
set row_security to off
as $$
declare
  cid uuid;
begin
  cid := public.attendance_ensure_group_chat(p_workplace_id);
  insert into public.chat_participants (conversation_id, user_id, role)
  values (cid, p_profile_id, 'member')
  on conflict (conversation_id, user_id) do update
    set left_at = null,
        role = excluded.role;
end;
$$;

revoke all on function public.attendance_add_to_group_chat(uuid, uuid) from public;

-- --------------------------------------------------------------------------- create workplace → group chat
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

  insert into public.attendance_memberships (
    workplace_id, profile_id, status, ack_version, invited_by
  ) values (
    v_id, uid, 'active'::public.attendance_membership_status, 1, uid
  );

  perform public.attendance_ensure_group_chat(v_id);
  return v_id;
end;
$$;

-- --------------------------------------------------------------------------- invite → DM card + notify
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
  v_name text;
  v_dm uuid;
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

  select name into v_name from public.attendance_workplaces where id = p_workplace_id;

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

  -- DM card (create_dm uses auth.uid() = owner)
  begin
    v_dm := public.create_dm(p_profile_id);
    perform public.attendance_post_chat_card(
      v_dm,
      uid,
      jsonb_build_object(
        'v', 1,
        'card', 'attendance_invite',
        'membership_id', v_id,
        'workplace_id', p_workplace_id,
        'workplace_name', coalesce(v_name, 'компания')
      ),
      'Стать частью команды · ' || coalesce(v_name, 'компания')
    );
  exception when others then
    null; -- invite still valid if chat fails
  end;

  perform public.attendance_notify(
    p_profile_id,
    uid,
    'attendance_invite',
    'attendance:invite:' || v_id::text,
    'Приглашение в команду',
    'Вас пригласили в «' || coalesce(v_name, 'компанию') || '»',
    jsonb_build_object(
      'workplace_id', p_workplace_id,
      'membership_id', v_id,
      'conversation_id', v_dm
    )
  );

  return v_id;
end;
$$;

-- --------------------------------------------------------------------------- accept → group + rules card
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
  v_name text;
  cid uuid;
  owner_id uuid;
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

  select config_version, name, owner_id
  into v_cfg, v_name, owner_id
  from public.attendance_workplaces
  where id = v_m.workplace_id;

  update public.attendance_memberships
  set status = 'active', ack_version = coalesce(v_cfg, 1)
  where id = p_membership_id;

  perform public.attendance_add_to_group_chat(v_m.workplace_id, uid);
  cid := public.attendance_ensure_group_chat(v_m.workplace_id);

  perform public.attendance_post_chat_card(
    cid,
    coalesce(owner_id, uid),
    jsonb_build_object(
      'v', 1,
      'card', 'attendance_rules',
      'workplace_id', v_m.workplace_id,
      'workplace_name', coalesce(v_name, 'компания'),
      'config_version', coalesce(v_cfg, 1)
    ),
    'Правила компании · v' || coalesce(v_cfg, 1)::text
  );
end;
$$;

-- --------------------------------------------------------------------------- config bump → rules card + notify members needing ack
create or replace function public.attendance_broadcast_rules_card(p_workplace_id uuid)
returns void
language plpgsql
security definer
set search_path = public
set row_security to off
as $$
declare
  v_w public.attendance_workplaces%rowtype;
  cid uuid;
  r record;
begin
  select * into v_w from public.attendance_workplaces where id = p_workplace_id;
  if not found then
    return;
  end if;

  cid := public.attendance_ensure_group_chat(p_workplace_id);
  perform public.attendance_post_chat_card(
    cid,
    v_w.owner_id,
    jsonb_build_object(
      'v', 1,
      'card', 'attendance_rules',
      'workplace_id', p_workplace_id,
      'workplace_name', v_w.name,
      'config_version', v_w.config_version
    ),
    'Обновлены правила · v' || v_w.config_version::text
  );

  for r in
    select m.profile_id
    from public.attendance_memberships m
    where m.workplace_id = p_workplace_id
      and m.status = 'active'
      and m.profile_id <> v_w.owner_id
      and m.ack_version < v_w.config_version
  loop
    perform public.attendance_notify(
      r.profile_id,
      v_w.owner_id,
      'attendance_rules_ack',
      'attendance:rules:' || p_workplace_id::text || ':v' || v_w.config_version::text || ':' || r.profile_id::text,
      'Новые правила компании',
      'Примите правила «' || v_w.name || '» (v' || v_w.config_version::text || ')',
      jsonb_build_object(
        'workplace_id', p_workplace_id,
        'config_version', v_w.config_version,
        'conversation_id', cid
      )
    );
  end loop;
end;
$$;

revoke all on function public.attendance_broadcast_rules_card(uuid) from public;

-- Patch settings update to broadcast when config bumps (reuse body from payroll migration chain).
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

-- --------------------------------------------------------------------------- duty roster notify
create or replace function public.attendance_update_duty_roster(
  p_workplace_id uuid,
  p_duty_roster jsonb
)
returns void
language plpgsql
security definer
set search_path = public
set row_security to off
as $$
declare
  uid uuid;
  v_name text;
  wid text;
  r_profile uuid;
begin
  uid := public.attendance_assert_authenticated();
  if p_workplace_id is null or p_duty_roster is null then
    raise exception 'invalid_arguments' using errcode = 'P0101';
  end if;
  if not public.attendance_is_workplace_owner(p_workplace_id, uid) then
    raise exception 'forbidden' using errcode = 'P0102';
  end if;

  select name into v_name from public.attendance_workplaces where id = p_workplace_id;

  update public.attendance_workplaces
  set duty_roster = p_duty_roster,
      updated_at = now()
  where id = p_workplace_id;

  for wid in
    select jsonb_array_elements_text(coalesce(p_duty_roster->'worker_ids', '[]'::jsonb))
  loop
    begin
      r_profile := wid::uuid;
    exception when others then
      continue;
    end;
    if r_profile = uid then
      continue;
    end if;
    perform public.attendance_notify(
      r_profile,
      uid,
      'attendance_duty',
      'attendance:duty:' || p_workplace_id::text || ':' || r_profile::text || ':' || to_char(now(), 'YYYYMMDDHH24MI'),
      'Дежурство',
      'Обновлён список дежурных в «' || coalesce(v_name, 'компании') || '»',
      jsonb_build_object('workplace_id', p_workplace_id)
    );
  end loop;
end;
$$;

-- --------------------------------------------------------------------------- analytics + timesheet
create or replace function public.attendance_analytics_overview(
  p_workplace_id uuid,
  p_start date,
  p_end date
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
begin
  uid := public.attendance_assert_authenticated();
  if p_workplace_id is null or p_start is null or p_end is null or p_end < p_start then
    raise exception 'invalid_arguments' using errcode = 'P0101';
  end if;
  if not (
    public.attendance_is_workplace_owner(p_workplace_id, uid)
    or public.attendance_can_view_workplace(p_workplace_id, uid)
  ) then
    raise exception 'forbidden' using errcode = 'P0102';
  end if;

  return jsonb_build_object(
    'workplace_id', p_workplace_id,
    'start', p_start,
    'end', p_end,
    'punches', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', p.id,
        'profile_id', p.profile_id,
        'punch_kind', p.punch_kind,
        'punch_type_id', p.punch_type_id,
        'punched_at', p.punched_at,
        'cancelled_at', p.cancelled_at
      ) order by p.punched_at)
      from public.attendance_punches p
      where p.workplace_id = p_workplace_id
        and p.punched_at::date between p_start and p_end
        and (
          public.attendance_is_workplace_owner(p_workplace_id, uid)
          or p.profile_id = uid
        )
    ), '[]'::jsonb),
    'absences', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', a.id,
        'profile_id', a.profile_id,
        'kind', a.kind,
        'start_date', a.start_date,
        'end_date', a.end_date,
        'note', a.note
      ) order by a.start_date)
      from public.attendance_absences a
      where a.workplace_id = p_workplace_id
        and a.start_date <= p_end
        and a.end_date >= p_start
        and (
          public.attendance_is_workplace_owner(p_workplace_id, uid)
          or a.profile_id = uid
        )
    ), '[]'::jsonb)
  );
end;
$$;

create or replace function public.attendance_timesheet_csv(
  p_workplace_id uuid,
  p_start date,
  p_end date
)
returns text
language plpgsql
stable
security definer
set search_path = public
set row_security to off
as $$
declare
  uid uuid;
  v_name text;
  buf text := E'\uFEFF';
  r record;
begin
  uid := public.attendance_assert_authenticated();
  if not public.attendance_is_workplace_owner(p_workplace_id, uid) then
    raise exception 'forbidden' using errcode = 'P0102';
  end if;
  if p_start is null or p_end is null or p_end < p_start then
    raise exception 'invalid_arguments' using errcode = 'P0101';
  end if;

  select name into v_name from public.attendance_workplaces where id = p_workplace_id;
  buf := buf || 'Компания;' || replace(coalesce(v_name, ''), ';', ',') || E'\n';
  buf := buf || 'Период;' || p_start::text || ' — ' || p_end::text || E'\n\n';
  buf := buf || E'Работник;Дата;Вид;Время;Отменено\n';

  for r in
    select
      coalesce(pr.full_name, pr.username, p.profile_id::text) as worker_name,
      p.punched_at::date as d,
      p.punch_kind::text as kind,
      to_char(p.punched_at at time zone 'UTC', 'HH24:MI') as t,
      (p.cancelled_at is not null) as cancelled
    from public.attendance_punches p
    left join public.profiles pr on pr.id = p.profile_id
    where p.workplace_id = p_workplace_id
      and p.punched_at::date between p_start and p_end
    order by pr.username nulls last, p.punched_at
  loop
    buf := buf
      || replace(r.worker_name, ';', ',') || ';'
      || r.d::text || ';'
      || r.kind || ';'
      || r.t || ';'
      || case when r.cancelled then 'да' else '' end
      || E'\n';
  end loop;

  return buf;
end;
$$;

grant execute on function public.attendance_analytics_overview(uuid, date, date) to authenticated;
grant execute on function public.attendance_timesheet_csv(uuid, date, date) to authenticated;

-- --------------------------------------------------------------------------- punch correction
create or replace function public.attendance_request_punch_correction(
  p_punch_id uuid,
  p_note text default null,
  p_proposed_punched_at timestamptz default null
)
returns uuid
language plpgsql
security definer
set search_path = public
set row_security to off
as $$
declare
  uid uuid;
  v_p public.attendance_punches%rowtype;
  v_id uuid;
  owner_id uuid;
  v_name text;
begin
  uid := public.attendance_assert_authenticated();
  select * into v_p from public.attendance_punches where id = p_punch_id;
  if not found then
    raise exception 'not_found' using errcode = 'P0103';
  end if;
  if v_p.profile_id <> uid then
    raise exception 'forbidden' using errcode = 'P0102';
  end if;

  insert into public.attendance_punch_correction_requests (
    workplace_id, punch_id, profile_id, note, proposed_punched_at
  ) values (
    v_p.workplace_id, p_punch_id, uid, nullif(trim(coalesce(p_note, '')), ''), p_proposed_punched_at
  )
  returning id into v_id;

  select owner_id, name into owner_id, v_name
  from public.attendance_workplaces where id = v_p.workplace_id;

  perform public.attendance_notify(
    owner_id,
    uid,
    'attendance_correction',
    'attendance:correction:' || v_id::text,
    'Запрос на исправление',
    'Работник просит исправить отметку в «' || coalesce(v_name, 'компании') || '»',
    jsonb_build_object(
      'workplace_id', v_p.workplace_id,
      'correction_id', v_id,
      'punch_id', p_punch_id
    )
  );

  return v_id;
end;
$$;

create or replace function public.attendance_resolve_punch_correction(
  p_correction_id uuid,
  p_status text
)
returns void
language plpgsql
security definer
set search_path = public
set row_security to off
as $$
declare
  uid uuid;
  v_c public.attendance_punch_correction_requests%rowtype;
  st public.attendance_correction_status;
begin
  uid := public.attendance_assert_authenticated();
  if p_status not in ('approved', 'rejected') then
    raise exception 'invalid_arguments' using errcode = 'P0101';
  end if;
  st := p_status::public.attendance_correction_status;

  select * into v_c from public.attendance_punch_correction_requests where id = p_correction_id;
  if not found then
    raise exception 'not_found' using errcode = 'P0103';
  end if;
  if not public.attendance_is_workplace_owner(v_c.workplace_id, uid) then
    raise exception 'forbidden' using errcode = 'P0102';
  end if;
  if v_c.status <> 'pending' then
    raise exception 'invalid_status' using errcode = 'P0104';
  end if;

  update public.attendance_punch_correction_requests
  set status = st,
      resolved_at = now(),
      resolved_by = uid
  where id = p_correction_id;

  if st = 'approved' then
    update public.attendance_punches
    set
      punched_at = coalesce(v_c.proposed_punched_at, punched_at),
      cancelled_at = null,
      cancel_note = null
    where id = v_c.punch_id;
  end if;

  perform public.attendance_notify(
    v_c.profile_id,
    uid,
    'attendance_correction',
    'attendance:correction:resolved:' || p_correction_id::text,
    'Исправление отметки',
    case when st = 'approved' then 'Запрос на исправление утверждён' else 'Запрос на исправление отклонён' end,
    jsonb_build_object(
      'workplace_id', v_c.workplace_id,
      'correction_id', p_correction_id,
      'status', p_status
    )
  );
end;
$$;

grant execute on function public.attendance_request_punch_correction(uuid, text, timestamptz) to authenticated;
grant execute on function public.attendance_resolve_punch_correction(uuid, text) to authenticated;

-- Extend workplace json with group_conversation_id (if helper exists from payroll mig)
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
    'group_conversation_id', p_w.group_conversation_id,
    'is_admin', p_w.owner_id = auth.uid(),
    'updated_at', p_w.updated_at
  );
$$;

notify pgrst, 'reload schema';
