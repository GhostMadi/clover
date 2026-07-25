-- Global dictionary version metadata + currencies reference table.

-- --------------------------------------------------------------------------- sync_meta (singleton)
create table if not exists public.sync_meta (
  id int primary key default 1
    constraint sync_meta_singleton check (id = 1),
  countries text not null default 'v1',
  cities text not null default 'v1',
  tags text not null default 'v1',
  currencies text not null default 'v1',
  categories text not null default 'v1',
  updated_at timestamptz not null default now()
);

comment on table public.sync_meta is 'Global dictionary version stamps; same for all users';

insert into public.sync_meta (id, countries, cities, tags, currencies, categories)
values (1, 'v2', 'v4', '1719758400', 'v1', '2026-06-30')
on conflict (id) do nothing;

alter table public.sync_meta enable row level security;

create policy sync_meta_select_public
  on public.sync_meta for select
  to anon, authenticated
  using (true);

-- --------------------------------------------------------------------------- currencies
create table if not exists public.currencies (
  code text primary key
    constraint currencies_code_format check (code ~ '^[A-Z]{3}$'),
  symbol text not null,
  is_active boolean not null default true,
  sort_order int not null default 0
);

comment on table public.currencies is 'ISO 4217 currency codes for pricing/display';

alter table public.currencies enable row level security;

create policy currencies_select_public
  on public.currencies for select
  to anon, authenticated
  using (is_active = true);

insert into public.currencies (code, symbol, sort_order) values
  ('KZT', '₸', 10),
  ('USD', '\$', 20),
  ('RUB', '₽', 30)
on conflict (code) do nothing;

-- Bump helper for admins (example):
-- update public.sync_meta
-- set cities = 'v' || (substring(cities from '^v(\d+)$')::int + 1)::text,
--     updated_at = now()
-- where id = 1;
