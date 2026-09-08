-- Tag bookingCalendar + RPCs for assignee calendar ("мне дают заказы").
-- Product: docs/business/booking-tz.md

insert into public.marker_tags (key, group_key)
values ('bookingCalendar', 'account')
on conflict (key) do update
set group_key = excluded.group_key;

-- Staff can always read own linked rows (in addition to host / public catalog).
drop policy if exists booking_staff_select on public.booking_staff;
create policy booking_staff_select
  on public.booking_staff
  for select
  to authenticated
  using (
    host_id = auth.uid()
    or profile_id = auth.uid()
    or (
      is_active = true
      and public.booking_host_has_booking_tag(host_id)
    )
  );

-- Hosts where current user is linked as staff.
create or replace function public.list_my_staff_booking_hosts()
returns setof jsonb
language plpgsql
stable
security definer
set search_path = public
set row_security to off
as $$
declare
  uid uuid;
begin
  uid := public.booking_assert_authenticated();

  return query
  select jsonb_build_object(
    'host_id', st.host_id,
    'host_display_name', coalesce(hp.full_name, ''),
    'host_username', hp.username,
    'staff_id', st.id,
    'staff_display_name', st.display_name,
    'is_active', st.is_active
  )
  from public.booking_staff st
  join public.profiles hp on hp.id = st.host_id
  where st.profile_id = uid
  order by lower(coalesce(hp.full_name, hp.username, '')), st.id;
end;
$$;

revoke all on function public.list_my_staff_booking_hosts() from public;
grant execute on function public.list_my_staff_booking_hosts() to authenticated;

-- Bookings assigned to me as staff (optional filter by host).
create or replace function public.list_my_staff_bookings_enriched(
  p_from timestamptz,
  p_to timestamptz,
  p_host_id uuid default null,
  p_cursor jsonb default null,
  p_limit int default 50
)
returns setof jsonb
language plpgsql
stable
security definer
set search_path = public
set row_security to off
as $$
declare
  uid uuid;
  v_limit int;
begin
  uid := public.booking_assert_authenticated();
  v_limit := greatest(1, least(coalesce(p_limit, 50), 100));

  return query
  select jsonb_build_object(
    'id', b.id,
    'host_id', b.host_id,
    'host_display_name', coalesce(hp.full_name, ''),
    'host_username', hp.username,
    'client_id', b.client_id,
    'client_name', coalesce(cp.full_name, ''),
    'client_username', cp.username,
    'service_id', b.service_id,
    'service_title', b.service_title,
    'service_emoji', b.service_emoji,
    'duration_minutes', b.duration_minutes,
    'price', b.price,
    'staff_id', b.staff_id,
    'executor_name', st.display_name,
    'starts_at', b.starts_at,
    'status', b.status,
    'notes', b.client_notes,
    'created_at', b.created_at
  )
  from public.bookings b
  join public.booking_staff st on st.id = b.staff_id
  join public.profiles hp on hp.id = b.host_id
  join public.profiles cp on cp.id = b.client_id
  where st.profile_id = uid
    and (p_host_id is null or b.host_id = p_host_id)
    and b.starts_at >= coalesce(p_from, '-infinity'::timestamptz)
    and b.starts_at <= coalesce(p_to, 'infinity'::timestamptz)
    and (
      p_cursor is null
      or b.starts_at > coalesce((p_cursor ->> 'starts_at')::timestamptz, '-infinity'::timestamptz)
      or (
        b.starts_at = (p_cursor ->> 'starts_at')::timestamptz
        and b.id > coalesce(
          (p_cursor ->> 'id')::uuid,
          '00000000-0000-0000-0000-000000000000'::uuid
        )
      )
    )
  order by b.starts_at asc, b.id asc
  limit v_limit;
end;
$$;

revoke all on function public.list_my_staff_bookings_enriched(timestamptz, timestamptz, uuid, jsonb, int) from public;
grant execute on function public.list_my_staff_bookings_enriched(timestamptz, timestamptz, uuid, jsonb, int) to authenticated;
