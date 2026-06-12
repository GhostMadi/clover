-- Hot feed: materialized view for top posts in last 24 hours + cron refresh.
-- Depends on: posts_post_media_engagement + post_view_events (+ optional sends).

-- --------------------------------------------------------------------------- MV: hot_posts_24h
-- Score is a simple weighted sum of events in the last 24h.
-- Tune weights later without touching app code.
create materialized view if not exists public.hot_posts_24h as
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
    select l.post_id, count(*)::bigint as n
    from public.post_reactions l
    join time_window w on l.created_at >= w.since_ts
    where l.kind = 'like'
    group by l.post_id
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
  -- Weighted score: likes + saves are strongest, comments mid, views weak.
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

-- Unique index required for REFRESH MATERIALIZED VIEW CONCURRENTLY.
create unique index if not exists hot_posts_24h_post_id_uidx on public.hot_posts_24h (post_id);
create index if not exists hot_posts_24h_score_idx on public.hot_posts_24h (score_24h desc);

comment on materialized view public.hot_posts_24h is
  'Top posts for hot feed (last 24h) based on events; refreshed by cron/job. Read-only for clients.';

-- --------------------------------------------------------------------------- Refresh function (can be called by cron / Edge / service_role)
create or replace function public.refresh_hot_posts_24h()
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  -- Concurrent refresh to avoid blocking readers.
  refresh materialized view concurrently public.hot_posts_24h;
end;
$$;

revoke all on function public.refresh_hot_posts_24h() from public;
grant execute on function public.refresh_hot_posts_24h() to service_role;
grant execute on function public.refresh_hot_posts_24h() to postgres;

-- --------------------------------------------------------------------------- Cron (best-effort)
-- Supabase обычно предоставляет pg_cron. Если нет — просто вызывай функцию из Edge/worker.
do $$
begin
  create extension if not exists pg_cron;
exception
  when insufficient_privilege then
    -- ignore on environments where extension management is restricted
    null;
end $$;

-- Every 5 minutes (unschedule: job may not exist yet — catch all).
do $$
begin
  perform cron.unschedule('refresh_hot_posts_24h');
exception
  when undefined_function then null;
  when undefined_table then null;
  when others then null;
end $$;

do $$
begin
  perform cron.schedule(
    'refresh_hot_posts_24h',
    '*/5 * * * *',
    $cron$select public.refresh_hot_posts_24h();$cron$
  );
exception
  when undefined_function then null;
  when undefined_table then null;
end $$;

-- --------------------------------------------------------------------------- Grants
grant select on public.hot_posts_24h to anon;
grant select on public.hot_posts_24h to authenticated;

