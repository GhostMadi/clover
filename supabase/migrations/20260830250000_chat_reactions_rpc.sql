-- Chat message reactions: toggle RPC + my_reactions in enriched payloads.

-- --------------------------------------------------------------------------- helper
create or replace function public._chat_my_reactions_json(p_message_id uuid)
returns jsonb
language sql
stable
security definer
set search_path = public
set row_security to off
as $$
  select coalesce(
    jsonb_agg(rr.emoji order by rr.created_at asc),
    '[]'::jsonb
  )
  from public.chat_message_reactions rr
  where rr.message_id = p_message_id
    and rr.user_id = auth.uid();
$$;

revoke all on function public._chat_my_reactions_json(uuid) from public;

-- --------------------------------------------------------------------------- toggle
create or replace function public.toggle_message_reaction(
  p_message_id uuid,
  p_emoji text
)
returns jsonb
language plpgsql
security definer
set search_path = public
set row_security to off
as $$
declare
  uid uuid;
  conv uuid;
  em text;
begin
  uid := auth.uid();
  if uid is null then
    raise exception 'not_authenticated' using errcode = 'P0003';
  end if;

  em := nullif(trim(coalesce(p_emoji, '')), '');
  if em is null or char_length(em) > 16 then
    raise exception 'invalid_emoji' using errcode = 'P0015';
  end if;

  select m.conversation_id into conv
  from public.chat_messages m
  where m.id = p_message_id
    and m.deleted_at is null;

  if conv is null then
    raise exception 'message_not_found' using errcode = 'P0014';
  end if;

  perform public.chat_assert_participant(conv);

  if exists (
    select 1
    from public.chat_message_reactions r
    where r.message_id = p_message_id
      and r.user_id = uid
      and r.emoji = em
  ) then
    delete from public.chat_message_reactions r
    where r.message_id = p_message_id
      and r.user_id = uid
      and r.emoji = em;
  else
    insert into public.chat_message_reactions (message_id, user_id, emoji)
    values (p_message_id, uid, em);
  end if;

  return jsonb_build_object(
    'reactions',
    (
      select coalesce(
        jsonb_agg(jsonb_build_object('emoji', x.emoji, 'count', x.cnt) order by x.cnt desc),
        '[]'::jsonb
      )
      from (
        select emoji, count(*)::int as cnt
        from public.chat_message_reactions rr
        where rr.message_id = p_message_id
        group by emoji
      ) x
    ),
    'my_reactions', public._chat_my_reactions_json(p_message_id)
  );
end;
$$;

revoke all on function public.toggle_message_reaction(uuid, text) from public;
grant execute on function public.toggle_message_reaction(uuid, text) to authenticated;

-- --------------------------------------------------------------------------- enriched: add my_reactions column
-- Postgres forbids changing OUT params via CREATE OR REPLACE — drop first.
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
  my_reactions jsonb
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
    public._chat_my_reactions_json(b.id) as my_reactions
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
  my_reactions jsonb
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
    (
      to_jsonb(b.*) || jsonb_build_object(
        'read_by_peer',
        (
          exists (
            select 1
            from public.chat_participants op
            cross join lateral (select auth.uid() as uid) me
            where op.conversation_id = b.conversation_id
              and op.user_id <> me.uid
              and op.left_at is null
          )
          and not exists (
            select 1
            from public.chat_participants pp
            cross join lateral (select auth.uid() as uid) me
            left join public.chat_messages rm
              on rm.id = pp.last_read_message_id
             and rm.conversation_id = pp.conversation_id
             and rm.deleted_at is null
            where pp.conversation_id = b.conversation_id
              and pp.user_id <> me.uid
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
    public._chat_my_reactions_json(b.id) as my_reactions
  from public.chat_messages b
  join public.profiles pr on pr.id = b.sender_id
  where b.id = p_message_id
    and b.deleted_at is null;
end;
$$;

revoke all on function public.list_messages_enriched(uuid, int, timestamptz) from public;
revoke all on function public.get_message_enriched(uuid) from public;
grant execute on function public.list_messages_enriched(uuid, int, timestamptz) to authenticated;
grant execute on function public.get_message_enriched(uuid) to authenticated;
