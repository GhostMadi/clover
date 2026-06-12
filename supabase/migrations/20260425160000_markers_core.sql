-- Markers (map events) + tags (initial version).
-- Notes:
-- - Marker is a lightweight object for map rendering.
-- - Event lifetime is bounded: duration <= 24h, end_time = event_time + duration.
-- - Status is stored (incl. cancelled); "effective" status is computed in RPC using event_time/end_time.

-- --------------------------------------------------------------------------- Extensions
create extension if not exists postgis;

-- --------------------------------------------------------------------------- Types
do $$
begin
  create type public.marker_status as enum ('upcoming', 'active', 'finished', 'cancelled');
exception
  when duplicate_object then null;
end $$;

-- --------------------------------------------------------------------------- markers
create table if not exists public.markers (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.profiles (id) on delete cascade,

  text_emoji text null,
  address_text text null,

  event_time timestamptz not null,
  duration interval not null
    constraint markers_duration_positive check (duration > interval '0 seconds')
    constraint markers_duration_max_24h check (duration <= interval '24 hours'),
  -- NOTE: generated columns require IMMUTABLE expressions; timestamptz arithmetic
  -- is not accepted as immutable. We compute end_time via trigger.
  end_time timestamptz not null,

  status public.marker_status not null default 'upcoming',

  -- PostGIS: store as geography for meters-based distance.
  location geography(point, 4326) not null,

  created_at timestamptz not null default now()
);

-- Keep end_time in sync with (event_time + duration).
create or replace function public.markers_set_end_time()
returns trigger
language plpgsql
as $$
begin
  new.end_time := new.event_time + new.duration;
  return new;
end;
$$;

drop trigger if exists trg_markers_set_end_time on public.markers;
create trigger trg_markers_set_end_time
  before insert or update of event_time, duration on public.markers
  for each row
  execute function public.markers_set_end_time();

create index if not exists markers_owner_id_idx on public.markers (owner_id);
create index if not exists markers_event_time_idx on public.markers (event_time);
create index if not exists markers_end_time_idx on public.markers (end_time);
create index if not exists markers_location_gix on public.markers using gist (location);
create index if not exists markers_status_idx on public.markers (status);

comment on table public.markers is
  'Лёгкий маркер события для карты: owner_id, emoji/title, гео, event_time + duration (<=24h), end_time generated.';

-- --------------------------------------------------------------------------- marker_tags (dictionary)
create table if not exists public.marker_tags (
  id uuid primary key default gen_random_uuid(),
  key text not null constraint marker_tags_key_not_blank check (char_length(trim(key)) > 0),
  group_key text null,
  created_at timestamptz not null default now(),
  constraint marker_tags_key_unique unique (key)
);

comment on table public.marker_tags is
  'Справочник тегов для маркеров (key = business/online/free/...); добавлять можно без изменения кода клиента.';

-- Seed: базовый словарь тегов (можно расширять без миграций).
insert into public.marker_tags (key, group_key)
values
  -- who
  ('business', 'who'),
  ('individual', 'who'),
  ('community', 'who'),
  ('brand', 'who'),
  -- for
  ('kids', 'for'),
  ('teens', 'for'),
  ('adults', 'for'),
  ('seniors', 'for'),
  ('families', 'for'),
  ('couples', 'for'),
  ('students', 'for'),
  ('professionals', 'for'),
  ('menOnly', 'for'),
  ('womenOnly', 'for'),
  -- place
  ('restaurant', 'place'),
  ('cafe', 'place'),
  ('bar', 'place'),
  ('cinema', 'place'),
  ('club', 'place'),
  ('shop', 'place'),
  ('beauty', 'place'),
  ('fitness', 'place'),
  ('medical', 'place'),
  ('education', 'place'),
  ('coworking', 'place'),
  ('hotel', 'place'),
  ('mall', 'place'),
  -- event
  ('party', 'event'),
  ('networking', 'event'),
  ('workshop', 'event'),
  ('lecture', 'event'),
  ('festival', 'event'),
  ('concert', 'event'),
  ('exhibition', 'event'),
  ('movieNight', 'event'),
  ('gameNight', 'event'),
  ('dating', 'event'),
  ('kidsEvent', 'event'),
  ('sportEvent', 'event'),
  ('sale', 'event'),
  ('grandOpening', 'event'),
  -- format / activity
  ('indoor', 'format'),
  ('outdoor', 'format'),
  ('online', 'format'),
  ('active', 'format'),
  ('chill', 'format'),
  ('extreme', 'format'),
  ('creative', 'format'),
  ('educational', 'format'),
  ('entertainment', 'format'),
  -- conditions
  ('free', 'conditions'),
  ('paid', 'conditions'),
  ('reservation', 'conditions'),
  ('limitedSpots', 'conditions'),
  ('petFriendly', 'conditions'),
  ('eco', 'conditions'),
  ('18plus', 'conditions'),
  ('night', 'conditions'),
  ('newEvent', 'conditions'),
  ('popular', 'conditions')
on conflict (key) do update
set group_key = excluded.group_key;

-- --------------------------------------------------------------------------- marker_tag_links (m2m)
create table if not exists public.marker_tag_links (
  marker_id uuid not null references public.markers (id) on delete cascade,
  tag_id uuid not null references public.marker_tags (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (marker_id, tag_id)
);

create index if not exists marker_tag_links_tag_id_idx on public.marker_tag_links (tag_id);
create index if not exists marker_tag_links_marker_id_idx on public.marker_tag_links (marker_id);

-- --------------------------------------------------------------------------- Bind markers to existing posts
alter table public.posts
  add column if not exists marker_id uuid null references public.markers (id) on delete set null;

create index if not exists posts_marker_id_idx
  on public.posts (marker_id)
  where marker_id is not null and deleted_at is null;

comment on column public.posts.marker_id is
  'Опциональная связь поста с маркером события (для тяжёлого контента, подгружается по marker_id).';

-- --------------------------------------------------------------------------- RLS
alter table public.markers enable row level security;
alter table public.marker_tags enable row level security;
alter table public.marker_tag_links enable row level security;

-- markers: select only visible (active/upcoming) based on now/end_time, and not cancelled
drop policy if exists markers_select_visible on public.markers;
create policy markers_select_visible
  on public.markers
  for select
  to anon, authenticated
  using (status <> 'cancelled' and end_time > now());

drop policy if exists markers_insert_own on public.markers;
create policy markers_insert_own
  on public.markers
  for insert
  to authenticated
  with check (owner_id = auth.uid());

drop policy if exists markers_update_own on public.markers;
create policy markers_update_own
  on public.markers
  for update
  to authenticated
  using (owner_id = auth.uid())
  with check (owner_id = auth.uid());

drop policy if exists markers_delete_own on public.markers;
create policy markers_delete_own
  on public.markers
  for delete
  to authenticated
  using (owner_id = auth.uid());

-- marker_tags: public read; write only by service_role (table grants below).
drop policy if exists marker_tags_select_all on public.marker_tags;
create policy marker_tags_select_all
  on public.marker_tags
  for select
  to anon, authenticated
  using (true);

-- marker_tag_links: readable if marker is visible; writable only by marker owner.
drop policy if exists marker_tag_links_select_visible_marker on public.marker_tag_links;
create policy marker_tag_links_select_visible_marker
  on public.marker_tag_links
  for select
  to anon, authenticated
  using (
    exists (
      select 1
      from public.markers m
      where m.id = marker_tag_links.marker_id
        and m.status <> 'cancelled'
        and m.end_time > now()
    )
  );

drop policy if exists marker_tag_links_write_marker_owner on public.marker_tag_links;
create policy marker_tag_links_write_marker_owner
  on public.marker_tag_links
  for all
  to authenticated
  using (
    exists (
      select 1
      from public.markers m
      where m.id = marker_tag_links.marker_id
        and m.owner_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1
      from public.markers m
      where m.id = marker_tag_links.marker_id
        and m.owner_id = auth.uid()
    )
  );

-- --------------------------------------------------------------------------- RPC: list markers for map (distance + effective status + filters)
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
  address_text text,
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
    -- Visible on map: only upcoming/active.
    m.status <> 'cancelled'
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
  'Map markers: within radius (PostGIS), visible (end_time > at_time, not cancelled), optional emoji + tag_keys filters, sort by distance then event_time.';

-- --------------------------------------------------------------------------- Grants
grant select on public.markers to anon;
grant select, insert, update, delete on public.markers to authenticated;

grant select on public.marker_tags to anon;
grant select on public.marker_tags to authenticated;
revoke insert, update, delete on public.marker_tags from authenticated, anon;

grant select, insert, delete on public.marker_tag_links to authenticated;
grant select on public.marker_tag_links to anon;
