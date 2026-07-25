-- Booking: host может откатить последнюю смену статуса (по booking_history).

create or replace function public.revert_booking_status(p_booking_id uuid)
returns text
language plpgsql
security definer
set search_path = public
set row_security to off
as $$
declare
  uid uuid;
  v_booking public.bookings%rowtype;
  v_prev public.booking_status;
begin
  uid := public.booking_assert_authenticated();

  select * into v_booking
  from public.bookings b
  where b.id = p_booking_id
  for update;

  if not found then
    raise exception 'booking_not_found' using errcode = 'P0008';
  end if;

  if v_booking.host_id <> uid then
    raise exception 'forbidden' using errcode = 'P0009';
  end if;

  if public.booking_status_is_terminal(v_booking.status) then
    raise exception 'invalid_status_transition' using errcode = 'P0011';
  end if;

  select h.old_status
  into v_prev
  from public.booking_history h
  where h.booking_id = p_booking_id
    and h.action = 'status_changed'::public.booking_history_action
    and h.new_status = v_booking.status
    and h.old_status is not null
  order by h.created_at desc
  limit 1;

  if v_prev is null or public.booking_status_is_terminal(v_prev) then
    raise exception 'nothing_to_revert' using errcode = 'P0011';
  end if;

  update public.bookings
  set status = v_prev,
      confirmed_at = case
        when v_prev = 'pending'::public.booking_status then null
        else confirmed_at
      end,
      client_arrived_at = case
        when v_prev in (
          'pending'::public.booking_status,
          'confirmed'::public.booking_status
        ) then null
        else client_arrived_at
      end,
      service_started_at = case
        when v_prev in (
          'pending'::public.booking_status,
          'confirmed'::public.booking_status,
          'client_arrived'::public.booking_status
        ) then null
        else service_started_at
      end
  where id = p_booking_id;

  insert into public.booking_history (booking_id, actor_id, action, old_status, new_status)
  values (
    p_booking_id,
    uid,
    'status_changed'::public.booking_history_action,
    v_booking.status,
    v_prev
  );

  return v_prev::text;
end;
$$;

revoke all on function public.revert_booking_status(uuid) from public;
grant execute on function public.revert_booking_status(uuid) to authenticated;

notify pgrst, 'reload schema';
