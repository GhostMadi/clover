-- Markers: bind post via markers.post_id (reverse link).
-- Changes:
-- - Remove posts.marker_id
-- - Add markers.post_id references posts(id)
-- - Only show markers on map when post_id is present (active marker)
-- - Update RPC `list_markers_map` accordingly

-- --------------------------------------------------------------------------- Schema
alter table public.markers
  add column if not exists post_id uuid null references public.posts (id) on delete set null;

-- Optional: one marker per post (helps avoid duplicates)
do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'markers_post_id_unique'
  ) then
    alter table public.markers
      add constraint markers_post_id_unique unique (post_id);
  end if;
exception
  when duplicate_object then null;
end $$;

create index if not exists markers_post_id_idx
  on public.markers (post_id)
  where post_id is not null;

comment on column public.markers.post_id is
  'Опциональная связь с постом (тяжёлый контент). Маркер показываем на карте только если post_id задан.';

-- Drop reverse link on posts
do $$
begin
  if exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'posts' and column_name = 'marker_id'
  ) then
    alter table public.posts drop column marker_id;
  end if;
end $$;

-- --------------------------------------------------------------------------- RLS: map should not show markers without post
drop policy if exists markers_select_visible on public.markers;
create policy markers_select_visible
  on public.markers
  for select
  to anon, authenticated
  using (post_id is not null and status <> 'cancelled' and end_time > now());

-- --------------------------------------------------------------------------- RPC: list markers for map (now requires post_id)
create or replace function public.list_markers_map(
  p_lat double precision,
  p_lng double precision,
  p_radius_m double precision,
  p_at_time timestamptz default now(),
  p_emoji text default null,
  p_tag_keys text[] default null,
  p_limit int default 200,
  p_offset int default 0
)
returns table (
  id uuid,
  owner_id uuid,
  text_emoji text,
  title text,
  lat double precision,
  lng double precision,
  event_time timestamptz,
  end_time timestamptz,
  status text,
  distance_m double precision
)
language sql
stable
security invoker
set search_path = public
as $$
  with
  params as (
    select
      st_setsrid(st_makepoint(p_lng, p_lat), 4326)::geography as user_loc,
      greatest(coalesce(p_radius_m, 0), 0)::double precision as radius_m,
      coalesce(p_at_time, now()) as at_time,
      nullif(trim(coalesce(p_emoji, '')), '') as emoji
  )
  select
    m.id,
    m.owner_id,
    m.text_emoji,
    m.address_text,
    st_y(m.location::geometry)::double precision as lat,
    st_x(m.location::geometry)::double precision as lng,
    m.event_time,
    m.end_time,
    (
      case
        when m.status = 'cancelled' then 'cancelled'
        when (select at_time from params) < m.event_time then 'upcoming'
        when (select at_time from params) <= m.end_time then 'active'
        else 'finished'
      end
    ) as status,
    st_distance(m.location, (select user_loc from params))::double precision as distance_m
  from public.markers m
  where
    -- Active marker = has post attached.
    m.post_id is not null
    and m.status <> 'cancelled'
    and m.end_time > (select at_time from params)
    and st_dwithin(m.location, (select user_loc from params), (select radius_m from params))
    and (
      (select emoji from params) is null
      or m.text_emoji = (select emoji from params)
    )
    and (
      p_tag_keys is null
      or exists (
        select 1
        from public.marker_tag_links l
        join public.marker_tags t on t.id = l.tag_id
        where l.marker_id = m.id
          and t.key = any (p_tag_keys)
      )
    )
  order by
    st_distance(m.location, (select user_loc from params)) asc,
    m.event_time asc
  limit least(greatest(coalesce(p_limit, 200), 1), 500)
  offset greatest(coalesce(p_offset, 0), 0);
$$;

revoke all on function public.list_markers_map(double precision, double precision, double precision, timestamptz, text, text[], int, int) from public;
grant execute on function public.list_markers_map(double precision, double precision, double precision, timestamptz, text, text[], int, int) to authenticated, anon;

comment on function public.list_markers_map(double precision, double precision, double precision, timestamptz, text, text[], int, int) is
  'Map markers: within radius (PostGIS), visible (post_id not null, end_time > at_time, not cancelled), optional emoji + tag_keys filters, sort by distance then event_time.';

