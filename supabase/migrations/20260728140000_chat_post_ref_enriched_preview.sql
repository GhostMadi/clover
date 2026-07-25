-- Enriched post_ref payload for chat messages (preview in thread).

create or replace function public._chat_post_ref_json(p_message_id uuid)
returns jsonb
language sql
stable
security definer
set search_path = public
set row_security to off
as $$
  select jsonb_build_object(
    'post_id', prf.post_id,
    'caption', prf.caption,
    'title', nullif(trim(coalesce(p.title, '')), ''),
    'cover_url', (
      select pm.url
      from public.post_media pm
      where pm.post_id = prf.post_id
      order by pm.sort_order asc
      limit 1
    )
  )
  from public.chat_message_post_refs prf
  inner join public.posts p on p.id = prf.post_id
  where prf.message_id = p_message_id
    and p.deleted_at is null
  limit 1;
$$;

revoke all on function public._chat_post_ref_json(uuid) from public;

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
    'post_ref', public._chat_post_ref_json(b.id)
  )
  from public.chat_messages b
  join public.profiles pr on pr.id = b.sender_id
  where b.id = p_message_id
    and b.deleted_at is null;
$$;

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
    public._chat_post_ref_json(b.id) as post_ref
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
    public._chat_post_ref_json(b.id) as post_ref
  from public.chat_messages b
  join public.profiles pr on pr.id = b.sender_id
  where b.id = p_message_id;
end;
$$;

revoke all on function public.list_messages_enriched(uuid, int, timestamptz) from public;
grant execute on function public.list_messages_enriched(uuid, int, timestamptz) to authenticated;

revoke all on function public.get_message_enriched(uuid) from public;
grant execute on function public.get_message_enriched(uuid) to authenticated;

-- Ensure post_ref row is always created (remove silent skip on conflict).
create or replace function public.send_message(
  p_conversation_id uuid,
  p_kind text,
  p_text text default null,
  p_reply_to uuid default null,
  p_forward_from uuid default null,
  p_post_id uuid default null,
  p_client_message_id uuid default null
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
    conversation_id,
    sender_id,
    kind,
    text,
    reply_to_message_id,
    forwarded_from_message_id,
    client_message_id
  )
  values (
    p_conversation_id,
    uid,
    mk,
    nullif(p_text, ''),
    p_reply_to,
    p_forward_from,
    p_client_message_id
  )
  returning id into mid;

  if mk = 'post_ref' then
    if p_post_id is null then
      raise exception 'post_id_required' using errcode = 'P0012';
    end if;
    insert into public.chat_message_post_refs (message_id, post_id, caption)
    values (mid, p_post_id, nullif(p_text, ''));
  end if;

  return mid;
end;
$$;

revoke all on function public.send_message(uuid, text, text, uuid, uuid, uuid, uuid) from public;
grant execute on function public.send_message(uuid, text, text, uuid, uuid, uuid, uuid) to authenticated;

notify pgrst, 'reload schema';
