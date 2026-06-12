-- posts: per-post event/session time (within marker lifetime)
-- Adds optional (nullable) time window for a post. Marker lifetime remains on `markers`.

alter table if exists public.posts
  add column if not exists event_time timestamptz null;

alter table if exists public.posts
  add column if not exists duration interval null;

alter table if exists public.posts
  add column if not exists end_time timestamptz null;

-- Keep end_time in sync with (event_time + duration) when both are set.
create or replace function public.posts_set_end_time()
returns trigger
language plpgsql
as $$
begin
  if new.event_time is null or new.duration is null then
    new.end_time := null;
  else
    new.end_time := new.event_time + new.duration;
  end if;
  return new;
end;
$$;

drop trigger if exists trg_posts_set_end_time on public.posts;
create trigger trg_posts_set_end_time
  before insert or update of event_time, duration on public.posts
  for each row
  execute function public.posts_set_end_time();

create index if not exists posts_event_time_idx on public.posts (event_time);
create index if not exists posts_end_time_idx on public.posts (end_time);

-- Ensure updated_at also refreshes when session time is changed.
drop trigger if exists trg_posts_set_updated_at on public.posts;
create trigger trg_posts_set_updated_at
  before update of title, description, cluster_id, is_archived, deleted_at, event_time, duration on public.posts
  for each row
  execute function public.posts_set_updated_at();

