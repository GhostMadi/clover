-- Social graph: profile_follows + denormalized counters on profiles.
-- Follow/unfollow only via RPC (hibernate targets rejected).

-- --------------------------------------------------------------------------- profiles: counters
alter table public.profiles
  add column if not exists followers_count integer not null default 0,
  add column if not exists following_count integer not null default 0;

do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'profiles_followers_count_non_negative'
  ) then
    alter table public.profiles
      add constraint profiles_followers_count_non_negative check (followers_count >= 0);
  end if;
  if not exists (
    select 1 from pg_constraint where conname = 'profiles_following_count_non_negative'
  ) then
    alter table public.profiles
      add constraint profiles_following_count_non_negative check (following_count >= 0);
  end if;
end $$;

comment on column public.profiles.followers_count is 'Denormalized: rows in profile_follows where following_id = id';
comment on column public.profiles.following_count is 'Denormalized: rows in profile_follows where follower_id = id';

-- --------------------------------------------------------------------------- profile_follows
create table if not exists public.profile_follows (
  follower_id uuid not null
    references public.profiles (id) on delete cascade,
  following_id uuid not null
    references public.profiles (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (follower_id, following_id),
  constraint profile_follows_no_self check (follower_id <> following_id)
);

create index if not exists profile_follows_follower_id_idx
  on public.profile_follows (follower_id);

create index if not exists profile_follows_following_id_idx
  on public.profile_follows (following_id);

comment on table public.profile_follows is 'Directed follow: follower_id follows following_id';

-- Backfill counters from existing rows (empty on fresh install).
update public.profiles p
set
  followers_count = coalesce((
    select count(*)::int from public.profile_follows f where f.following_id = p.id
  ), 0),
  following_count = coalesce((
    select count(*)::int from public.profile_follows f where f.follower_id = p.id
  ), 0);

-- --------------------------------------------------------------------------- Triggers: keep counts in sync
create or replace function public.profile_follows_apply_counts_on_insert()
returns trigger
language plpgsql
security definer
set search_path = public
set row_security to off
as $$
begin
  update public.profiles
  set following_count = following_count + 1
  where id = new.follower_id;

  update public.profiles
  set followers_count = followers_count + 1
  where id = new.following_id;

  return new;
end;
$$;

create or replace function public.profile_follows_apply_counts_on_delete()
returns trigger
language plpgsql
security definer
set search_path = public
set row_security to off
as $$
begin
  update public.profiles
  set following_count = greatest(following_count - 1, 0)
  where id = old.follower_id;

  update public.profiles
  set followers_count = greatest(followers_count - 1, 0)
  where id = old.following_id;

  return old;
end;
$$;

drop trigger if exists trg_profile_follows_ai on public.profile_follows;
create trigger trg_profile_follows_ai
  after insert on public.profile_follows
  for each row
  execute function public.profile_follows_apply_counts_on_insert();

drop trigger if exists trg_profile_follows_ad on public.profile_follows;
create trigger trg_profile_follows_ad
  after delete on public.profile_follows
  for each row
  execute function public.profile_follows_apply_counts_on_delete();

-- --------------------------------------------------------------------------- RLS: no direct client DML
alter table public.profile_follows enable row level security;

revoke all on table public.profile_follows from anon;
revoke all on table public.profile_follows from authenticated;

-- --------------------------------------------------------------------------- RPC: follow / unfollow
create or replace function public.follow_user(p_target uuid)
returns void
language plpgsql
security definer
set search_path = public
set row_security to off
as $$
declare
  uid uuid;
  st text;
begin
  uid := auth.uid();
  if uid is null then
    raise exception 'not_authenticated' using errcode = 'P0003';
  end if;

  if p_target is null or p_target = uid then
    raise exception 'cannot_follow_self' using errcode = 'P0007';
  end if;

  select p.account_state into st
  from public.profiles p
  where p.id = p_target;

  if not found then
    raise exception 'user_not_found' using errcode = 'P0008';
  end if;

  if st = 'hibernate' then
    raise exception 'user_sleeping' using errcode = 'P0006';
  end if;

  insert into public.profile_follows (follower_id, following_id)
  values (uid, p_target)
  on conflict do nothing;
end;
$$;

create or replace function public.unfollow_user(p_target uuid)
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
    return;
  end if;

  delete from public.profile_follows
  where follower_id = uid
    and following_id = p_target;
end;
$$;

create or replace function public.is_following_user(p_target uuid)
returns boolean
language sql
stable
security definer
set search_path = public
set row_security to off
as $$
  select exists (
    select 1
    from public.profile_follows f
    where f.follower_id = auth.uid()
      and f.following_id = p_target
  );
$$;

-- --------------------------------------------------------------------------- Lists (mini profile rows; reset → noName in UI contract)
create or replace function public.list_profile_followers(
  p_profile_id uuid,
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
    case when pr.reset_at is not null then 'noName' else pr.username end as username,
    case when pr.reset_at is not null then null else pr.avatar_url end as avatar_url
  from public.profile_follows f
  inner join public.profiles pr on pr.id = f.follower_id
  where f.following_id = p_profile_id
  order by f.created_at desc
  limit least(greatest(coalesce(p_limit, 50), 1), 200)
  offset greatest(coalesce(p_offset, 0), 0);
$$;

create or replace function public.list_profile_following(
  p_profile_id uuid,
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
    case when pr.reset_at is not null then 'noName' else pr.username end as username,
    case when pr.reset_at is not null then null else pr.avatar_url end as avatar_url
  from public.profile_follows f
  inner join public.profiles pr on pr.id = f.following_id
  where f.follower_id = p_profile_id
  order by f.created_at desc
  limit least(greatest(coalesce(p_limit, 50), 1), 200)
  offset greatest(coalesce(p_offset, 0), 0);
$$;

revoke all on function public.follow_user(uuid) from public;
revoke all on function public.unfollow_user(uuid) from public;
revoke all on function public.is_following_user(uuid) from public;
revoke all on function public.list_profile_followers(uuid, int, int) from public;
revoke all on function public.list_profile_following(uuid, int, int) from public;

grant execute on function public.follow_user(uuid) to authenticated;
grant execute on function public.unfollow_user(uuid) to authenticated;
grant execute on function public.is_following_user(uuid) to authenticated;
grant execute on function public.list_profile_followers(uuid, int, int) to authenticated, anon;
grant execute on function public.list_profile_following(uuid, int, int) to authenticated, anon;

comment on function public.follow_user(uuid) is
  'Create follow edge; rejects target in hibernate (user_sleeping). Idempotent on duplicate.';
comment on function public.unfollow_user(uuid) is 'Remove follow edge for current user.';
comment on function public.is_following_user(uuid) is 'Whether auth.uid() follows p_target.';
comment on function public.list_profile_followers(uuid, int, int) is 'Users who follow p_profile_id.';
comment on function public.list_profile_following(uuid, int, int) is 'Users whom p_profile_id follows.';
