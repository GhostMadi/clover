-- Мгновенное обновление галочек «прочитано» у отправителя: broadcast на тот же topic, что и message_enriched.
-- Клиент: channel name = 'chat_thread_' || conversation_id, event = 'peer_read'.
-- Обзор всех миграций чата и цепочки Realtime: migrations/_chat/README.md (раздел «Realtime и прочитано»).

create or replace function public.chat_broadcast_peer_read_after_update()
returns trigger
language plpgsql
security definer
set search_path = public
set row_security to off
as $$
declare
  payload jsonb;
begin
  if new.left_at is not null then
    return new;
  end if;

  if old.last_read_message_id is not distinct from new.last_read_message_id
     and old.last_read_at is not distinct from new.last_read_at then
    return new;
  end if;

  payload := jsonb_build_object(
    'conversation_id', new.conversation_id::text,
    'user_id', new.user_id::text,
    'last_read_message_id',
      case when new.last_read_message_id is null then null else new.last_read_message_id::text end,
    'last_read_at', new.last_read_at
  );

  perform realtime.send(
    payload,
    'peer_read',
    'chat_thread_' || new.conversation_id::text,
    false
  );

  return new;
end;
$$;

drop trigger if exists chat_participants_broadcast_peer_read_after_update on public.chat_participants;

create trigger chat_participants_broadcast_peer_read_after_update
  after update on public.chat_participants
  for each row
  execute function public.chat_broadcast_peer_read_after_update();
