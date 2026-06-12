-- Account state management: Reset (content wipe) + Hibernate (sleep).
--
-- IMPORTANT:
-- - Reset is an ACTION. We store reset_at (for anonymous display in history) + last_reset_at (rate limit).
-- - Hibernate is a STATE. We store account_state + content_visible + last_hibernate_at (rate limit).
-- - Posts are soft-deleted via posts.deleted_at (already exists). Clusters get soft-delete fields here.
-- - Followers/following are NOT touched by any action here.
--
-- This migration is written to be idempotent (safe to re-apply).

-- --------------------------------------------------------------------------- profiles: state + limits
alter table public.profiles
  add column if not exists account_state text not null default 'active',
  add column if not exists content_visible boolean not null default true,
  add column if not exists reset_at timestamptz null,
  add column if not exists last_reset_at timestamptz null,
  add column if not exists last_hibernate_at timestamptz null;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'profiles_account_state_allowed'
  ) then
    alter table public.profiles
      add constraint profiles_account_state_allowed
      check (account_state in ('active', 'hibernate'));
  end if;
end $$;

comment on column public.profiles.account_state is 'active|hibernate; reset is tracked by reset_at/last_reset_at';
comment on column public.profiles.content_visible is 'Fast flag: when false, hide posts/clusters from other users';
comment on column public.profiles.reset_at is 'If not null: show placeholder author (noName + default avatar) in history';
comment on column public.profiles.last_reset_at is 'Rate limit: reset_account() allowed once per 30 days';
comment on column public.profiles.last_hibernate_at is 'Rate limit: hibernate_account() allowed once per 30 days';

-- --------------------------------------------------------------------------- clusters: soft delete
alter table public.clusters
  add column if not exists deleted_at timestamptz null,
  add column if not exists deleted_reason text null;

comment on column public.clusters.deleted_at is 'Soft delete for Reset; hide from others, keep for audit';

-- --------------------------------------------------------------------------- clusters: update profile.cluster_count to ignore soft-deleted clusters
-- Override the function from 20260402120000_clusters.sql.
create or replace function public.clusters_sync_profile_cluster_count()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  old_counts boolean;
  new_counts boolean;
begin
  old_counts := coalesce(old.deleted_at, null) is null and old.is_archived = false;
  new_counts := coalesce(new.deleted_at, null) is null and new.is_archived = false;

  if (tg_op = 'INSERT') then
    if new_counts then
      perform public.profiles_apply_cluster_count_delta(new.owner_id, 1);
    end if;
    return new;
  end if;

  if (tg_op = 'DELETE') then
    if old_counts then
      perform public.profiles_apply_cluster_count_delta(old.owner_id, -1);
    end if;
    return old;
  end if;

  -- UPDATE
  if (old.owner_id is distinct from new.owner_id) then
    if old_counts then
      perform public.profiles_apply_cluster_count_delta(old.owner_id, -1);
    end if;
    if new_counts then
      perform public.profiles_apply_cluster_count_delta(new.owner_id, 1);
    end if;
    return new;
  end if;

  if (old_counts is distinct from new_counts) then
    if old_counts and not new_counts then
      perform public.profiles_apply_cluster_count_delta(new.owner_id, -1);
    elsif not old_counts and new_counts then
      perform public.profiles_apply_cluster_count_delta(new.owner_id, 1);
    end if;
  end if;

  return new;
end;
$$;

-- --------------------------------------------------------------------------- RLS: hide content from hibernated users (but owners see their own)
-- Posts: author sees all; others only visible authors + not soft-deleted + not archived.
drop policy if exists posts_select_visible on public.posts;
create policy posts_select_visible
  on public.posts
  for select
  to anon, authenticated
  using (
    user_id = auth.uid()
    or (
      deleted_at is null
      and not is_archived
      and exists (
        select 1
        from public.profiles pr
        where pr.id = posts.user_id
          and pr.content_visible = true
          and pr.account_state <> 'hibernate'
      )
    )
  );

-- post_media: visible like its post (reuse same visibility rules).
drop policy if exists post_media_select_visible on public.post_media;
create policy post_media_select_visible
  on public.post_media
  for select
  to anon, authenticated
  using (
    exists (
      select 1
      from public.posts p
      join public.profiles pr on pr.id = p.user_id
      where p.id = post_media.post_id
        and (
          p.user_id = auth.uid()
          or (
            p.deleted_at is null
            and not p.is_archived
            and pr.content_visible = true
            and pr.account_state <> 'hibernate'
          )
        )
    )
  );

-- comments: visible only if the post is visible by the same rules.
drop policy if exists comments_select_visible on public.comments;
create policy comments_select_visible
  on public.comments
  for select
  to anon, authenticated
  using (
    exists (
      select 1
      from public.posts p
      join public.profiles pr on pr.id = p.user_id
      where p.id = comments.post_id
        and (
          p.user_id = auth.uid()
          or (
            p.deleted_at is null
            and not p.is_archived
            and pr.content_visible = true
            and pr.account_state <> 'hibernate'
          )
        )
    )
  );

-- clusters: owner sees all; others only not archived + not soft-deleted + visible owner.
drop policy if exists clusters_select_visible on public.clusters;
create policy clusters_select_visible
  on public.clusters
  for select
  to anon, authenticated
  using (
    owner_id = auth.uid()
    or (
      deleted_at is null
      and not is_archived
      and exists (
        select 1
        from public.profiles pr
        where pr.id = clusters.owner_id
          and pr.content_visible = true
          and pr.account_state <> 'hibernate'
      )
    )
  );

-- --------------------------------------------------------------------------- RPC helpers: author anonymization if reset_at is set
create or replace function public.author_mini_json(p_profile_id uuid)
returns jsonb
language sql
stable
security invoker
set search_path = public
as $$
  select jsonb_build_object(
    'id', pr.id,
    'username', case when pr.reset_at is not null then 'noName' else pr.username end,
    'avatar_url', case when pr.reset_at is not null then null else pr.avatar_url end
  )
  from public.profiles pr
  where pr.id = p_profile_id;
$$;

comment on function public.author_mini_json(uuid) is
  'Mini author payload with reset anonymization (noName + null avatar).';

revoke all on function public.author_mini_json(uuid) from public;
grant execute on function public.author_mini_json(uuid) to authenticated, anon;

-- --------------------------------------------------------------------------- RPC updates (feeds / post / comments) to use author_mini_json
create or replace function public.list_user_feed_enriched(
  p_user_id uuid,
  p_limit int default 24,
  p_offset int default 0
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
  left join public.post_reactions r
    on r.post_id = p.id
   and r.user_id = auth.uid()
  left join public.post_saves ps_me
    on ps_me.post_id = p.id
   and ps_me.user_id = auth.uid()
  where p.user_id = p_user_id
    and p.is_archived = false
    and p.deleted_at is null
  order by p.created_at desc
  limit least(greatest(coalesce(p_limit, 24), 1), 100)
  offset greatest(coalesce(p_offset, 0), 0);
$$;

-- Hot feed RPC uses MV hot_posts_24h. Ensure it also anonymizes reset authors and hides hibernate accounts.
create or replace function public.list_hot_feed_enriched(
  p_limit int default 24,
  p_offset int default 0
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
  from public.hot_posts_24h h
  inner join public.posts p on p.id = h.post_id
  inner join public.profiles pr on pr.id = p.user_id
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
  order by h.score_24h desc, p.created_at desc
  limit least(greatest(coalesce(p_limit, 24), 1), 100)
  offset greatest(coalesce(p_offset, 0), 0);
$$;

-- Do not allow clients to query MV directly (MV bypasses RLS and can leak hidden post ids).
revoke select on public.hot_posts_24h from anon;
revoke select on public.hot_posts_24h from authenticated;
grant select on public.hot_posts_24h to service_role;
grant select on public.hot_posts_24h to postgres;

create or replace function public.list_user_feed_enriched_cursor(
  p_user_id uuid,
  p_limit int default 24,
  p_cursor_created_at timestamptz default null,
  p_cursor_id uuid default null,
  p_cluster_id uuid default null,
  p_only_without_cluster boolean default false
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
  left join public.post_reactions r
    on r.post_id = p.id
   and r.user_id = auth.uid()
  left join public.post_saves ps_me
    on ps_me.post_id = p.id
   and ps_me.user_id = auth.uid()
  where p.user_id = p_user_id
    and p.is_archived = false
    and p.deleted_at is null
    and (
      case
        when coalesce(p_only_without_cluster, false) then p.cluster_id is null
        when p_cluster_id is not null then p.cluster_id = p_cluster_id
        else true
      end
    )
    and (
      p_cursor_id is null
      or (p.created_at, p.id) < (p_cursor_created_at, p_cursor_id)
    )
  order by p.created_at desc, p.id desc
  limit least(greatest(coalesce(p_limit, 24), 1), 100);
$$;

create or replace function public.get_post_enriched(p_post_id uuid)
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
  left join public.post_reactions r
    on r.post_id = p.id
   and r.user_id = auth.uid()
  left join public.post_saves ps_me
    on ps_me.post_id = p.id
   and ps_me.user_id = auth.uid()
  where p.id = p_post_id;
$$;

create or replace function public.list_post_root_comments_enriched(
  p_post_id uuid,
  p_limit int default 24,
  p_offset int default 0
)
returns table (
  comment jsonb,
  my_kind text
)
language sql
stable
security invoker
set search_path = public
as $$
  select
    (
      to_jsonb(c.*)
      || jsonb_build_object(
        'profiles',
        jsonb_build_object(
          'username', case when pr.reset_at is not null then 'noName' else pr.username end,
          'avatar_url', case when pr.reset_at is not null then null else pr.avatar_url end
        )
      )
    ) as comment,
    r.kind as my_kind
  from public.comments c
  inner join public.profiles pr on pr.id = c.user_id
  left join public.comment_reactions r
    on r.comment_id = c.id
   and r.user_id = auth.uid()
  where c.post_id = p_post_id
    and c.parent_comment_id is null
    and c.is_deleted = false
  order by c.created_at desc
  limit greatest(0, least(coalesce(p_limit, 24), 200))
  offset greatest(0, coalesce(p_offset, 0));
$$;

create or replace function public.list_comment_replies_enriched(
  p_post_id uuid,
  p_parent_comment_id uuid,
  p_limit int default 50,
  p_offset int default 0
)
returns table (
  comment jsonb,
  my_kind text
)
language sql
stable
security invoker
set search_path = public
as $$
  select
    (
      to_jsonb(c.*)
      || jsonb_build_object(
        'profiles',
        jsonb_build_object(
          'username', case when pr.reset_at is not null then 'noName' else pr.username end,
          'avatar_url', case when pr.reset_at is not null then null else pr.avatar_url end
        )
      )
    ) as comment,
    r.kind as my_kind
  from public.comments c
  inner join public.profiles pr on pr.id = c.user_id
  left join public.comment_reactions r
    on r.comment_id = c.id
   and r.user_id = auth.uid()
  where c.post_id = p_post_id
    and c.parent_comment_id = p_parent_comment_id
    and c.is_deleted = false
  order by c.created_at asc
  limit greatest(0, least(coalesce(p_limit, 50), 200))
  offset greatest(0, coalesce(p_offset, 0));
$$;

-- --------------------------------------------------------------------------- Actions RPC (rate-limited): reset / hibernate / wake up
create or replace function public.hibernate_account()
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  uid uuid;
  last_ts timestamptz;
begin
  uid := auth.uid();
  if uid is null then
    raise exception 'not_authenticated' using errcode = 'P0003';
  end if;

  select p.last_hibernate_at into last_ts
  from public.profiles p
  where p.id = uid;

  if last_ts is not null and now() < last_ts + interval '30 days' then
    raise exception 'hibernate_rate_limited' using errcode = 'P0004';
  end if;

  update public.profiles
  set
    account_state = 'hibernate',
    content_visible = false,
    last_hibernate_at = now()
  where id = uid;
end;
$$;

create or replace function public.wake_up_if_needed()
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  uid uuid;
begin
  uid := auth.uid();
  if uid is null then
    return;
  end if;
  update public.profiles
  set
    account_state = 'active',
    content_visible = true
  where id = uid
    and account_state = 'hibernate';
end;
$$;

create or replace function public.reset_account()
returns void
language plpgsql
security definer
set search_path = public, storage
as $$
declare
  uid uuid;
  last_ts timestamptz;
  post_ids text[];
begin
  uid := auth.uid();
  if uid is null then
    raise exception 'not_authenticated' using errcode = 'P0003';
  end if;

  select p.last_reset_at into last_ts
  from public.profiles p
  where p.id = uid;

  if last_ts is not null and now() < last_ts + interval '30 days' then
    raise exception 'reset_rate_limited' using errcode = 'P0005';
  end if;

  -- Collect post ids BEFORE updating (used for Storage cleanup).
  select array_agg(p.id::text) into post_ids
  from public.posts p
  where p.user_id = uid;

  -- Soft-delete content (posts already have deleted_at).
  update public.posts
  set deleted_at = now()
  where user_id = uid
    and deleted_at is null;

  -- Soft-delete clusters.
  update public.clusters
  set
    deleted_at = now(),
    deleted_reason = 'reset'
  where owner_id = uid
    and deleted_at is null;

  -- Clear profile visuals + mark reset.
  update public.profiles
  set
    avatar_url = null,
    background_url = null,
    reset_at = now(),
    last_reset_at = now()
  where id = uid;

  -- Storage cleanup (best-effort). Buckets follow {uid}/... convention.
  delete from storage.objects so
  where so.bucket_id in ('avatars', 'profile_backgrounds', 'cluster_covers')
    and (storage.foldername(so.name))[1] = uid::text;

  -- post_media bucket convention: posts/{post_id}/{media_id}.*
  if post_ids is not null and array_length(post_ids, 1) > 0 then
    delete from storage.objects so
    where so.bucket_id = 'post_media'
      and (storage.foldername(so.name))[1] = 'posts'
      and (storage.foldername(so.name))[2] = any(post_ids);
  end if;
end;
$$;

revoke all on function public.hibernate_account() from public;
revoke all on function public.wake_up_if_needed() from public;
revoke all on function public.reset_account() from public;
grant execute on function public.hibernate_account() to authenticated;
grant execute on function public.wake_up_if_needed() to authenticated;
grant execute on function public.reset_account() to authenticated;

comment on function public.reset_account() is
  'Reset action: soft-delete posts/clusters, clear avatar/background, set reset_at, enforce 30d limit, best-effort storage cleanup. Does NOT touch followers.';
