-- Dashboard / cabinet badge: total unread chat messages for auth.uid().
-- Same unread rule as list_conversations_enriched (messages after last_read_at, not mine).

create or replace function public.count_unread_chat_messages()
returns int
language sql
stable
security definer
set search_path = public
set row_security to off
as $$
  with me as (
    select auth.uid() as uid
  )
  select coalesce((
    select count(*)::int
    from public.chat_participants p
    join public.chat_messages msg
      on msg.conversation_id = p.conversation_id
     and msg.deleted_at is null
     and msg.sender_id <> (select uid from me)
     and msg.created_at > coalesce(p.last_read_at, 'epoch'::timestamptz)
    where (select uid from me) is not null
      and p.user_id = (select uid from me)
      and p.left_at is null
  ), 0);
$$;

revoke all on function public.count_unread_chat_messages() from public;
grant execute on function public.count_unread_chat_messages() to authenticated;

comment on function public.count_unread_chat_messages() is
  'Total unread inbound chat messages for the current user (cabinet badge).';
