-- Markers: allow owners to read their own markers even when not "visible" on map.
-- This is needed for flows that insert a draft marker (post_id is null) and still expect
-- PostgREST `INSERT ... RETURNING` / `.select()` to return the created row.

alter table public.markers enable row level security;

drop policy if exists markers_select_own on public.markers;
create policy markers_select_own
  on public.markers
  for select
  to authenticated
  using (owner_id = auth.uid());

