-- Single booking enriched row for deep links / notification tap (client or host viewer).

create or replace function public.get_booking_enriched_for_viewer(p_booking_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
set row_security to off
as $$
declare
  uid uuid;
  b public.bookings%rowtype;
begin
  uid := public.booking_assert_authenticated();

  select * into b
  from public.bookings
  where id = p_booking_id;

  if not found then
    return null;
  end if;

  if b.client_id = uid then
    return jsonb_build_object(
      'role', 'client',
      'item', jsonb_build_object(
        'id', b.id,
        'host_id', b.host_id,
        'host_display_name', coalesce((
          select p.full_name from public.profiles p where p.id = b.host_id
        ), ''),
        'host_username', (select p.username from public.profiles p where p.id = b.host_id),
        'service_title', b.service_title,
        'service_emoji', b.service_emoji,
        'duration_minutes', b.duration_minutes,
        'price', b.price,
        'executor_name', (select st.display_name from public.booking_staff st where st.id = b.staff_id),
        'starts_at', b.starts_at,
        'status', b.status,
        'notes', b.client_notes,
        'created_at', b.created_at
      )
    );
  end if;

  if b.host_id = uid then
    return jsonb_build_object(
      'role', 'host',
      'item', jsonb_build_object(
        'id', b.id,
        'client_id', b.client_id,
        'client_name', coalesce((
          select p.full_name from public.profiles p where p.id = b.client_id
        ), ''),
        'client_username', (select p.username from public.profiles p where p.id = b.client_id),
        'client_phone', (select p.phone from public.profiles p where p.id = b.client_id),
        'service_title', b.service_title,
        'service_emoji', b.service_emoji,
        'duration_minutes', b.duration_minutes,
        'price', b.price,
        'executor_name', (select st.display_name from public.booking_staff st where st.id = b.staff_id),
        'starts_at', b.starts_at,
        'status', b.status,
        'notes', b.client_notes,
        'participants_count', b.participants_count,
        'created_at', b.created_at
      )
    );
  end if;

  return null;
end;
$$;

revoke all on function public.get_booking_enriched_for_viewer(uuid) from public;
grant execute on function public.get_booking_enriched_for_viewer(uuid) to authenticated;

comment on function public.get_booking_enriched_for_viewer(uuid) is
  'Deep link / notification: one booking for current user as client or host.';

notify pgrst, 'reload schema';
