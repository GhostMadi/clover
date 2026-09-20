-- List active participants for chat info screen (DM + group).
-- Caller must be an active participant (chat_assert_participant).

create or replace function public.list_conversation_participants(p_conversation_id uuid)
returns table (
  user_id uuid,
  role text,
  username text,
  avatar_url text,
  joined_at timestamptz
)
language plpgsql
stable
security definer
set search_path = public
set row_security to off
as $$
begin
  perform public.chat_assert_participant(p_conversation_id);

  return query
  select
    p.user_id,
    p.role::text as role,
    coalesce(pr.username, '')::text as username,
    pr.avatar_url::text as avatar_url,
    p.joined_at
  from public.chat_participants p
  join public.profiles pr on pr.id = p.user_id
  where p.conversation_id = p_conversation_id
    and p.left_at is null
  order by
    case when p.role = 'admin' then 0 else 1 end,
    p.joined_at asc,
    pr.username asc nulls last;
end;
$$;

revoke all on function public.list_conversation_participants(uuid) from public;
grant execute on function public.list_conversation_participants(uuid) to authenticated;

comment on function public.list_conversation_participants(uuid) is
  'Active chat participants with profile username/avatar for chat info UI.';
