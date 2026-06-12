-- REST GET на chat_participants падал с 500: SELECT-политика проверяла членство через
-- подзапрос к той же таблице → повторное применение RLS на каждой строке → рекурсия.
-- Вынесем проверку в SECURITY DEFINER с row_security off (как chat_assert_participant).

create or replace function public.chat_session_is_active_participant(p_conversation_id uuid)
returns boolean
language sql
security definer
set search_path = public
set row_security to off
stable
as $$
  select exists (
    select 1
    from public.chat_participants p
    where p.conversation_id = p_conversation_id
      and p.user_id = auth.uid()
      and p.left_at is null
  );
$$;

revoke all on function public.chat_session_is_active_participant(uuid) from public;
grant execute on function public.chat_session_is_active_participant(uuid) to authenticated;

drop policy if exists chat_participants_select_participant on public.chat_participants;

create policy chat_participants_select_participant
  on public.chat_participants for select
  using (public.chat_session_is_active_participant(chat_participants.conversation_id));
