-- Chat RPC: create conversations, list conversations/messages enriched, send messages, mark read, search.
-- Uses SECURITY DEFINER + row_security off (tables are not directly accessible to clients).
-- Idempotent where possible.

-- --------------------------------------------------------------------------- helper: assert participant
create or replace function public.chat_assert_participant(p_conversation_id uuid)
returns void
language plpgsql
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

  if not exists (
    select 1
    from public.chat_participants p
    where p.conversation_id = p_conversation_id
      and p.user_id = uid
      and p.left_at is null
  ) then
    raise exception 'not_participant' using errcode = 'P0010';
  end if;
end;
$$;

-- --------------------------------------------------------------------------- create dm
create or replace function public.create_dm(p_other_user_id uuid)
returns uuid
language plpgsql
security definer
set search_path = public
set row_security to off
as $$
declare
  uid uuid;
  cid uuid;
begin
  uid := auth.uid();
  if uid is null then
    raise exception 'not_authenticated' using errcode = 'P0003';
  end if;

  if p_other_user_id is null or p_other_user_id = uid then
    raise exception 'invalid_user' using errcode = 'P0007';
  end if;

  -- Ensure other profile exists and is not sleeping.
  if not exists (select 1 from public.profiles pr where pr.id = p_other_user_id) then
    raise exception 'user_not_found' using errcode = 'P0008';
  end if;
  if exists (select 1 from public.profiles pr where pr.id = p_other_user_id and pr.account_state = 'hibernate') then
    raise exception 'user_sleeping' using errcode = 'P0006';
  end if;

  -- Try reuse existing dm with exactly 2 active participants (uid + other).
  select c.id into cid
  from public.chat_conversations c
  where c.type = 'dm'
    and exists (
      select 1 from public.chat_participants p
      where p.conversation_id = c.id and p.user_id = uid and p.left_at is null
    )
    and exists (
      select 1 from public.chat_participants p
      where p.conversation_id = c.id and p.user_id = p_other_user_id and p.left_at is null
    )
    and 2 = (
      select count(*) from public.chat_participants p
      where p.conversation_id = c.id and p.left_at is null
    )
  order by c.created_at desc
  limit 1;

  if cid is not null then
    return cid;
  end if;

  insert into public.chat_conversations (type, title, created_by)
  values ('dm', null, uid)
  returning id into cid;

  insert into public.chat_participants (conversation_id, user_id, role)
  values
    (cid, uid, 'member'),
    (cid, p_other_user_id, 'member')
  on conflict do nothing;

  return cid;
end;
$$;

-- --------------------------------------------------------------------------- create group
create or replace function public.create_group(p_title text, p_user_ids uuid[])
returns uuid
language plpgsql
security definer
set search_path = public
set row_security to off
as $$
declare
  uid uuid;
  cid uuid;
  v uuid;
begin
  uid := auth.uid();
  if uid is null then
    raise exception 'not_authenticated' using errcode = 'P0003';
  end if;

  insert into public.chat_conversations (type, title, created_by)
  values ('group', nullif(trim(coalesce(p_title, '')), ''), uid)
  returning id into cid;

  -- creator admin
  insert into public.chat_participants (conversation_id, user_id, role)
  values (cid, uid, 'admin')
  on conflict do nothing;

  if p_user_ids is not null then
    foreach v in array p_user_ids loop
      if v is null or v = uid then
        continue;
      end if;
      -- skip unknown users silently (client can validate separately)
      if exists (select 1 from public.profiles pr where pr.id = v and pr.account_state <> 'hibernate') then
        insert into public.chat_participants (conversation_id, user_id, role)
        values (cid, v, 'member')
        on conflict do nothing;
      end if;
    end loop;
  end if;

  return cid;
end;
$$;

-- --------------------------------------------------------------------------- participants management (admin only)
create or replace function public.add_participants(p_conversation_id uuid, p_user_ids uuid[])
returns void
language plpgsql
security definer
set search_path = public
set row_security to off
as $$
declare
  uid uuid;
  v uuid;
begin
  uid := auth.uid();
  if uid is null then
    raise exception 'not_authenticated' using errcode = 'P0003';
  end if;

  if not exists (
    select 1 from public.chat_participants p
    where p.conversation_id = p_conversation_id
      and p.user_id = uid
      and p.role = 'admin'
      and p.left_at is null
  ) then
    raise exception 'not_admin' using errcode = 'P0011';
  end if;

  foreach v in array coalesce(p_user_ids, '{}'::uuid[]) loop
    if v is null then continue; end if;
    if exists (select 1 from public.profiles pr where pr.id = v and pr.account_state <> 'hibernate') then
      insert into public.chat_participants (conversation_id, user_id, role)
      values (p_conversation_id, v, 'member')
      on conflict do nothing;
    end if;
  end loop;
end;
$$;

create or replace function public.remove_participant(p_conversation_id uuid, p_user_id uuid)
returns void
language plpgsql
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
  if p_user_id is null then
    return;
  end if;

  if not exists (
    select 1 from public.chat_participants p
    where p.conversation_id = p_conversation_id
      and p.user_id = uid
      and p.role = 'admin'
      and p.left_at is null
  ) then
    raise exception 'not_admin' using errcode = 'P0011';
  end if;

  update public.chat_participants
  set left_at = now()
  where conversation_id = p_conversation_id
    and user_id = p_user_id
    and left_at is null;
end;
$$;

-- --------------------------------------------------------------------------- send message (+ optional post ref)
create or replace function public.send_message(
  p_conversation_id uuid,
  p_kind text,
  p_text text default null,
  p_reply_to uuid default null,
  p_forward_from uuid default null,
  p_post_id uuid default null
)
returns uuid
language plpgsql
security definer
set search_path = public
set row_security to off
as $$
declare
  uid uuid;
  mk public.chat_message_kind;
  mid uuid;
begin
  uid := auth.uid();
  if uid is null then
    raise exception 'not_authenticated' using errcode = 'P0003';
  end if;

  perform public.chat_assert_participant(p_conversation_id);

  mk := coalesce(nullif(trim(coalesce(p_kind, '')), ''), 'text')::public.chat_message_kind;

  insert into public.chat_messages (
    conversation_id, sender_id, kind, text, reply_to_message_id, forwarded_from_message_id
  )
  values (
    p_conversation_id,
    uid,
    mk,
    nullif(p_text, ''),
    p_reply_to,
    p_forward_from
  )
  returning id into mid;

  if mk = 'post_ref' then
    if p_post_id is null then
      raise exception 'post_id_required' using errcode = 'P0012';
    end if;
    insert into public.chat_message_post_refs (message_id, post_id, caption)
    values (mid, p_post_id, nullif(p_text, ''))
    on conflict do nothing;
  end if;

  return mid;
end;
$$;

-- --------------------------------------------------------------------------- mark conversation read
create or replace function public.mark_conversation_read(p_conversation_id uuid, p_last_message_id uuid default null)
returns void
language plpgsql
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

  perform public.chat_assert_participant(p_conversation_id);

  update public.chat_participants
  set last_read_at = now(),
      last_read_message_id = coalesce(p_last_message_id, last_read_message_id)
  where conversation_id = p_conversation_id
    and user_id = uid
    and left_at is null;
end;
$$;

-- --------------------------------------------------------------------------- list conversations enriched
create or replace function public.list_conversations_enriched(
  p_limit int default 30,
  p_offset int default 0
)
returns table (
  conversation_id uuid,
  type text,
  title text,
  created_at timestamptz,
  other_user jsonb,
  last_message jsonb,
  unread_count int
)
language sql
stable
security definer
set search_path = public
set row_security to off
as $$
  with me as (
    select auth.uid() as uid
  ),
  mine as (
    select
      c.id as conversation_id,
      c.type,
      c.title,
      c.created_at,
      p.last_read_at
    from public.chat_conversations c
    join public.chat_participants p
      on p.conversation_id = c.id
     and p.user_id = (select uid from me)
     and p.left_at is null
  ),
  enriched as (
    select
      m.conversation_id,
      m.type::text as type,
      m.title,
      m.created_at,
      case when m.type = 'dm' then (
        select jsonb_build_object(
          'id', pr.id,
          'username', pr.username,
          'avatar_url', pr.avatar_url
        )
        from public.chat_participants p2
        join public.profiles pr on pr.id = p2.user_id
        where p2.conversation_id = m.conversation_id
          and p2.left_at is null
          and p2.user_id <> (select uid from me)
        limit 1
      ) else null end as other_user,
      (
        select to_jsonb(msg.*)
        from public.chat_messages msg
        where msg.conversation_id = m.conversation_id
          and msg.deleted_at is null
        order by msg.created_at desc, msg.id desc
        limit 1
      ) as last_message,
      coalesce((
        select count(*)::int
        from public.chat_messages msg
        where msg.conversation_id = m.conversation_id
          and msg.deleted_at is null
          and msg.created_at > coalesce(m.last_read_at, 'epoch'::timestamptz)
          and msg.sender_id <> (select uid from me)
      ), 0) as unread_count
    from mine m
  )
  select *
  from enriched
  order by coalesce((enriched.last_message->>'created_at')::timestamptz, enriched.created_at) desc
  limit least(greatest(coalesce(p_limit, 30), 1), 200)
  offset greatest(coalesce(p_offset, 0), 0);
$$;

-- --------------------------------------------------------------------------- list messages enriched
create or replace function public.list_messages_enriched(
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
  post_ref jsonb
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
    to_jsonb(b.*) as message,
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
    (
      select jsonb_build_object('post_id', prf.post_id, 'caption', prf.caption)
      from public.chat_message_post_refs prf
      where prf.message_id = b.id
      limit 1
    ) as post_ref
  from base b
  join public.profiles pr on pr.id = b.sender_id
  order by (b.created_at) asc, b.id asc;
$$;

-- --------------------------------------------------------------------------- search (FTS if available; fallback to ILIKE)
create or replace function public.search_messages(
  p_query text,
  p_conversation_id uuid default null,
  p_limit int default 50
)
returns table (
  conversation_id uuid,
  message jsonb,
  sender jsonb
)
language sql
stable
security definer
set search_path = public
set row_security to off
as $$
  with me as (select auth.uid() as uid),
  q as (
    select
      trim(coalesce(p_query,'')) as raw,
      websearch_to_tsquery('simple', trim(coalesce(p_query,''))) as tsq,
      '%' || replace(replace(replace(trim(coalesce(p_query,'')), '%',''), '_',''), ',', '') || '%' as pattern
  ),
  allowed_conversations as (
    select p.conversation_id
    from public.chat_participants p
    where p.user_id = (select uid from me)
      and p.left_at is null
      and (p_conversation_id is null or p.conversation_id = p_conversation_id)
  )
  select
    m.conversation_id,
    to_jsonb(m.*) as message,
    jsonb_build_object('id', pr.id, 'username', pr.username, 'avatar_url', pr.avatar_url) as sender
  from public.chat_messages m
  join allowed_conversations ac on ac.conversation_id = m.conversation_id
  join public.profiles pr on pr.id = m.sender_id
  where m.deleted_at is null
    and m.text is not null
    and (
      (m.search_tsv is not null and (select raw from q) <> '' and m.search_tsv @@ (select tsq from q))
      or (m.text ilike (select pattern from q))
    )
  order by m.created_at desc, m.id desc
  limit least(greatest(coalesce(p_limit, 50), 1), 200);
$$;

-- --------------------------------------------------------------------------- grants
revoke all on function public.chat_assert_participant(uuid) from public;
revoke all on function public.create_dm(uuid) from public;
revoke all on function public.create_group(text, uuid[]) from public;
revoke all on function public.add_participants(uuid, uuid[]) from public;
revoke all on function public.remove_participant(uuid, uuid) from public;
revoke all on function public.send_message(uuid, text, text, uuid, uuid, uuid) from public;
revoke all on function public.mark_conversation_read(uuid, uuid) from public;
revoke all on function public.list_conversations_enriched(int, int) from public;
revoke all on function public.list_messages_enriched(uuid, int, timestamptz) from public;
revoke all on function public.search_messages(text, uuid, int) from public;

grant execute on function public.chat_assert_participant(uuid) to authenticated;
grant execute on function public.create_dm(uuid) to authenticated;
grant execute on function public.create_group(text, uuid[]) to authenticated;
grant execute on function public.add_participants(uuid, uuid[]) to authenticated;
grant execute on function public.remove_participant(uuid, uuid) to authenticated;
grant execute on function public.send_message(uuid, text, text, uuid, uuid, uuid) to authenticated;
grant execute on function public.mark_conversation_read(uuid, uuid) to authenticated;
grant execute on function public.list_conversations_enriched(int, int) to authenticated;
grant execute on function public.list_messages_enriched(uuid, int, timestamptz) to authenticated;
grant execute on function public.search_messages(text, uuid, int) to authenticated;

