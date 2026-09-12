-- booking_points: места хозяина записи (как companies у attendance).
-- Продукт: docs/business/booking-points.md

create table if not exists public.booking_points (
  id uuid primary key default gen_random_uuid(),
  host_id uuid not null references public.profiles (id) on delete cascade,
  name text not null check (char_length(trim(name)) > 0),
  created_at timestamptz not null default now(),
  archived_at timestamptz null
);

create index if not exists booking_points_host_id_idx
  on public.booking_points (host_id)
  where archived_at is null;

alter table public.booking_points enable row level security;

create policy booking_points_select_own
  on public.booking_points for select to authenticated
  using (host_id = auth.uid());

create policy booking_points_insert_own
  on public.booking_points for insert to authenticated
  with check (host_id = auth.uid());

create policy booking_points_update_own
  on public.booking_points for update to authenticated
  using (host_id = auth.uid())
  with check (host_id = auth.uid());

create policy booking_points_delete_own
  on public.booking_points for delete to authenticated
  using (host_id = auth.uid());

alter table public.booking_services
  add column if not exists point_id uuid references public.booking_points (id) on delete set null;

create index if not exists booking_services_point_id_idx
  on public.booking_services (point_id)
  where point_id is not null;

-- Backfill: одна точка «Основная» на каждого host с услугами или тегом booking.
insert into public.booking_points (host_id, name)
select distinct s.host_id, 'Основная'
from public.booking_services s
where not exists (
  select 1 from public.booking_points p where p.host_id = s.host_id and p.archived_at is null
);

update public.booking_services s
set point_id = p.id
from public.booking_points p
where s.point_id is null
  and p.host_id = s.host_id
  and p.archived_at is null;

-- Хозяева с услугами уже получили точку выше.
-- Остальные — через booking_ensure_default_point() при первом входе на сайт.

create or replace function public.booking_ensure_default_point()
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  uid uuid := auth.uid();
  pid uuid;
begin
  if uid is null then
    raise exception 'not authenticated';
  end if;

  select id into pid
  from public.booking_points
  where host_id = uid and archived_at is null
  order by created_at asc
  limit 1;

  if pid is not null then
    return pid;
  end if;

  insert into public.booking_points (host_id, name)
  values (uid, 'Основная')
  returning id into pid;

  return pid;
end;
$$;

revoke all on function public.booking_ensure_default_point() from public;
grant execute on function public.booking_ensure_default_point() to authenticated;
