-- Business categories (reference) + 1:1 business_profiles(user_id → profiles).

-- --------------------------------------------------------------------------- enum
do $$
begin
  create type public.business_profile_status as enum ('active', 'deactive');
exception
  when duplicate_object then null;
end $$;

comment on type public.business_profile_status is 'Состояние бизнес-профиля: active / deactive.';

-- --------------------------------------------------------------------------- business_categories
create table if not exists public.business_categories (
  id serial primary key,
  slug text not null
    constraint business_categories_slug_format check (slug ~ '^[a-z][a-z0-9_]*$'),
  constraint business_categories_slug_key unique (slug)
);

comment on table public.business_categories is
  'Справочник направления бизнеса; клиент показывает лейблы по slug через l10n.';

insert into public.business_categories (slug)
values
  ('restaurant'),
  ('clothing_store'),
  ('just_business')
on conflict (slug) do nothing;

-- --------------------------------------------------------------------------- business_profiles (1:1 profiles)
create table if not exists public.business_profiles (
  user_id uuid not null primary key
    references public.profiles (id) on delete cascade,
  category_id integer not null
    references public.business_categories (id) on delete restrict,
  status public.business_profile_status not null default 'deactive'
);

comment on table public.business_profiles is
  'Расширение профиля для бизнеса: категория и статус. При вставке без category_id ставится категория just_business.';

create index if not exists business_profiles_category_id_idx
  on public.business_profiles (category_id);

-- При omit category_id: NEW.category_id = NULL до проверки NOT NULL → до INSERT-триггера задаём just_business.
create or replace function public.business_profiles_set_default_category()
returns trigger
language plpgsql
as $$
begin
  if new.category_id is null then
    select bc.id into new.category_id
    from public.business_categories bc
    where bc.slug = 'just_business'
    limit 1;

    if new.category_id is null then
      raise exception 'business_categories.seed missing slug just_business';
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists trg_business_profiles_set_default_category on public.business_profiles;
create trigger trg_business_profiles_set_default_category
  before insert on public.business_profiles
  for each row
  execute function public.business_profiles_set_default_category();

-- --------------------------------------------------------------------------- RLS
alter table public.business_categories enable row level security;
alter table public.business_profiles enable row level security;

drop policy if exists business_categories_select_public on public.business_categories;
create policy business_categories_select_public
  on public.business_categories for select to anon, authenticated
  using (true);

drop policy if exists business_profiles_select_own on public.business_profiles;
create policy business_profiles_select_own
  on public.business_profiles for select to authenticated
  using (user_id = auth.uid());

drop policy if exists business_profiles_insert_own on public.business_profiles;
create policy business_profiles_insert_own
  on public.business_profiles for insert to authenticated
  with check (user_id = auth.uid());

drop policy if exists business_profiles_update_own on public.business_profiles;
create policy business_profiles_update_own
  on public.business_profiles for update to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

drop policy if exists business_profiles_delete_own on public.business_profiles;
create policy business_profiles_delete_own
  on public.business_profiles for delete to authenticated
  using (user_id = auth.uid());

-- --------------------------------------------------------------------------- Grants
grant select on public.business_categories to anon, authenticated;

grant select, insert, update, delete on public.business_profiles to authenticated;
