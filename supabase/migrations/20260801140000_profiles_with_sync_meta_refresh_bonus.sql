-- Refresh profiles_with_sync_meta after profiles.bonus_program_status was added.
-- PostgreSQL expands p.* at view creation time; CREATE OR REPLACE cannot insert columns before sync_meta.

drop view if exists public.profiles_with_sync_meta;

create view public.profiles_with_sync_meta
with (security_invoker = true)
as
select
  p.*,
  public.sync_meta_payload() as sync_meta
from public.profiles p;

comment on view public.profiles_with_sync_meta is
  'profiles + embedded global sync_meta (same for all rows)';

grant select on public.profiles_with_sync_meta to anon, authenticated;

notify pgrst, 'reload schema';
