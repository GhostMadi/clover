-- Enriched-сообщение в Realtime Broadcast сразу после INSERT (тот же JSON, что get_message_enriched).
-- Клиент: topic = 'chat_thread_' || conversation_id, event = 'message_enriched', public channel.
-- См. также: migrations/_chat/README.md (Realtime), companion broadcast peer_read — 20260429140000_chat_broadcast_peer_read.sql.

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
    'post_ref', (
      select jsonb_build_object('post_id', prf.post_id, 'caption', prf.caption)
      from public.chat_message_post_refs prf
      where prf.message_id = b.id
      limit 1
    )
  )
  from public.chat_messages b
  join public.profiles pr on pr.id = b.sender_id
  where b.id = p_message_id
    and b.deleted_at is null;
$$;

revoke all on function public._chat_message_enriched_json(uuid) from public;

create or replace function public.chat_broadcast_message_after_insert()
returns trigger
language plpgsql
security definer
set search_path = public
set row_security to off
as $$
declare
  payload jsonb;
begin
  if new.deleted_at is not null then
    return new;
  end if;

  payload := public._chat_message_enriched_json(new.id);
  if payload is null then
    return new;
  end if;

  perform realtime.send(
    payload,
    'message_enriched',
    'chat_thread_' || new.conversation_id::text,
    false
  );
  return new;
end;
$$;

drop trigger if exists chat_messages_broadcast_enriched_after_insert on public.chat_messages;

create trigger chat_messages_broadcast_enriched_after_insert
  after insert on public.chat_messages
  for each row
  execute function public.chat_broadcast_message_after_insert();

-- Realtime Authorization (при необходимости сузьте USING): https://supabase.com/docs/guides/realtime/broadcast
do $$
begin
  execute 'drop policy if exists "authenticated can receive chat broadcasts" on realtime.messages';
  execute $pol$
    create policy "authenticated can receive chat broadcasts"
      on realtime.messages
      for select
      to authenticated
      using (true);
  $pol$;
exception
  when undefined_table then
    null;
end;
$$;
