-- markers: country_code + city_code (как public.locations), денормализация при location_id.

alter table public.markers
  add column if not exists country_code text null,
  add column if not exists city_code text null;

do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'markers_geo_binding_pair'
  ) then
    alter table public.markers
      add constraint markers_geo_binding_pair check (
        (country_code is null and city_code is null)
        or (country_code is not null and city_code is not null)
      );
  end if;
exception
  when duplicate_object then null;
end $$;

do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'markers_country_code_fkey'
  ) then
    alter table public.markers
      add constraint markers_country_code_fkey
      foreign key (country_code)
      references public.countries (code)
      on delete restrict;
  end if;
exception
  when duplicate_object then null;
end $$;

do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'markers_city_fk'
  ) then
    alter table public.markers
      add constraint markers_city_fk
      foreign key (country_code, city_code)
      references public.cities (country_code, city_code)
      on delete restrict;
  end if;
exception
  when duplicate_object then null;
end $$;

create index if not exists markers_country_city_idx
  on public.markers (country_code, city_code)
  where country_code is not null and city_code is not null;

comment on column public.markers.country_code is
  'FK → countries.code; в паре с city_code или оба null; денормализация из locations.';

comment on column public.markers.city_code is
  'FK → cities.city_code (в паре с country_code); денормализация из locations.';

-- Backfill из привязанных locations.
update public.markers m
set
  country_code = l.country_code,
  city_code = l.city_code
from public.locations l
where m.location_id = l.id
  and l.country_code is not null
  and l.city_code is not null
  and (m.country_code is distinct from l.country_code or m.city_code is distinct from l.city_code);

-- --------------------------------------------------------------------------- Sync geo + address + country/city from locations
create or replace function public.markers_sync_location_from_location_id()
returns trigger
language plpgsql
security definer
set search_path = public
set row_security to off
as $$
declare
  v_lat double precision;
  v_lng double precision;
  v_primary text;
  v_cyrillic text;
  v_country text;
  v_city text;
begin
  if new.location_id is null then
    return new;
  end if;

  select
    l.latitude,
    l.longitude,
    l.address_primary,
    l.address_cyrillic,
    l.country_code,
    l.city_code
    into v_lat, v_lng, v_primary, v_cyrillic, v_country, v_city
  from public.locations l
  where l.id = new.location_id;

  if v_lat is not null and v_lng is not null then
    new.location := st_setsrid(st_makepoint(v_lng, v_lat), 4326)::geography;
  end if;

  if v_primary is not null and char_length(trim(v_primary)) > 0 then
    new.address_primary := trim(v_primary);
  end if;

  if v_cyrillic is not null and char_length(trim(v_cyrillic)) > 0 then
    new.address_cyrillic := trim(v_cyrillic);
  end if;

  if v_country is not null and v_city is not null then
    new.country_code := lower(trim(v_country));
    new.city_code := trim(v_city);
  else
    new.country_code := null;
    new.city_code := null;
  end if;

  return new;
end;
$$;

-- --------------------------------------------------------------------------- RPC list_markers_map
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
  address_primary text,
  address_cyrillic text,
  country_code text,
  city_code text,
  description text,
  cover_image_url text,
  event_time timestamptz,
  end_time timestamptz,
  status text,
  lat double precision,
  lng double precision,
  distance_m double precision,
  post_id uuid,
  post_count bigint,
  preview_image_urls text[]
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
    m.address_primary,
    m.address_cyrillic,
    m.country_code,
    m.city_code,
    m.description,
    m.cover_image_url,
    m.event_time,
    m.end_time,
    (
      case
        when m.status = 'cancelled'::public.marker_status then 'cancelled'
        when (select at_time from params) < m.event_time then 'upcoming'
        when (select at_time from params) <= m.end_time then 'active'
        else 'finished'
      end
    ) as status,
    st_y(m.location::geometry)::double precision as lat,
    st_x(m.location::geometry)::double precision as lng,
    st_distance(m.location, (select user_loc from params))::double precision as distance_m,
    m.post_id,
    (
      select count(*)::bigint
      from public.marker_posts mp
      where mp.marker_id = m.id
    ) as post_count,
    coalesce(
      (
        select array_agg(r.u order by r.ord)
        from (
          select
            trim(both pm_first.url)::text as u,
            row_number() over (
              order by
                mp.is_primary desc,
                mp.sort_order asc,
                mp.created_at asc,
                mp.post_id asc
            ) as ord
          from public.marker_posts mp
          join public.posts p on p.id = mp.post_id
          left join lateral (
            select pm.url
            from public.post_media pm
            where pm.post_id = p.id
            order by pm.sort_order asc nulls last
            limit 1
          ) pm_first on true
          where mp.marker_id = m.id
            and pm_first.url is not null
            and length(trim(both pm_first.url)) > 0
        ) r
        where r.ord <= 4
      ),
      '{}'::text[]
    ) as preview_image_urls
  from public.markers m
  where
    m.is_archived = false
    and m.status <> 'cancelled'::public.marker_status
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

-- --------------------------------------------------------------------------- RPC get_post_enriched (marker payload)
drop function if exists public.get_post_enriched(uuid);

create function public.get_post_enriched(p_post_id uuid)
returns table (
  post jsonb,
  author jsonb,
  my_reaction text,
  my_saved boolean,
  my_following_author boolean
)
language sql
stable
security invoker
set search_path = public
as $fn$
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
        ),
        'marker',
        case
          when m.id is not null then
            jsonb_build_object(
              'id', m.id,
              'text_emoji', m.text_emoji,
              'address_primary', m.address_primary,
              'address_cyrillic', m.address_cyrillic,
              'country_code', m.country_code,
              'city_code', m.city_code,
              'event_time', m.event_time,
              'end_time', m.end_time,
              'status', m.status::text
            )
          else 'null'::jsonb
        end
      )
    ) as post,
    public.author_mini_json(pr.id) as author,
    r.kind as my_reaction,
    (ps_me.post_id is not null) as my_saved,
    (
      auth.uid() is not null
      and auth.uid() <> p.user_id
      and exists (
        select 1
        from public.profile_follows f
        where f.follower_id = auth.uid()
          and f.following_id = p.user_id
      )
    ) as my_following_author
  from public.posts p
  inner join public.profiles pr on pr.id = p.user_id
  left join public.markers m
    on m.id = p.marker_id
  left join public.post_reactions r
    on r.post_id = p.id
   and r.user_id = auth.uid()
  left join public.post_saves ps_me
    on ps_me.post_id = p.id
   and ps_me.user_id = auth.uid()
  where p.id = p_post_id;
$fn$;

revoke all on function public.get_post_enriched(uuid) from public;
grant execute on function public.get_post_enriched(uuid) to authenticated, anon;

comment on function public.get_post_enriched(uuid) is
  'Post detail: post, author, my reaction/saved, my_following_author; marker incl. country_code/city_code.';

notify pgrst, 'reload schema';
