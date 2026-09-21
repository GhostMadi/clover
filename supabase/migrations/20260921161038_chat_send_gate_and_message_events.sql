-- --------------------------------------------------------------------------- send_message
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
  perform public.chat_assert_dm_interactable(p_conversation_id);

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

-- --------------------------------------------------------------------------- delete / edit + broadcast
create or replace function public.delete_message(p_message_id uuid)
returns void
language plpgsql
security definer
set search_path = public
set row_security to off
as $$
declare
  uid uuid;
  conv uuid;
  updated int;
begin
  uid := auth.uid();
  if uid is null then
    raise exception 'not_authenticated' using errcode = 'P0003';
  end if;

  select m.conversation_id into conv
  from public.chat_messages m
  where m.id = p_message_id
    and m.deleted_at is null;

  if conv is null then
    raise exception 'message_not_found' using errcode = 'P0014';
  end if;

  perform public.chat_assert_participant(conv);

  update public.chat_messages
  set deleted_at = now()
  where id = p_message_id
    and sender_id = uid
    and deleted_at is null;

  get diagnostics updated = row_count;
  if updated > 0 then
    perform realtime.send(
      jsonb_build_object(
        'message_id', p_message_id,
        'conversation_id', conv,
        'reason', 'deleted'
      ),
      'message_removed',
      'chat_thread_' || conv::text,
      false
    );
  end if;
end;
$$;

create or replace function public.edit_message(
  p_message_id uuid,
  p_text text
)
returns void
language plpgsql
security definer
set search_path = public
set row_security to off
as $$
declare
  uid uuid;
  conv uuid;
  body text;
  updated int;
  payload jsonb;
begin
  uid := auth.uid();
  if uid is null then
    raise exception 'not_authenticated' using errcode = 'P0003';
  end if;

  body := nullif(trim(coalesce(p_text, '')), '');
  if body is null then
    raise exception 'empty_text' using errcode = 'P0016';
  end if;

  select m.conversation_id into conv
  from public.chat_messages m
  where m.id = p_message_id
    and m.deleted_at is null
    and m.kind = 'text';

  if conv is null then
    raise exception 'message_not_found' using errcode = 'P0014';
  end if;

  perform public.chat_assert_participant(conv);

  update public.chat_messages
  set text = body,
      edited_at = now()
  where id = p_message_id
    and sender_id = uid
    and kind = 'text'
    and deleted_at is null;

  get diagnostics updated = row_count;
  if updated > 0 then
    payload := public._chat_message_enriched_json(p_message_id);
    if payload is not null then
      perform realtime.send(
        payload,
        'message_updated',
        'chat_thread_' || conv::text,
        false
      );
    end if;
  end if;
end;
$$;

revoke all on function public.delete_message(uuid) from public;
revoke all on function public.edit_message(uuid, text) from public;
grant execute on function public.delete_message(uuid) to authenticated;
grant execute on function public.edit_message(uuid, text) to authenticated;

notify pgrst, 'reload schema';
