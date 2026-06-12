-- Blocks, follow notifications, following feed RPC, reconcile counters.
-- See supabase/SPEC_SUPABASE_SOCIAL_GRAPH_AND_ACCOUNT.md

-- --------------------------------------------------------------------------- profile_blocks
create table if not exists public.profile_blocks (
  blocker_id uuid not null
    references public.profiles (id) on delete cascade,
  blocked_id uuid not null
    references public.profiles (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (blocker_id, blocked_id),
  constraint profile_blocks_no_self check (blocker_id <> blocked_id)
);

create index if not exists profile_blocks_blocker_id_idx on public.profile_blocks (blocker_id);
create index if not exists profile_blocks_blocked_id_idx on public.profile_blocks (blocked_id);

comment on table public.profile_blocks is 'Directed block: blocker_id blocked blocked_id; symmetric check in can_user_interact for follow.';

alter table public.profile_blocks enable row level security;

-- Owner sees own outgoing blocks
drop policy if exists profile_blocks_select_own on public.profile_blocks;
create policy profile_blocks_select_own
  on public.profile_blocks for select
  to authenticated
  using (blocker_id = auth.uid());

drop policy if exists profile_blocks_insert_own on public.profile_blocks;
create policy profile_blocks_insert_own
  on public.profile_blocks for insert
  to authenticated
  with check (blocker_id = auth.uid());

drop policy if exists profile_blocks_delete_own on public.profile_blocks;
create policy profile_blocks_delete_own
  on public.profile_blocks for delete
  to authenticated
  using (blocker_id = auth.uid());

-- --------------------------------------------------------------------------- notification_events (follow dedupe)
create table if not exists public.notification_events (
  id uuid primary key default gen_random_uuid(),
  dedupe_key text not null,
  recipient_id uuid not null
    references public.profiles (id) on delete cascade,
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  constraint notification_events_dedupe_key_unique unique (dedupe_key)
);

create index if not exists notification_events_recipient_created_idx
  on public.notification_events (recipient_id, created_at desc);

comment on table public.notification_events is 'At-least-once events with dedupe_key; push delivery out of band.';

alter table public.notification_events enable row level security;

-- No direct client access; written from follow_user (definer)
revoke all on table public.notification_events from anon;
revoke all on table public.notification_events from authenticated;

-- --------------------------------------------------------------------------- can_user_interact
create or replace function public.can_user_interact(p_actor uuid, p_target uuid)
returns boolean
language sql
stable
security definer
set search_path = public
set row_security to off
as $$
  select
    p_actor is not null
    and p_target is not null
    and p_actor <> p_target
    and exists (select 1 from public.profiles pr where pr.id = p_actor)
    and exists (select 1 from public.profiles pr where pr.id = p_target)
    and not exists (
      select 1
      from public.profile_blocks b
      where (b.blocker_id = p_actor and b.blocked_id = p_target)
         or (b.blocker_id = p_target and b.blocked_id = p_actor)
    );
$$;

revoke all on function public.can_user_interact(uuid, uuid) from public;
grant execute on function public.can_user_interact(uuid, uuid) to authenticated, anon;

comment on function public.can_user_interact(uuid, uuid) is
  'True if both profiles exist, not self, and no symmetric block for follow-style actions.';

-- --------------------------------------------------------------------------- follow_user: blocks, rate limit, notification
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
  n int;
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

  if not public.can_user_interact(uid, p_target) then
    raise exception 'user_blocked' using errcode = 'P0009';
  end if;

  select count(*)::int into n
  from public.profile_follows f
  where f.follower_id = uid
    and f.created_at > now() - interval '1 hour';

  if n >= 200 then
    raise exception 'follow_rate_limited' using errcode = 'P0010';
  end if;

  with ins as (
    insert into public.profile_follows (follower_id, following_id)
    values (uid, p_target)
    on conflict do nothing
    returning 1 as x
  )
  insert into public.notification_events (dedupe_key, recipient_id, payload)
  select
    'follow:' || uid::text || ':' || p_target::text,
    p_target,
    jsonb_build_object(
      'type', 'follow',
      'actor_id', uid,
      'message', 'started following you'
    )
  from ins
  on conflict (dedupe_key) do nothing;
end;
$$;

-- --------------------------------------------------------------------------- list_following_feed_enriched_cursor
-- Posts from users the viewer follows; same visibility as hot feed (not hibernate, content_visible).
create or replace function public.list_following_feed_enriched_cursor(
  p_limit int default 24,
  p_cursor_created_at timestamptz default null,
  p_cursor_id uuid default null
)
returns table (
  post jsonb,
  author jsonb,
  my_reaction text,
  my_saved boolean
)
language sql
stable
security invoker
set search_path = public
as $$
  select
    (
      to_jsonb(p.*)
      || jsonb_build_object(
        'post_media',
        coalesce(
          (
            select jsonb_agg(to_jsonb(pm.*) order by pm.sort_order asc)
            from public.post_media pm
            where pm.post_id = p.id
          ),
          '[]'::jsonb
        )
      )
    ) as post,
    public.author_mini_json(pr.id) as author,
    r.kind as my_reaction,
    (ps_me.post_id is not null) as my_saved
  from public.posts p
  inner join public.profiles pr on pr.id = p.user_id
  inner join public.profile_follows ff
    on ff.following_id = p.user_id
   and ff.follower_id = auth.uid()
  left join public.post_reactions r
    on r.post_id = p.id
   and r.user_id = auth.uid()
  left join public.post_saves ps_me
    on ps_me.post_id = p.id
   and ps_me.user_id = auth.uid()
  where p.is_archived = false
    and p.deleted_at is null
    and pr.content_visible = true
    and pr.account_state <> 'hibernate'
    and (
      p_cursor_id is null
      or (p.created_at, p.id) < (p_cursor_created_at, p_cursor_id)
    )
  order by p.created_at desc, p.id desc
  limit least(greatest(coalesce(p_limit, 24), 1), 100);
$$;

revoke all on function public.list_following_feed_enriched_cursor(int, timestamptz, uuid) from public;
grant execute on function public.list_following_feed_enriched_cursor(int, timestamptz, uuid) to authenticated;

comment on function public.list_following_feed_enriched_cursor(int, timestamptz, uuid) is
  'Home feed by following: keyset cursor; visibility aligned with hibernate rules.';

-- --------------------------------------------------------------------------- reconcile (service_role / cron)
create or replace function public.reconcile_profile_follow_counts()
returns void
language plpgsql
security definer
set search_path = public
set row_security to off
as $$
begin
  -- Single pass: two aggregates over profile_follows, then update only drift rows.
  update public.profiles p
  set
    followers_count = coalesce(fc.c, 0),
    following_count = coalesce(fw.c, 0)
  from public.profiles pr
  left join (
    select following_id as id, count(*)::int as c
    from public.profile_follows
    group by following_id
  ) fc on fc.id = pr.id
  left join (
    select follower_id as id, count(*)::int as c
    from public.profile_follows
    group by follower_id
  ) fw on fw.id = pr.id
  where p.id = pr.id
    and (
      p.followers_count is distinct from coalesce(fc.c, 0)
      or p.following_count is distinct from coalesce(fw.c, 0)
    );
end;
$$;

revoke all on function public.reconcile_profile_follow_counts() from public;
grant execute on function public.reconcile_profile_follow_counts() to service_role;

comment on function public.reconcile_profile_follow_counts() is
  'Recompute followers_count/following_count from profile_follows for all drift rows; run via cron off-peak.';
