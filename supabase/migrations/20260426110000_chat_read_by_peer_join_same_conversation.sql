-- read_by_peer: join last_read_message_id only if that row belongs to the same conversation.
-- Without rm.conversation_id = pp.conversation_id, a stray UUID could match any chat_messages.id
-- and make the peer cursor look "newer" than b → false «прочитано».

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

create or replace function public.get_message_enriched(p_message_id uuid)
returns table (
  message jsonb,
  sender jsonb,
  reply_preview jsonb,
  reactions jsonb,
  attachments jsonb,
  post_ref jsonb
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
            cross join (select auth.uid() as uid) m
            where op.conversation_id = b.conversation_id
              and op.user_id <> m.uid
              and op.left_at is null
          )
          and not exists (
            select 1
            from public.chat_participants pp
            cross join (select auth.uid() as uid) mm
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
    (
      select jsonb_build_object('post_id', prf.post_id, 'caption', prf.caption)
      from public.chat_message_post_refs prf
      where prf.message_id = b.id
      limit 1
    ) as post_ref
  from public.chat_messages b
  join public.profiles pr on pr.id = b.sender_id
  where b.id = p_message_id;
end;
$$;
