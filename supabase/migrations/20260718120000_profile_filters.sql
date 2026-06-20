-- Profile feed filters: categories + values per owner.
-- Denormalized profiles.has_filters — true when owner has ≥1 category (gates filter button in UI).
-- Client path: RPC only (no direct DML on filter tables).

-- --------------------------------------------------------------------------- profiles.has_filters
alter table public.profiles
  add column if not exists has_filters boolean not null default false;

comment on column public.profiles.has_filters is
  'Denormalized: true when owner has at least one row in profile_filter_categories.';

-- --------------------------------------------------------------------------- profile_filter_categories
create table if not exists public.profile_filter_categories (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null
    references public.profiles (id) on delete cascade,

  name text not null
    constraint profile_filter_categories_name_not_blank check (char_length(trim(name)) > 0),
  sort_order int not null default 0,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint profile_filter_categories_name_len check (char_length(trim(name)) <= 64)
);

create index if not exists profile_filter_categories_owner_sort_idx
  on public.profile_filter_categories (owner_id, sort_order, created_at);

create unique index if not exists profile_filter_categories_owner_name_norm_uidx
  on public.profile_filter_categories (owner_id, lower(trim(name)));

comment on table public.profile_filter_categories is
  'Filter groups on a profile feed (e.g. Size, Color). Owner-managed via RPC.';

-- --------------------------------------------------------------------------- profile_filter_values
create table if not exists public.profile_filter_values (
  id uuid primary key default gen_random_uuid(),
  category_id uuid not null
    references public.profile_filter_categories (id) on delete cascade,

  label text not null
    constraint profile_filter_values_label_not_blank check (char_length(trim(label)) > 0),
  sort_order int not null default 0,

  created_at timestamptz not null default now(),

  constraint profile_filter_values_label_len check (char_length(trim(label)) <= 64)
);

create index if not exists profile_filter_values_category_sort_idx
  on public.profile_filter_values (category_id, sort_order, created_at);

create unique index if not exists profile_filter_values_category_label_norm_uidx
  on public.profile_filter_values (category_id, lower(trim(label)));

comment on table public.profile_filter_values is
  'Selectable values inside a profile filter category.';

-- --------------------------------------------------------------------------- updated_at (categories)
create or replace function public.profile_filter_categories_set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

drop trigger if exists trg_profile_filter_categories_set_updated_at on public.profile_filter_categories;
create trigger trg_profile_filter_categories_set_updated_at
  before update on public.profile_filter_categories
  for each row
  execute function public.profile_filter_categories_set_updated_at();

-- --------------------------------------------------------------------------- sync profiles.has_filters
create or replace function public.sync_profile_has_filters_from_categories()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_owner_id uuid;
begin
  if tg_op = 'DELETE' then
    v_owner_id := old.owner_id;
  else
    v_owner_id := new.owner_id;
  end if;

  update public.profiles p
  set has_filters = exists (
    select 1
    from public.profile_filter_categories c
    where c.owner_id = v_owner_id
  )
  where p.id = v_owner_id;

  return coalesce(new, old);
end;
$$;

drop trigger if exists trg_profile_filter_categories_sync_has_filters on public.profile_filter_categories;
create trigger trg_profile_filter_categories_sync_has_filters
  after insert or delete on public.profile_filter_categories
  for each row
  execute function public.sync_profile_has_filters_from_categories();

-- --------------------------------------------------------------------------- helper: normalize values array
create or replace function public.profile_filter_normalize_values(p_values text[])
returns text[]
language plpgsql
immutable
as $$
declare
  v_raw text;
  v_trimmed text;
  v_norm text;
  v_seen text[] := '{}';
  v_out text[] := '{}';
begin
  if p_values is null or coalesce(array_length(p_values, 1), 0) = 0 then
    raise exception 'filter_values_required' using errcode = 'P0007';
  end if;

  foreach v_raw in array p_values loop
    v_trimmed := trim(v_raw);
    if char_length(v_trimmed) = 0 then
      raise exception 'filter_value_blank' using errcode = 'P0007';
    end if;
    if char_length(v_trimmed) > 64 then
      raise exception 'filter_value_too_long' using errcode = 'P0007';
    end if;

    v_norm := lower(v_trimmed);
    if v_norm = any (v_seen) then
      continue;
    end if;

    v_seen := array_append(v_seen, v_norm);
    v_out := array_append(v_out, v_trimmed);
  end loop;

  if coalesce(array_length(v_out, 1), 0) = 0 then
    raise exception 'filter_values_required' using errcode = 'P0007';
  end if;

  return v_out;
end;
$$;

-- --------------------------------------------------------------------------- RPC: list categories (enriched)
create or replace function public.list_profile_filter_categories(p_profile_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
set row_security to off
as $$
declare
  uid uuid;
  v_has_filters boolean;
  result jsonb;
begin
  uid := auth.uid();
  if uid is null then
    raise exception 'not_authenticated' using errcode = 'P0003';
  end if;

  if p_profile_id is null then
    raise exception 'invalid_profile' using errcode = 'P0007';
  end if;

  select coalesce(p.has_filters, false)
  into v_has_filters
  from public.profiles p
  where p.id = p_profile_id;

  if not found then
    raise exception 'profile_not_found' using errcode = 'P0008';
  end if;

  -- Owner always can list (settings). Visitors only when profile exposes filters.
  if uid <> p_profile_id and not v_has_filters then
    return '[]'::jsonb;
  end if;

  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'id', c.id,
        'name', c.name,
        'values', coalesce(v.values, '[]'::jsonb)
      )
      order by c.sort_order, c.created_at
    ),
    '[]'::jsonb
  )
  into result
  from public.profile_filter_categories c
  left join lateral (
    select jsonb_agg(v.label order by v.sort_order, v.created_at) as values
    from public.profile_filter_values v
    where v.category_id = c.id
  ) v on true
  where c.owner_id = p_profile_id;

  return coalesce(result, '[]'::jsonb);
end;
$$;

-- --------------------------------------------------------------------------- RPC: upsert category + replace values
create or replace function public.upsert_profile_filter_category(
  p_name text,
  p_values text[],
  p_category_id uuid default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
set row_security to off
as $$
declare
  uid uuid;
  v_category_name text;
  v_label text;
  v_values text[];
  v_category_id uuid;
  v_sort_order int;
  v_i int;
begin
  uid := auth.uid();
  if uid is null then
    raise exception 'not_authenticated' using errcode = 'P0003';
  end if;

  v_category_name := trim(coalesce(p_name, ''));
  if char_length(v_category_name) = 0 then
    raise exception 'filter_name_required' using errcode = 'P0007';
  end if;
  if char_length(v_category_name) > 64 then
    raise exception 'filter_name_too_long' using errcode = 'P0007';
  end if;

  v_values := public.profile_filter_normalize_values(p_values);

  if p_category_id is null then
    select coalesce(max(c.sort_order), -1) + 1
    into v_sort_order
    from public.profile_filter_categories c
    where c.owner_id = uid;

    begin
      insert into public.profile_filter_categories (owner_id, name, sort_order)
      values (uid, v_category_name, v_sort_order)
      returning id into v_category_id;
    exception
      when unique_violation then
        raise exception 'category_name_taken' using errcode = 'P0011';
    end;
  else
    begin
      update public.profile_filter_categories c
      set name = v_category_name
      where c.id = p_category_id
        and c.owner_id = uid
      returning c.id into v_category_id;
    exception
      when unique_violation then
        raise exception 'category_name_taken' using errcode = 'P0011';
    end;

    if v_category_id is null then
      raise exception 'category_not_found' using errcode = 'P0008';
    end if;
  end if;

  delete from public.profile_filter_values v
  where v.category_id = v_category_id;

  v_i := 0;
  foreach v_label in array v_values loop
    begin
      insert into public.profile_filter_values (category_id, label, sort_order)
      values (v_category_id, v_label, v_i);
    exception
      when unique_violation then
        raise exception 'filter_value_taken' using errcode = 'P0011';
    end;
    v_i := v_i + 1;
  end loop;

  return jsonb_build_object(
    'id', v_category_id,
    'name', v_category_name,
    'values', to_jsonb(v_values)
  );
end;
$$;

-- --------------------------------------------------------------------------- RPC: delete category
create or replace function public.delete_profile_filter_category(p_category_id uuid)
returns void
language plpgsql
security definer
set search_path = public
set row_security to off
as $$
declare
  uid uuid;
  v_deleted_id uuid;
begin
  uid := auth.uid();
  if uid is null then
    raise exception 'not_authenticated' using errcode = 'P0003';
  end if;

  if p_category_id is null then
    raise exception 'invalid_category' using errcode = 'P0007';
  end if;

  delete from public.profile_filter_categories c
  where c.id = p_category_id
    and c.owner_id = uid
  returning c.id into v_deleted_id;

  if v_deleted_id is null then
    raise exception 'category_not_found' using errcode = 'P0008';
  end if;
end;
$$;

-- --------------------------------------------------------------------------- RLS + revoke direct access
alter table public.profile_filter_categories enable row level security;
alter table public.profile_filter_values enable row level security;

revoke all on public.profile_filter_categories from anon, authenticated;
revoke all on public.profile_filter_values from anon, authenticated;

-- --------------------------------------------------------------------------- Grants (RPC)
revoke all on function public.list_profile_filter_categories(uuid) from public;
revoke all on function public.upsert_profile_filter_category(text, text[], uuid) from public;
revoke all on function public.delete_profile_filter_category(uuid) from public;

grant execute on function public.list_profile_filter_categories(uuid) to authenticated;
grant execute on function public.upsert_profile_filter_category(text, text[], uuid) to authenticated;
grant execute on function public.delete_profile_filter_category(uuid) to authenticated;

comment on function public.list_profile_filter_categories(uuid) is
  'Returns [{id, name, values: [label...]}] for owner (settings) or visitors when profiles.has_filters = true.';

comment on function public.upsert_profile_filter_category(text, text[], uuid) is
  'Create (p_category_id null) or update own category; replaces all values. Updates profiles.has_filters via trigger.';

comment on function public.delete_profile_filter_category(uuid) is
  'Delete own category (cascade values). Sets profiles.has_filters false when last category removed.';
