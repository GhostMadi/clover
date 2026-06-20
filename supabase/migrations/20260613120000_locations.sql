-- User/business locations (settings → resources).
-- Requires public.profiles, public.countries, public.cities.

-- --------------------------------------------------------------------------- Align reference codes with Flutter catalog
alter table public.countries
  drop constraint if exists countries_code_format;

alter table public.cities
  drop constraint if exists cities_city_code_format;

update public.countries
set code = lower(code)
where code <> lower(code);

update public.cities
set country_code = lower(country_code)
where country_code <> lower(country_code);

delete from public.cities;

insert into public.countries (code, sort_order) values
  ('kz', 1),
  ('ru', 2)
on conflict (code) do update
set sort_order = excluded.sort_order;

insert into public.cities (country_code, city_code, sort_order) values
  ('kz', 'almaty', 1),
  ('kz', 'astana', 2),
  ('kz', 'shymkent', 3),
  ('ru', 'moscow', 1),
  ('ru', 'saintPetersburg', 2),
  ('ru', 'kazan', 3)
on conflict (country_code, city_code) do update
set sort_order = excluded.sort_order;

alter table public.countries
  add constraint countries_code_format check (code ~ '^[a-z]{2}$');

alter table public.cities
  add constraint cities_city_code_format check (city_code ~ '^[a-z][a-zA-Z0-9]{1,31}$');

-- --------------------------------------------------------------------------- locations
create table if not exists public.locations (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null
    references public.profiles (id) on delete cascade,

  address_primary text not null
    constraint locations_address_primary_not_blank check (char_length(trim(address_primary)) > 0),
  address_cyrillic text null,

  latitude double precision null
    constraint locations_latitude_range check (latitude is null or (latitude >= -90 and latitude <= 90)),
  longitude double precision null
    constraint locations_longitude_range check (longitude is null or (longitude >= -180 and longitude <= 180)),

  country_code text null
    references public.countries (code) on delete restrict,
  city_code text null,

  is_active boolean not null default true,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint locations_coordinates_pair check (
    (latitude is null and longitude is null)
    or (latitude is not null and longitude is not null)
  ),
  constraint locations_geo_binding_pair check (
    (country_code is null and city_code is null)
    or (country_code is not null and city_code is not null)
  ),
  constraint locations_city_fk
    foreign key (country_code, city_code)
    references public.cities (country_code, city_code)
    on delete restrict
);

create index if not exists locations_owner_id_idx
  on public.locations (owner_id);

create index if not exists locations_owner_active_idx
  on public.locations (owner_id, is_active);

create index if not exists locations_owner_created_idx
  on public.locations (owner_id, created_at desc);

comment on table public.locations is
  'Адреса пользователя/бизнеса: обязательны id (gen), address_primary, is_active (default true); страна/город и координаты опциональны, но парой.';

comment on column public.locations.address_primary is 'Основной адрес (латиница при создании на карте)';
comment on column public.locations.address_cyrillic is 'Адрес кириллицей (необязательно)';
comment on column public.locations.country_code is 'FK → countries.code; вместе с city_code или оба null';
comment on column public.locations.city_code is 'FK → cities.city_code (в паре с country_code)';

-- --------------------------------------------------------------------------- updated_at
create or replace function public.locations_set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

drop trigger if exists trg_locations_set_updated_at on public.locations;
create trigger trg_locations_set_updated_at
  before update on public.locations
  for each row
  execute function public.locations_set_updated_at();

-- --------------------------------------------------------------------------- RLS
alter table public.locations enable row level security;

drop policy if exists locations_select_owner on public.locations;
create policy locations_select_owner
  on public.locations
  for select
  to authenticated
  using (owner_id = (select auth.uid()));

drop policy if exists locations_insert_owner on public.locations;
create policy locations_insert_owner
  on public.locations
  for insert
  to authenticated
  with check (owner_id = (select auth.uid()));

drop policy if exists locations_update_owner on public.locations;
create policy locations_update_owner
  on public.locations
  for update
  to authenticated
  using (owner_id = (select auth.uid()))
  with check (owner_id = (select auth.uid()));

drop policy if exists locations_delete_owner on public.locations;
create policy locations_delete_owner
  on public.locations
  for delete
  to authenticated
  using (owner_id = (select auth.uid()));

-- --------------------------------------------------------------------------- Grants
grant select, insert, update, delete on public.locations to authenticated;
