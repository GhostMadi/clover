-- Remove subtitle everywhere: posts + markers preview.
-- New contract:
-- - posts: title + description (no subtitle)
-- - markers (fast preview layer): title + description (no short_description)

-- --------------------------------------------------------------------------- posts
-- Drop the old trigger first (it may reference `subtitle` in its column list).
drop trigger if exists trg_posts_set_updated_at on public.posts;

alter table public.posts
  drop column if exists subtitle;

-- Make updated_at robust to schema changes (no column list).
create trigger trg_posts_set_updated_at
  before update on public.posts
  for each row
  execute function public.posts_set_updated_at();

-- --------------------------------------------------------------------------- markers (preview layer)
alter table public.markers
  add column if not exists description text null;

-- Backfill from previous preview column if it exists.
do $$
begin
  if exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'markers'
      and column_name = 'short_description'
  ) then
    execute $q$
      update public.markers
      set description = coalesce(description, short_description)
      where description is null
        and short_description is not null
        and char_length(trim(short_description)) > 0
    $q$;
  end if;
end $$;

alter table public.markers
  drop column if exists short_description;

comment on column public.markers.description is
  'Лёгкое описание для превью на карте; держать очень коротким (≈ 100–200 символов).';

-- --------------------------------------------------------------------------- RPC: list_markers_map (fast)
drop function if exists public.list_markers_map(
  double precision,
  double precision,
  double precision,
  timestamptz,
  text,
  text[],
  int,
  int
);

create function public.list_markers_map(
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
  -- preview
  address_text text,
  description text,
  cover_image_url text,
  -- time
  event_time timestamptz,
  end_time timestamptz,
  status text,
  -- geo
  lat double precision,
  lng double precision,
  distance_m double precision,
  -- heavy link
  post_id uuid
)
language plpgsql
stable
security invoker
set search_path = public
as $$
begin
  if exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'markers'
      and column_name = 'address_text'
  ) then
    return query
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
      m.description,
      m.cover_image_url,
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
      st_y(m.location::geometry)::double precision as lat,
      st_x(m.location::geometry)::double precision as lng,
      st_distance(m.location, (select user_loc from params))::double precision as distance_m,
      m.post_id
  from public.markers m
    where
      m.post_id is not null
    and m.is_archived = false
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
  else
    return query
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
      m.title as address_text,
      m.description,
      m.cover_image_url,
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
      st_y(m.location::geometry)::double precision as lat,
      st_x(m.location::geometry)::double precision as lng,
      st_distance(m.location, (select user_loc from params))::double precision as distance_m,
      m.post_id
    from public.markers m
    where
      m.post_id is not null
      and m.is_archived = false
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
  end if;
end;
$$;

revoke all on function public.list_markers_map(double precision, double precision, double precision, timestamptz, text, text[], int, int) from public;
grant execute on function public.list_markers_map(double precision, double precision, double precision, timestamptz, text, text[], int, int) to authenticated, anon;

notify pgrst, 'reload schema';

