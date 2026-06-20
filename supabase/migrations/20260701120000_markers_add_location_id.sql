-- markers: optional link to saved user location (settings → resources).
-- markers.location (PostGIS) stays for fast map queries; copied from locations when coords exist.

alter table public.markers
  add column if not exists location_id uuid null
    references public.locations (id) on delete set null;

create index if not exists markers_location_id_idx
  on public.markers (location_id)
  where location_id is not null;

comment on column public.markers.location_id is
  'Опциональная связь с сохранённым местоположением (public.locations). Гео для карты — в markers.location (денормализация).';

-- --------------------------------------------------------------------------- Ownership check (avoid RLS cycle on insert/update)
create or replace function public.markers_location_ownership_allows(p_location_id uuid)
returns boolean
language sql
security definer
set search_path = public
set row_security to off
stable
as $$
  select p_location_id is null
    or exists (
      select 1
      from public.locations l
      where l.id = p_location_id
        and l.owner_id = auth.uid()
    );
$$;

revoke all on function public.markers_location_ownership_allows(uuid) from public;
grant execute on function public.markers_location_ownership_allows(uuid) to authenticated;

drop policy if exists markers_insert_own on public.markers;
create policy markers_insert_own
  on public.markers
  for insert
  to authenticated
  with check (
    owner_id = auth.uid()
    and public.markers_location_ownership_allows(location_id)
  );

drop policy if exists markers_update_own on public.markers;
create policy markers_update_own
  on public.markers
  for update
  to authenticated
  using (owner_id = auth.uid())
  with check (
    owner_id = auth.uid()
    and public.markers_location_ownership_allows(location_id)
  );

-- --------------------------------------------------------------------------- Denormalize markers.location from locations lat/lng
create or replace function public.markers_sync_location_from_location_id()
returns trigger
language plpgsql
security definer
set search_path = public
set row_security to off
as $$
declare
  v_lat double precision;
  v_lng double precision;
begin
  if new.location_id is null then
    return new;
  end if;

  select l.latitude, l.longitude
    into v_lat, v_lng
  from public.locations l
  where l.id = new.location_id;

  if v_lat is not null and v_lng is not null then
    new.location := st_setsrid(st_makepoint(v_lng, v_lat), 4326)::geography;
  end if;

  return new;
end;
$$;

drop trigger if exists trg_markers_sync_location_from_location_id on public.markers;
create trigger trg_markers_sync_location_from_location_id
  before insert or update of location_id
  on public.markers
  for each row
  execute function public.markers_sync_location_from_location_id();

notify pgrst, 'reload schema';
