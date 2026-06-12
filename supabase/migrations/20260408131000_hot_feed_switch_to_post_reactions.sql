-- Switch hot_posts_24h MV from post_likes to post_reactions, then drop old post_likes.
-- Safe for remote DB where hot_posts_24h already exists.

-- --------------------------------------------------------------------------- Recreate MV to remove dependency on post_likes
-- Drop indexes first (Postgres drops them with MV, but keep explicit for clarity).
drop index if exists public.hot_posts_24h_post_id_uidx;
drop index if exists public.hot_posts_24h_score_idx;

drop materialized view if exists public.hot_posts_24h;

create materialized view public.hot_posts_24h as
with
  time_window as (
    select now() - interval '24 hours' as since_ts
  ),
  live_posts as (
    select p.id, p.created_at
    from public.posts p
    where p.deleted_at is null
      and p.is_archived = false
  ),
  likes_24h as (
    select r.post_id, count(*)::bigint as n
    from public.post_reactions r
    join time_window w on r.created_at >= w.since_ts
    where r.kind = 'like'
    group by r.post_id
  ),
  saves_24h as (
    select s.post_id, count(*)::bigint as n
    from public.post_saves s
    join time_window w on s.created_at >= w.since_ts
    group by s.post_id
  ),
  comments_24h as (
    select c.post_id, count(*)::bigint as n
    from public.comments c
    join time_window w on c.created_at >= w.since_ts
    where c.parent_comment_id is null
      and c.is_deleted = false
    group by c.post_id
  ),
  views_24h as (
    select v.post_id, count(*)::bigint as n
    from public.post_view_events v
    join time_window w on v.created_at >= w.since_ts
    group by v.post_id
  )
select
  p.id as post_id,
  (
    coalesce(l.n, 0) * 5
    + coalesce(sv.n, 0) * 4
    + coalesce(c.n, 0) * 3
    + coalesce(vw.n, 0) * 1
  )::bigint as score_24h,
  coalesce(l.n, 0)::bigint as likes_24h,
  coalesce(sv.n, 0)::bigint as saves_24h,
  coalesce(c.n, 0)::bigint as comments_24h,
  coalesce(vw.n, 0)::bigint as views_24h,
  p.created_at as post_created_at
from live_posts p
left join likes_24h l on l.post_id = p.id
left join saves_24h sv on sv.post_id = p.id
left join comments_24h c on c.post_id = p.id
left join views_24h vw on vw.post_id = p.id
where
  (
    coalesce(l.n, 0)
    + coalesce(sv.n, 0)
    + coalesce(c.n, 0)
    + coalesce(vw.n, 0)
  ) > 0
order by score_24h desc, p.created_at desc;

create unique index hot_posts_24h_post_id_uidx on public.hot_posts_24h (post_id);
create index hot_posts_24h_score_idx on public.hot_posts_24h (score_24h desc);

comment on materialized view public.hot_posts_24h is
  'Top posts for hot feed (last 24h) based on events; refreshed by cron/job. Read-only for clients.';

grant select on public.hot_posts_24h to anon;
grant select on public.hot_posts_24h to authenticated;

-- --------------------------------------------------------------------------- Drop old post_likes infra (dev stage)
do $$
begin
  execute 'drop trigger if exists trg_post_likes_count_ins on public.post_likes';
  execute 'drop trigger if exists trg_post_likes_count_del on public.post_likes';
exception when undefined_table then
  null;
end $$;

drop function if exists public.post_likes_sync_post_count();

drop policy if exists post_likes_select_visible on public.post_likes;
drop policy if exists post_likes_insert_own on public.post_likes;
drop policy if exists post_likes_delete_own on public.post_likes;

drop table if exists public.post_likes;

