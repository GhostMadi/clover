-- Batch follow checks + block/unblock RPCs (social graph).
-- Product: docs/business/blocks.md · docs/business/profile.md
-- Spec: docs/supabase/SPEC_SUPABASE_SOCIAL_GRAPH_AND_ACCOUNT.md

-- --------------------------------------------------------------------------- is_following_users (batch)
create or replace function public.is_following_users(p_targets uuid[])
returns table (
  profile_id uuid,
  is_following boolean
)
language sql
stable
security definer
set search_path = public
set row_security to off
as $$
  select
    t.profile_id,
    exists (
      select 1
      from public.profile_follows f
      where f.follower_id = auth.uid()
        and f.following_id = t.profile_id
    ) as is_following
  from (
    select distinct x as profile_id
    from unnest(coalesce(p_targets, array[]::uuid[])) as x
    where x is not null
  ) t;
$$;

revoke all on function public.is_following_users(uuid[]) from public;
grant execute on function public.is_following_users(uuid[]) to authenticated;

comment on function public.is_following_users(uuid[]) is
  'Batch: whether auth.uid() follows each id in p_targets. Empty/null → no rows.';

-- --------------------------------------------------------------------------- block_user
create or replace function public.block_user(p_target uuid)
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

  if p_target is null or p_target = uid then
    raise exception 'cannot_block_self' using errcode = 'P0007';
  end if;

  if not exists (select 1 from public.profiles pr where pr.id = p_target) then
    raise exception 'user_not_found' using errcode = 'P0008';
  end if;

  insert into public.profile_blocks (blocker_id, blocked_id)
  values (uid, p_target)
  on conflict do nothing;

  -- Drop follow edges both ways (block ends the relationship).
  delete from public.profile_follows
  where (follower_id = uid and following_id = p_target)
     or (follower_id = p_target and following_id = uid);
end;
$$;

revoke all on function public.block_user(uuid) from public;
grant execute on function public.block_user(uuid) to authenticated;

comment on function public.block_user(uuid) is
  'Caller blocks p_target; removes follow both ways. Idempotent.';

-- --------------------------------------------------------------------------- unblock_user
create or replace function public.unblock_user(p_target uuid)
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

  if p_target is null then
    return;
  end if;

  delete from public.profile_blocks
  where blocker_id = uid
    and blocked_id = p_target;
end;
$$;

revoke all on function public.unblock_user(uuid) from public;
grant execute on function public.unblock_user(uuid) to authenticated;

comment on function public.unblock_user(uuid) is
  'Caller removes block of p_target. Idempotent.';

-- --------------------------------------------------------------------------- list_my_blocked_users
create or replace function public.list_my_blocked_users(
  p_limit int default 50,
  p_offset int default 0
)
returns table (
  profile_id uuid,
  username text,
  avatar_url text
)
language sql
stable
security definer
set search_path = public
set row_security to off
as $$
  select
    pr.id as profile_id,
    pr.username,
    pr.avatar_url
  from public.profile_blocks b
  inner join public.profiles pr on pr.id = b.blocked_id
  where b.blocker_id = auth.uid()
  order by b.created_at desc
  limit greatest(1, least(coalesce(p_limit, 50), 100))
  offset greatest(0, coalesce(p_offset, 0));
$$;

revoke all on function public.list_my_blocked_users(int, int) from public;
grant execute on function public.list_my_blocked_users(int, int) to authenticated;

comment on function public.list_my_blocked_users(int, int) is
  'Profiles blocked by auth.uid(), newest first.';
