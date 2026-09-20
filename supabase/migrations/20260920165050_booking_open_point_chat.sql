-- Booking point group chat (mirror attendance company chat).
-- Product: docs/business/booking-points.md
-- Spec: docs/supabase/booking-points.md

alter table public.booking_points
  add column if not exists group_conversation_id uuid
    references public.chat_conversations(id) on delete set null;

create unique index if not exists booking_points_group_conversation_uidx
  on public.booking_points (group_conversation_id)
  where group_conversation_id is not null;

comment on column public.booking_points.group_conversation_id is
  'Групповой чат точки записи (хозяин + active staff с profile_id).';

create or replace function public.booking_ensure_point_group_chat(p_point_id uuid)
returns uuid
language plpgsql
security definer
set search_path = public
set row_security to off
as $$
declare
  v_p public.booking_points%rowtype;
  cid uuid;
begin
  select * into v_p from public.booking_points where id = p_point_id and archived_at is null;
  if not found then
    raise exception 'not_found' using errcode = 'P0002';
  end if;

  if v_p.group_conversation_id is not null then
    return v_p.group_conversation_id;
  end if;

  insert into public.chat_conversations (type, title, created_by)
  values ('group', 'Запись · ' || v_p.name, v_p.host_id)
  returning id into cid;

  insert into public.chat_participants (conversation_id, user_id, role)
  values (cid, v_p.host_id, 'admin')
  on conflict do nothing;

  update public.booking_points
  set group_conversation_id = cid
  where id = p_point_id;

  return cid;
end;
$$;

revoke all on function public.booking_ensure_point_group_chat(uuid) from public;

create or replace function public.booking_open_point_chat(p_point_id uuid)
returns uuid
language plpgsql
security definer
set search_path = public
set row_security to off
as $$
declare
  uid uuid;
  v_host uuid;
  cid uuid;
  r record;
begin
  uid := public.booking_assert_authenticated();

  select host_id into v_host
  from public.booking_points
  where id = p_point_id and archived_at is null;
  if v_host is null then
    raise exception 'not_found' using errcode = 'P0002';
  end if;

  -- Host or active linked staff of this host.
  if uid <> v_host
     and not exists (
       select 1
       from public.booking_staff s
       where s.host_id = v_host
         and s.profile_id = uid
         and s.is_active = true
     )
  then
    raise exception 'forbidden' using errcode = '42501';
  end if;

  cid := public.booking_ensure_point_group_chat(p_point_id);

  for r in
    select s.profile_id
    from public.booking_staff s
    where s.host_id = v_host
      and s.is_active = true
      and s.profile_id is not null
  loop
    insert into public.chat_participants (conversation_id, user_id, role)
    values (cid, r.profile_id, 'member')
    on conflict (conversation_id, user_id) do update
      set left_at = null;
  end loop;

  insert into public.chat_participants (conversation_id, user_id, role)
  values (cid, v_host, 'admin')
  on conflict (conversation_id, user_id) do update
    set left_at = null,
        role = 'admin';

  return cid;
end;
$$;

revoke all on function public.booking_open_point_chat(uuid) from public;
grant execute on function public.booking_open_point_chat(uuid) to authenticated;

comment on function public.booking_ensure_point_group_chat(uuid) is
  'Create or return group chat for a booking point; title Запись · {name}.';

comment on function public.booking_open_point_chat(uuid) is
  'Ensure point group chat and sync host + active staff with profile_id; returns conversation id.';
