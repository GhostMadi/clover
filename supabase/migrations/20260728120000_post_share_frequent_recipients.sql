-- Top recipients for post sharing in DMs (post_ref messages to followed users).

create or replace function public.list_post_share_frequent_recipients(p_limit int default 10)
returns table (
  profile_id uuid,
  username text,
  avatar_url text,
  share_count bigint
)
language sql
stable
security definer
set search_path = public
set row_security to off
as $$
  with my_shares as (
    select
      m.conversation_id,
      m.created_at
    from public.chat_messages m
    inner join public.chat_message_post_refs pr on pr.message_id = m.id
    where m.sender_id = auth.uid()
      and m.deleted_at is null
  ),
  dm_peers as (
    select
      s.conversation_id,
      s.created_at,
      p.user_id as peer_id
    from my_shares s
    inner join public.chat_conversations c
      on c.id = s.conversation_id
     and c.type = 'dm'
    inner join public.chat_participants p
      on p.conversation_id = s.conversation_id
     and p.user_id <> auth.uid()
     and p.left_at is null
  ),
  scored as (
    select
      dp.peer_id as profile_id,
      count(*)::bigint as share_count,
      max(dp.created_at) as last_shared_at
    from dm_peers dp
    inner join public.profile_follows f
      on f.follower_id = auth.uid()
     and f.following_id = dp.peer_id
    group by dp.peer_id
  )
  select
    pr.id as profile_id,
    case when pr.reset_at is not null then 'noName' else pr.username end as username,
    case when pr.reset_at is not null then null else pr.avatar_url end as avatar_url,
    s.share_count
  from scored s
  inner join public.profiles pr on pr.id = s.profile_id
  where pr.content_visible = true
    and pr.account_state <> 'hibernate'
  order by s.share_count desc, s.last_shared_at desc
  limit least(greatest(coalesce(p_limit, 10), 1), 50);
$$;

revoke all on function public.list_post_share_frequent_recipients(int) from public;
grant execute on function public.list_post_share_frequent_recipients(int) to authenticated;

comment on function public.list_post_share_frequent_recipients(int) is
  'Top followed users the current user shared posts with in DMs (post_ref).';

notify pgrst, 'reload schema';
