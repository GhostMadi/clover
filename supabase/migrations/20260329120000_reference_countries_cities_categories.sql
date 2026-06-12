-- Reference data: countries, cities, profile categories.
-- Run in Supabase SQL Editor or via `supabase db push`.
-- Semantics: UI labels live in Flutter l10n; DB stores stable codes only.

-- --------------------------------------------------------------------------- countries
create table if not exists public.countries (
  code text primary key
    constraint countries_code_format check (code ~ '^[A-Z]{2}$'),
  is_active boolean not null default true,
  sort_order int not null default 0
);

comment on table public.countries is 'ISO 3166-1 alpha-2; single source for profile country_code';

-- --------------------------------------------------------------------------- cities
create table if not exists public.cities (
  country_code text not null
    references public.countries (code) on delete restrict,
  city_code text not null
    constraint cities_city_code_format check (city_code ~ '^[A-Z0-9_]{2,32}$'),
  is_active boolean not null default true,
  sort_order int not null default 0,
  primary key (country_code, city_code)
);

create index if not exists cities_country_active_idx
  on public.cities (country_code)
  where is_active = true;

comment on table public.cities is 'City codes are unique per country; pair (country_code, city_code) is the logical id';

-- --------------------------------------------------------------------------- profile categories
create table if not exists public.profile_categories (
  code text primary key
    constraint profile_categories_code_format check (code ~ '^[a-z0-9_]{2,64}$'),
  is_active boolean not null default true,
  sort_order int not null default 0
);

comment on table public.profile_categories is 'Profile interest/category slug; profile stores this code';

-- --------------------------------------------------------------------------- RLS
alter table public.countries enable row level security;
alter table public.cities enable row level security;
alter table public.profile_categories enable row level security;

-- Read: guests + logged-in users, only active rows (adjust if admins need inactive via API)
create policy countries_select_public
  on public.countries for select
  to anon, authenticated
  using (is_active = true);

create policy cities_select_public
  on public.cities for select
  to anon, authenticated
  using (is_active = true);

create policy profile_categories_select_public
  on public.profile_categories for select
  to anon, authenticated
  using (is_active = true);

-- No insert/update/delete for anon/authenticated (use service_role / dashboard)

-- --------------------------------------------------------------------------- Optional: link profiles (uncomment when columns are text codes aligned with these tables)
-- alter table public.profiles
--   add constraint profiles_country_fk
--   foreign key (country_code) references public.countries (code);
--
-- alter table public.profiles
--   add constraint profiles_city_fk
--   foreign key (country_code, city_id)
--   references public.cities (country_code, city_code);
-- Note: rename profiles.city_id -> city_code if you store city_code; adjust column names to match your schema.

-- alter table public.profiles
--   add constraint profiles_category_fk
--   foreign key (category_id) references public.profile_categories (code);
-- Note: if column is named category_id but stores slug, consider renaming to category_code.

-- --------------------------------------------------------------------------- Seeds (example — extend as needed)
insert into public.countries (code, sort_order) values
  ('KZ', 10),
  ('RU', 20)
on conflict (code) do nothing;

insert into public.cities (country_code, city_code, sort_order) values
  ('KZ', 'ALA', 10),
  ('KZ', 'AST', 20),
  ('KZ', 'SHY', 30),
  ('RU', 'MOW', 10),
  ('RU', 'SPB', 20)
on conflict (country_code, city_code) do nothing;

insert into public.profile_categories (code, sort_order) values
  ('beauty', 10),
  ('music', 20),
  ('sports', 30),
  ('food', 40),
  ('tech', 50)
on conflict (code) do nothing;
