-- Chat inbox/push preview: EN keys (not RU labels). Clients / drain localize.

create or replace function public.chat_broadcast_message_after_insert()
returns trigger
language plpgsql
security definer
set search_path = public
set row_security to off
as $$
declare
  payload jsonb;
  member record;
  preview text;
  sender_name text;
  kind_text text;
begin
  if new.deleted_at is not null then
    return new;
  end if;

  kind_text := coalesce(new.kind::text, 'text');

  -- Thread payload for text/post/system/etc. Media/file: sent after attachments in RPC.
  if kind_text not in ('media', 'file') then
    payload := public._chat_message_enriched_json(new.id);
    if payload is not null then
      perform realtime.send(
        payload,
        'message_enriched',
        'chat_thread_' || new.conversation_id::text,
        false
      );
    end if;
  end if;

  -- Free text stays as-is; placeholders = English keys (localize on client / FCM drain).
  preview := case
    when kind_text = 'text' then left(coalesce(nullif(trim(new.text), ''), 'message'), 120)
    when kind_text = 'media' then 'photo'
    when kind_text = 'file' then 'file'
    when kind_text = 'post_ref' then 'post'
    when kind_text = 'system' then left(coalesce(nullif(trim(new.text), ''), 'system'), 120)
    else 'message'
  end;

  select coalesce(nullif(trim(pr.username), ''), 'Clover')
    into sender_name
  from public.profiles pr
  where pr.id = new.sender_id;

  for member in
    select p.user_id
    from public.chat_participants p
    where p.conversation_id = new.conversation_id
      and p.left_at is null
  loop
    perform realtime.send(
      jsonb_build_object(
        'conversation_id', new.conversation_id::text,
        'message_id', new.id::text,
        'sender_id', new.sender_id::text,
        'sender_username', coalesce(sender_name, 'Clover'),
        'kind', kind_text,
        'preview', preview,
        'created_at', new.created_at
      ),
      'inbox_changed',
      'chat_inbox_' || member.user_id::text,
      false
    );

    if member.user_id is distinct from new.sender_id then
      insert into public.push_outbox (user_id, kind, title, body, payload)
      values (
        member.user_id,
        'chat_message',
        coalesce(sender_name, 'Clover'),
        preview,
        jsonb_build_object(
          'kind', 'chat_message',
          'conversation_id', new.conversation_id::text,
          'message_id', new.id::text,
          'sender_id', new.sender_id::text,
          'peer_username', coalesce(sender_name, 'chat'),
          'message_kind', kind_text,
          'preview_key', preview
        )
      );
    end if;
  end loop;

  return new;
end;
$$;

comment on function public.chat_broadcast_message_after_insert() is
  'Inbox + push on insert; preview placeholders = EN keys (photo/file/post/message/system).';
