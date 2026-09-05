-- Chat messenger basics: soft-delete + edit text messages.

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
end;
$$;

revoke all on function public.delete_message(uuid) from public;
revoke all on function public.edit_message(uuid, text) from public;
grant execute on function public.delete_message(uuid) to authenticated;
grant execute on function public.edit_message(uuid, text) to authenticated;
