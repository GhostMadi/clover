-- Booking: RPC после добавления enum values (отдельная транзакция).

-- Статусы, при которых слот занят.
create or replace function public.booking_status_blocks_slot(p_status public.booking_status)
returns boolean
language sql
immutable
as $$
  select p_status in (
    'pending'::public.booking_status,
    'confirmed'::public.booking_status,
    'client_arrived'::public.booking_status,
    'in_progress'::public.booking_status
  );
$$;

-- --------------------------------------------------------------------------- update_booking_status (visit flow)
create or replace function public.update_booking_status(
  p_booking_id uuid,
  p_status public.booking_status
)
returns void
language plpgsql
security definer
set search_path = public
set row_security to off
as $$
declare
  uid uuid;
  v_booking public.bookings%rowtype;
  v_is_host boolean;
  v_is_client boolean;
begin
  uid := public.booking_assert_authenticated();

  select * into v_booking
  from public.bookings b
  where b.id = p_booking_id
  for update;

  if not found then
    raise exception 'booking_not_found' using errcode = 'P0008';
  end if;

  v_is_host := v_booking.host_id = uid;
  v_is_client := v_booking.client_id = uid;

  if not v_is_host and not v_is_client then
    raise exception 'forbidden' using errcode = 'P0009';
  end if;

  if v_booking.status = p_status then
    return;
  end if;

  if p_status = 'confirmed'::public.booking_status then
    if not v_is_host or v_booking.status <> 'pending'::public.booking_status then
      raise exception 'invalid_status_transition' using errcode = 'P0011';
    end if;
    update public.bookings
    set status = p_status,
        confirmed_at = now()
    where id = p_booking_id;

  elsif p_status = 'client_arrived'::public.booking_status then
    if not v_is_host then
      raise exception 'forbidden' using errcode = 'P0009';
    end if;
    if v_booking.status not in (
      'pending'::public.booking_status,
      'confirmed'::public.booking_status
    ) then
      raise exception 'invalid_status_transition' using errcode = 'P0011';
    end if;
    update public.bookings
    set status = p_status,
        client_arrived_at = coalesce(client_arrived_at, now())
    where id = p_booking_id;

  elsif p_status = 'in_progress'::public.booking_status then
    if not v_is_host then
      raise exception 'forbidden' using errcode = 'P0009';
    end if;
    if v_booking.status <> 'client_arrived'::public.booking_status then
      raise exception 'invalid_status_transition' using errcode = 'P0011';
    end if;
    update public.bookings
    set status = p_status,
        service_started_at = coalesce(service_started_at, now())
    where id = p_booking_id;

  elsif p_status = 'completed'::public.booking_status then
    if not v_is_host then
      raise exception 'forbidden' using errcode = 'P0009';
    end if;
    if v_booking.status <> 'in_progress'::public.booking_status then
      raise exception 'invalid_status_transition' using errcode = 'P0011';
    end if;
    update public.bookings
    set status = p_status,
        completed_at = now()
    where id = p_booking_id;

  elsif p_status = 'cancelled'::public.booking_status then
    if v_booking.status in (
      'completed'::public.booking_status,
      'cancelled'::public.booking_status,
      'in_progress'::public.booking_status
    ) then
      raise exception 'invalid_status_transition' using errcode = 'P0011';
    end if;

    if v_is_client and not v_is_host then
      if v_booking.status not in (
        'pending'::public.booking_status,
        'confirmed'::public.booking_status
      ) then
        raise exception 'invalid_status_transition' using errcode = 'P0011';
      end if;
      if v_booking.starts_at <= now() then
        raise exception 'cancel_too_late' using errcode = 'P0011';
      end if;
    end if;

    update public.bookings
    set status = p_status,
        cancelled_at = now(),
        cancelled_by = uid
    where id = p_booking_id;

  else
    raise exception 'invalid_status_transition' using errcode = 'P0011';
  end if;

  insert into public.booking_history (booking_id, actor_id, action, old_status, new_status)
  values (
    p_booking_id,
    uid,
    'status_changed'::public.booking_history_action,
    v_booking.status,
    p_status
  );
end;
$$;
