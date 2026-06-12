-- Идемпотентность оптимистика: клиент задаёт UUID, сервер хранит и возвращает в сообщении и broadcast.

drop function if exists public.send_message(uuid, text, text, uuid, uuid, uuid);

alter table public.chat_messages
  add column if not exists client_message_id uuid null;

comment on column public.chat_messages.client_message_id is 'UUID с клиента (optimistic reconcile); один раз на отправку.';

create unique index if not exists chat_messages_client_message_id_unique
  on public.chat_messages (client_message_id)
  where client_message_id is not null;

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
    values (mid, p_post_id, nullif(p_text, ''))
    on conflict do nothing;
  end if;

  return mid;
end;
$$;

revoke all on function public.send_message(uuid, text, text, uuid, uuid, uuid, uuid) from public;

grant execute on function public.send_message(uuid, text, text, uuid, uuid, uuid, uuid) to authenticated;
