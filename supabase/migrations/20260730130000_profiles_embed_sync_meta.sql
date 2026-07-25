-- Embed global sync_meta into profile reads (single HTTP response for client).

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
    'tags', sm.tags,
    'currencies', sm.currencies,
    'categories', sm.categories
  )
  from public.sync_meta sm
  where sm.id = 1;
$$;

comment on function public.sync_meta_payload() is
  'Global dictionary version stamps as JSON for embedding in profile responses';

grant execute on function public.sync_meta_payload() to anon, authenticated;

create or replace view public.profiles_with_sync_meta
with (security_invoker = true)
as
select
  p.*,
  public.sync_meta_payload() as sync_meta
from public.profiles p;

comment on view public.profiles_with_sync_meta is
  'profiles + embedded global sync_meta (same for all rows)';

grant select on public.profiles_with_sync_meta to anon, authenticated;
