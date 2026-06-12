-- Markers: fix insert/update/delete permissions (RLS + grants).
-- Some environments may end up missing policies or grants; this migration makes them idempotently correct.

alter table public.markers enable row level security;

-- Ensure authenticated can write to markers table.
grant select, insert, update, delete on public.markers to authenticated;

-- Insert/update/delete: only owner can mutate.
drop policy if exists markers_insert_own on public.markers;
create policy markers_insert_own
  on public.markers
  for insert
  to authenticated
  with check (owner_id = auth.uid());

drop policy if exists markers_update_own on public.markers;
create policy markers_update_own
  on public.markers
  for update
  to authenticated
  using (owner_id = auth.uid())
  with check (owner_id = auth.uid());

drop policy if exists markers_delete_own on public.markers;
create policy markers_delete_own
  on public.markers
  for delete
  to authenticated
  using (owner_id = auth.uid());

