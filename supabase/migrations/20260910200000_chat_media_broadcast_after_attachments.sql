-- Fix: media/file message_enriched fired on chat_messages INSERT before attachments exist.
-- Skip thread broadcast for media/file in AFTER INSERT trigger; send it from
-- send_message_with_attachments after attachments are written.
-- Inbox + push still fire immediately (preview «Фото»).

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

  preview := case
    when kind_text = 'text' then left(coalesce(nullif(trim(new.text), ''), 'Сообщение'), 120)
    when kind_text = 'media' then 'Фото'
    when kind_text = 'file' then 'Файл'
    when kind_text = 'post_ref' then 'Пост'
    when kind_text = 'system' then left(coalesce(nullif(trim(new.text), ''), 'Системное'), 120)
    else 'Сообщение'
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
          'peer_username', coalesce(sender_name, 'чат')
        )
      );
    end if;
  end loop;

  return new;
end;
$$;

comment on function public.chat_broadcast_message_after_insert() is
  'Inbox + push on insert; message_enriched for non-media. Media/file enriched via send_message_with_attachments.';

create or replace function public.send_message_with_attachments(
  p_conversation_id uuid,
  p_kind text,
  p_text text default null,
  p_reply_to uuid default null,
  p_attachments jsonb default '[]'::jsonb,
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
  elem jsonb;
  att_count int;
  pth text;
  bkt text;
  pub text;
  payload jsonb;
begin
  uid := auth.uid();
  if uid is null then
    raise exception 'not_authenticated' using errcode = 'P0003';
  end if;

  perform public.chat_assert_participant(p_conversation_id);

  if p_client_message_id is not null then
    select m.id into mid
    from public.chat_messages m
    where m.client_message_id = p_client_message_id
    limit 1;
    if mid is not null then
      return mid;
    end if;
  end if;

  att_count := coalesce(jsonb_array_length(coalesce(p_attachments, '[]'::jsonb)), 0);
  if att_count < 1 then
    raise exception 'attachments_required' using errcode = 'P0013';
  end if;
  if att_count > 100 then
    raise exception 'too_many_attachments' using errcode = 'P0014';
  end if;

  mk := coalesce(nullif(trim(coalesce(p_kind, '')), ''), 'media')::public.chat_message_kind;
  if mk not in ('media'::public.chat_message_kind, 'file'::public.chat_message_kind) then
    raise exception 'invalid_kind_for_attachments' using errcode = 'P0015';
  end if;

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
    nullif(trim(coalesce(p_text, '')), ''),
    p_reply_to,
    null,
    p_client_message_id
  )
  returning id into mid;

  for elem in select value from jsonb_array_elements(coalesce(p_attachments, '[]'::jsonb)) as x(value)
  loop
    bkt := nullif(trim(coalesce(elem->>'bucket', '')), '');
    pth := nullif(trim(coalesce(elem->>'path', '')), '');
    pub := nullif(trim(coalesce(elem->>'public_url', '')), '');

    if bkt is null or bkt = '' or pth is null or pth = '' then
      raise exception 'attachment_missing_bucket_or_path' using errcode = 'P0016';
    end if;

    if bkt = 'chat_media' then
      if pth not like (uid::text || '/%') then
        raise exception 'attachment_path_not_owned' using errcode = 'P0018';
      end if;
    elsif bkt = 'r2' then
      if position('/' || uid::text || '/' in '/' || pth || '/') = 0 then
        raise exception 'attachment_path_not_owned' using errcode = 'P0018';
      end if;
      if pub is null or pub = '' then
        raise exception 'attachment_missing_public_url' using errcode = 'P0019';
      end if;
      if pub not like 'https://%' and pub not like 'http://%' then
        raise exception 'attachment_invalid_public_url' using errcode = 'P0020';
      end if;
    else
      raise exception 'invalid_attachment_bucket' using errcode = 'P0017';
    end if;

    insert into public.chat_message_attachments (
      message_id,
      bucket,
      path,
      public_url,
      mime,
      size_bytes,
      width,
      height,
      duration_ms,
      preview_path
    )
    values (
      mid,
      bkt,
      pth,
      pub,
      nullif(trim(elem->>'mime'), ''),
      case when elem ? 'size_bytes' and nullif(trim(elem->>'size_bytes'), '') is not null
        then (elem->>'size_bytes')::bigint else null end,
      case when elem ? 'width' and nullif(trim(elem->>'width'), '') is not null
        then (elem->>'width')::int else null end,
      case when elem ? 'height' and nullif(trim(elem->>'height'), '') is not null
        then (elem->>'height')::int else null end,
      case when elem ? 'duration_ms' and nullif(trim(elem->>'duration_ms'), '') is not null
        then (elem->>'duration_ms')::int else null end,
      nullif(trim(elem->>'preview_path'), '')
    );
  end loop;

  -- Now attachments exist — deliver full enriched payload to open threads.
  payload := public._chat_message_enriched_json(mid);
  if payload is not null then
    perform realtime.send(
      payload,
      'message_enriched',
      'chat_thread_' || p_conversation_id::text,
      false
    );
  end if;

  return mid;
end;
$$;

revoke all on function public.send_message_with_attachments(uuid, text, text, uuid, jsonb, uuid) from public;
grant execute on function public.send_message_with_attachments(uuid, text, text, uuid, jsonb, uuid) to authenticated;

comment on function public.send_message_with_attachments(uuid, text, text, uuid, jsonb, uuid) is
  'Insert message + attachments then broadcast message_enriched (with attachments).';
