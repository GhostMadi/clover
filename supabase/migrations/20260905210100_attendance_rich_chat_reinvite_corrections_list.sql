-- Attendance: rich chat card post + reinvite DM/notify + list corrections + enriched attendance_card.
-- Depends on: 20260905210000_attendance_chat_card_kinds.sql (enum values committed).
-- Process: docs/business/attendance.md

-- --------------------------------------------------------------------------- post card (rich kinds)
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
  v_card text;
  v_kind public.chat_message_kind;
  v_text text;
  v_workplace_id uuid;
  v_membership_id uuid;
  v_workplace_name text;
  v_config_version int;
begin
  if p_conversation_id is null or p_sender_id is null then
    return null;
  end if;

  v_card := coalesce(p_payload->>'card', '');
  if v_card not in ('attendance_invite', 'attendance_rules') then
    v_kind := 'system'::public.chat_message_kind;
    v_text := left(coalesce(nullif(trim(p_fallback_text), ''), 'Посещаемость'), 4000);
    insert into public.chat_messages (conversation_id, sender_id, kind, text)
    values (p_conversation_id, p_sender_id, v_kind, v_text)
    returning id into mid;
    return mid;
  end if;

  v_kind := v_card::public.chat_message_kind;
  v_workplace_id := nullif(p_payload->>'workplace_id', '')::uuid;
  v_membership_id := nullif(p_payload->>'membership_id', '')::uuid;
  v_workplace_name := coalesce(nullif(trim(p_payload->>'workplace_name'), ''), 'компания');
  v_config_version := nullif(p_payload->>'config_version', '')::int;
  v_text := left(coalesce(nullif(trim(p_fallback_text), ''), v_workplace_name), 4000);

  if v_workplace_id is null then
    raise exception 'invalid_arguments' using errcode = 'P0101';
  end if;

  insert into public.chat_messages (conversation_id, sender_id, kind, text)
  values (p_conversation_id, p_sender_id, v_kind, v_text)
  returning id into mid;

  insert into public.chat_message_attendance_cards (
    message_id, card_type, workplace_id, membership_id, workplace_name, config_version
  ) values (
    mid, v_card, v_workplace_id, v_membership_id, v_workplace_name, v_config_version
  );

  return mid;
end;
$$;

-- --------------------------------------------------------------------------- shared DM invite card + notify
create or replace function public.attendance_send_invite_dm_card(
  p_membership_id uuid,
  p_actor_id uuid
)
returns uuid
language plpgsql
security definer
set search_path = public
set row_security to off
as $$
declare
  v_m public.attendance_memberships%rowtype;
  v_name text;
  v_dm uuid;
begin
  select * into v_m from public.attendance_memberships where id = p_membership_id;
  if not found then
    return null;
  end if;

  select name into v_name from public.attendance_workplaces where id = v_m.workplace_id;

  begin
    v_dm := public.create_dm(v_m.profile_id);
    perform public.attendance_post_chat_card(
      v_dm,
      p_actor_id,
      jsonb_build_object(
        'v', 1,
        'card', 'attendance_invite',
        'membership_id', v_m.id,
        'workplace_id', v_m.workplace_id,
        'workplace_name', coalesce(v_name, 'компания')
      ),
      'Стать частью команды · ' || coalesce(v_name, 'компания')
    );
  exception when others then
    v_dm := null;
  end;

  perform public.attendance_notify(
    v_m.profile_id,
    p_actor_id,
    'attendance_invite',
    'attendance:invite:' || v_m.id::text || ':' || to_char(now(), 'YYYYMMDDHH24MISS'),
    'Приглашение в команду',
    'Вас пригласили в «' || coalesce(v_name, 'компанию') || '»',
    jsonb_build_object(
      'workplace_id', v_m.workplace_id,
      'membership_id', v_m.id,
      'conversation_id', v_dm
    )
  );

  return v_dm;
end;
$$;

revoke all on function public.attendance_send_invite_dm_card(uuid, uuid) from public;

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

  perform public.attendance_send_invite_dm_card(p_membership_id, uid);
end;
$$;

-- --------------------------------------------------------------------------- list corrections (admin / self)
create or replace function public.attendance_list_corrections(
  p_workplace_id uuid,
  p_status text default null
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
  if p_workplace_id is null then
    raise exception 'invalid_arguments' using errcode = 'P0101';
  end if;
  if not (
    public.attendance_is_workplace_owner(p_workplace_id, uid)
    or exists (
      select 1 from public.attendance_memberships m
      where m.workplace_id = p_workplace_id and m.profile_id = uid and m.status = 'active'
    )
  ) then
    raise exception 'forbidden' using errcode = 'P0102';
  end if;

  return coalesce((
    select jsonb_agg(jsonb_build_object(
      'id', c.id,
      'workplace_id', c.workplace_id,
      'punch_id', c.punch_id,
      'profile_id', c.profile_id,
      'note', c.note,
      'proposed_punched_at', c.proposed_punched_at,
      'status', c.status,
      'created_at', c.created_at,
      'resolved_at', c.resolved_at,
      'worker_name', coalesce(pr.full_name, pr.username, c.profile_id::text),
      'punch_kind', p.punch_kind,
      'punched_at', p.punched_at
    ) order by c.created_at desc)
    from public.attendance_punch_correction_requests c
    left join public.profiles pr on pr.id = c.profile_id
    left join public.attendance_punches p on p.id = c.punch_id
    where c.workplace_id = p_workplace_id
      and (
        public.attendance_is_workplace_owner(p_workplace_id, uid)
        or c.profile_id = uid
      )
      and (p_status is null or c.status::text = p_status)
  ), '[]'::jsonb);
end;
$$;

grant execute on function public.attendance_list_corrections(uuid, text) to authenticated;

-- --------------------------------------------------------------------------- enrich chat: attendance_card (+ keep my_reactions)
create or replace function public._chat_message_enriched_json(p_message_id uuid)
returns jsonb
language sql
stable
security definer
set search_path = public
set row_security to off
as $$
  select jsonb_build_object(
    'message', to_jsonb(b.*),
    'sender', jsonb_build_object('id', pr.id, 'username', pr.username, 'avatar_url', pr.avatar_url),
    'reply_preview', (
      select jsonb_build_object(
        'id', r.id,
        'sender_id', r.sender_id,
        'text', r.text,
        'kind', r.kind::text,
        'created_at', r.created_at
      )
      from public.chat_messages r
      where r.id = b.reply_to_message_id
      limit 1
    ),
    'reactions', (
      select coalesce(jsonb_agg(jsonb_build_object('emoji', x.emoji, 'count', x.cnt) order by x.cnt desc), '[]'::jsonb)
      from (
        select emoji, count(*)::int as cnt
        from public.chat_message_reactions rr
        where rr.message_id = b.id
        group by emoji
      ) x
    ),
    'attachments', (
      select coalesce(jsonb_agg(to_jsonb(a.*) order by a.created_at asc), '[]'::jsonb)
      from public.chat_message_attachments a
      where a.message_id = b.id
    ),
    'post_ref', public._chat_post_ref_json(b.id),
    'my_reactions', public._chat_my_reactions_json(b.id),
    'attendance_card', public._chat_attendance_card_json(b.id)
  )
  from public.chat_messages b
  join public.profiles pr on pr.id = b.sender_id
  where b.id = p_message_id
    and b.deleted_at is null;
$$;

drop function if exists public.list_messages_enriched(uuid, int, timestamptz);
drop function if exists public.get_message_enriched(uuid);

create function public.list_messages_enriched(
  p_conversation_id uuid,
  p_limit int default 50,
  p_before timestamptz default null
)
returns table (
  message jsonb,
  sender jsonb,
  reply_preview jsonb,
  reactions jsonb,
  attachments jsonb,
  post_ref jsonb,
  my_reactions jsonb,
  attendance_card jsonb
)
language sql
stable
security definer
set search_path = public
set row_security to off
as $$
  with me as (select auth.uid() as uid),
  ok as (
    select public.chat_assert_participant(p_conversation_id) as _
  ),
  base as (
    select m.*
    from public.chat_messages m
    where m.conversation_id = p_conversation_id
      and m.deleted_at is null
      and (p_before is null or m.created_at < p_before)
    order by m.created_at desc, m.id desc
    limit least(greatest(coalesce(p_limit, 50), 1), 200)
  )
  select
    (
      to_jsonb(b.*) || jsonb_build_object(
        'read_by_peer',
        (
          exists (
            select 1
            from public.chat_participants op
            cross join me mm
            where op.conversation_id = b.conversation_id
              and op.user_id <> mm.uid
              and op.left_at is null
          )
          and not exists (
            select 1
            from public.chat_participants pp
            cross join me mm
            left join public.chat_messages rm
              on rm.id = pp.last_read_message_id
             and rm.conversation_id = pp.conversation_id
             and rm.deleted_at is null
            where pp.conversation_id = b.conversation_id
              and pp.user_id <> mm.uid
              and pp.left_at is null
              and (
                pp.last_read_message_id is null
                or rm.id is null
                or (
                  b.created_at > rm.created_at
                  or (b.created_at = rm.created_at and b.id > rm.id)
                )
              )
          )
        )
      )
    ) as message,
    jsonb_build_object('id', pr.id, 'username', pr.username, 'avatar_url', pr.avatar_url) as sender,
    (
      select jsonb_build_object(
        'id', r.id,
        'sender_id', r.sender_id,
        'text', r.text,
        'kind', r.kind::text,
        'created_at', r.created_at
      )
      from public.chat_messages r
      where r.id = b.reply_to_message_id
      limit 1
    ) as reply_preview,
    (
      select coalesce(jsonb_agg(jsonb_build_object('emoji', x.emoji, 'count', x.cnt) order by x.cnt desc), '[]'::jsonb)
      from (
        select emoji, count(*)::int as cnt
        from public.chat_message_reactions rr
        where rr.message_id = b.id
        group by emoji
      ) x
    ) as reactions,
    (
      select coalesce(jsonb_agg(to_jsonb(a.*) order by a.created_at asc), '[]'::jsonb)
      from public.chat_message_attachments a
      where a.message_id = b.id
    ) as attachments,
    public._chat_post_ref_json(b.id) as post_ref,
    public._chat_my_reactions_json(b.id) as my_reactions,
    public._chat_attendance_card_json(b.id) as attendance_card
  from base b
  join public.profiles pr on pr.id = b.sender_id
  order by (b.created_at) asc, b.id asc;
$$;

create function public.get_message_enriched(p_message_id uuid)
returns table (
  message jsonb,
  sender jsonb,
  reply_preview jsonb,
  reactions jsonb,
  attachments jsonb,
  post_ref jsonb,
  my_reactions jsonb,
  attendance_card jsonb
)
language plpgsql
stable
security definer
set search_path = public
set row_security to off
as $$
declare
  conv uuid;
begin
  select m.conversation_id into conv
  from public.chat_messages m
  where m.id = p_message_id
    and m.deleted_at is null;

  if conv is null then
    raise exception 'message_not_found' using errcode = 'P0014';
  end if;

  perform public.chat_assert_participant(conv);

  return query
  select
    l.message,
    l.sender,
    l.reply_preview,
    l.reactions,
    l.attachments,
    l.post_ref,
    l.my_reactions,
    l.attendance_card
  from public.list_messages_enriched(conv, 200, null) l
  where (l.message->>'id')::uuid = p_message_id
  limit 1;
end;
$$;

revoke all on function public.list_messages_enriched(uuid, int, timestamptz) from public;
revoke all on function public.get_message_enriched(uuid) from public;
grant execute on function public.list_messages_enriched(uuid, int, timestamptz) to authenticated;
grant execute on function public.get_message_enriched(uuid) to authenticated;

notify pgrst, 'reload schema';
