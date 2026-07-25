-- Remove hiring/relations feature: table, RPCs, profile flags.

drop function if exists public.withdraw_relation(uuid);
drop function if exists public.list_my_relations_enriched();
drop function if exists public.request_relation(uuid, text);
drop function if exists public.get_my_relation_with(uuid);
drop function if exists public.update_relation_status(uuid, text);

drop trigger if exists tr_relations_updated_at on public.relations;
drop table if exists public.relations;

alter table public.profiles
  drop column if exists open_for_memberships,
  drop column if exists hiring_enabled;

drop function if exists public.handle_updated_at();
