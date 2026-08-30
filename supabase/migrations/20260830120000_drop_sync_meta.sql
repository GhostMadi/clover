-- Remove global dictionary version metadata (client uses enum catalogs only).

drop view if exists public.profiles_with_sync_meta;

drop function if exists public.sync_meta_payload();

drop policy if exists sync_meta_select_public on public.sync_meta;

drop table if exists public.sync_meta;

notify pgrst, 'reload schema';
