-- Remove deferred currencies dictionary from sync_meta and schema.

drop table if exists public.currencies;

alter table public.sync_meta drop column if exists currencies;

create or replace function public.sync_meta_payload()
returns jsonb
language sql
stable
security definer
set search_path = public
as $$
  select jsonb_build_object(
    'countries', sm.countries,
    'cities', sm.cities,
    'tags', sm.tags
  )
  from public.sync_meta sm
  where sm.id = 1;
$$;

comment on function public.sync_meta_payload() is
  'Global dictionary version stamps as JSON for embedding in profile responses';
