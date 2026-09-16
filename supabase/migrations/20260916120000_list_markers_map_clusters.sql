-- list_markers_map_clusters: server-side PostGIS clustering for low zoom (LOD).
-- Client: call when zoom < 13; for zoom >= 13 use list_markers_map (this RPC returns empty).

create or replace function public.list_markers_map_clusters(
  p_lat double precision,
  p_lng double precision,
  p_radius_m double precision,
  p_zoom double precision,
  p_at_time timestamptz default now(),
  p_emoji text default null,
  p_tag_keys text[] default null,
  p_country_code text default null,
  p_city_code text default null,
  p_limit int default 200
)
returns table (
  lng double precision,
  lat double precision,
  point_count bigint,
  sample_emoji text,
  sample_marker_id uuid
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
      nullif(trim(coalesce(p_emoji, '')), '') as emoji,
      nullif(trim(coalesce(p_country_code, '')), '') as country_code,
      nullif(trim(coalesce(p_city_code, '')), '') as city_code,
      coalesce(p_zoom, 0)::double precision as zoom,
      -- ~0.02° at z10; halves each zoom step up (z11→0.01, z12→0.005)
      greatest(
        0.02 * power(2.0, 10.0 - coalesce(p_zoom, 10)::double precision),
        0.001
      )::double precision as cell_deg
  ),
  filtered as (
    select
      m.id,
      m.text_emoji,
      m.location::geometry as geom
    from public.markers m
    where
      -- High zoom: empty — client switches to list_markers_map
      (select zoom from params) < 13
      and m.is_archived = false
      and m.status <> 'cancelled'::public.marker_status
      and m.end_time > (select at_time from params)
      and st_dwithin(m.location, (select user_loc from params), (select radius_m from params))
      and (
        (select emoji from params) is null
        or m.text_emoji = (select emoji from params)
      )
      and (
        (select country_code from params) is null
        or m.country_code = (select country_code from params)
      )
      and (
        (select city_code from params) is null
        or m.city_code = (select city_code from params)
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
  ),
  snapped as (
    select
      f.id,
      f.text_emoji,
      f.geom,
      st_snaptogrid(f.geom, (select cell_deg from params)) as cell_geom
    from filtered f
  ),
  clustered as (
    select
      st_x(st_centroid(st_collect(s.geom)))::double precision as lng,
      st_y(st_centroid(st_collect(s.geom)))::double precision as lat,
      count(*)::bigint as point_count,
      (array_agg(
        s.text_emoji
        order by s.geom <-> st_centroid(s.cell_geom), s.id
      ))[1] as sample_emoji,
      (array_agg(
        s.id
        order by s.geom <-> st_centroid(s.cell_geom), s.id
      ))[1] as sample_marker_id
    from snapped s
    group by s.cell_geom
  )
  select
    c.lng,
    c.lat,
    c.point_count,
    c.sample_emoji,
    c.sample_marker_id
  from clustered c
  order by
    st_distance(
      st_setsrid(st_makepoint(c.lng, c.lat), 4326)::geography,
      (select user_loc from params)
    ) asc,
    c.point_count desc
  limit least(greatest(coalesce(p_limit, 200), 1), 500);
$$;

revoke all on function public.list_markers_map_clusters(
  double precision,
  double precision,
  double precision,
  double precision,
  timestamptz,
  text,
  text[],
  text,
  text,
  int
) from public;

grant execute on function public.list_markers_map_clusters(
  double precision,
  double precision,
  double precision,
  double precision,
  timestamptz,
  text,
  text[],
  text,
  text,
  int
) to authenticated, anon;

comment on function public.list_markers_map_clusters(
  double precision,
  double precision,
  double precision,
  double precision,
  timestamptz,
  text,
  text[],
  text,
  text,
  int
) is
  'Map LOD clusters: ST_SnapToGrid when p_zoom < 13; empty when p_zoom >= 13 (use list_markers_map). Same visibility filters as list_markers_map.';
