-- Курсор last_read_message_id только «вперёд» по шкале сообщений (created_at, id).
-- Раньше: coalesce(p, old) мог откатить курсор при рассинхроне клиента или старом p.

create or replace function public.mark_conversation_read(p_conversation_id uuid, p_last_message_id uuid default null)
returns void
language plpgsql
security definer
set search_path = public
set row_security to off
as $$
declare
  uid uuid;
begin
  uid := auth.uid();
  if uid is null then
    raise exception 'not_authenticated' using errcode = 'P0003';
  end if;

  perform public.chat_assert_participant(p_conversation_id);

  update public.chat_participants cp
  set
    last_read_at = now(),
    last_read_message_id = case
      when p_last_message_id is null then cp.last_read_message_id
      when not exists (
        select 1
        from public.chat_messages mm
        where mm.id = p_last_message_id
          and mm.conversation_id = p_conversation_id
          and mm.deleted_at is null
      ) then cp.last_read_message_id
      when cp.last_read_message_id is null then p_last_message_id
      else (
        select mm.id
        from public.chat_messages mm
        where mm.conversation_id = p_conversation_id
          and mm.deleted_at is null
          and mm.id in (cp.last_read_message_id, p_last_message_id)
        order by mm.created_at desc, mm.id desc
        limit 1
      )
    end
  where cp.conversation_id = p_conversation_id
    and cp.user_id = uid
    and cp.left_at is null;
end;
$$;
