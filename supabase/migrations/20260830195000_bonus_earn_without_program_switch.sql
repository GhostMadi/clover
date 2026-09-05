-- Начисление бонусов за визит не зависит от profiles.bonus_program_status.
-- Свитч программы управляет только списанием (bonus_apply_booking_payment_spend).

create or replace function public.bonus_apply_booking_service_earn(p_booking_id uuid)
returns uuid
language plpgsql
security definer
set search_path = public
set row_security to off
as $$
declare
  v_booking public.bookings%rowtype;
  v_amount bigint;
begin
  if p_booking_id is null then
    return null;
  end if;

  select * into v_booking
  from public.bookings b
  where b.id = p_booking_id;

  if not found then
    return null;
  end if;

  if v_booking.status <> 'completed'::public.booking_status then
    return null;
  end if;

  v_amount := greatest(coalesce(v_booking.service_bonus_earn_amount, 0), 0);
  if v_amount <= 0 then
    return null;
  end if;

  return public.bonus_post_ledger_entry(
    p_client_id => v_booking.client_id,
    p_host_id => v_booking.host_id,
    p_kind => 'earn'::public.bonus_ledger_kind,
    p_amount => v_amount,
    p_title => 'Начисление за визит',
    p_subtitle => v_booking.service_title,
    p_source => 'booking_service'::public.bonus_ledger_source,
    p_source_id => v_booking.id
  );
end;
$$;

revoke all on function public.bonus_apply_booking_service_earn(uuid) from public;
grant execute on function public.bonus_apply_booking_service_earn(uuid) to service_role;

comment on function public.bonus_apply_booking_service_earn(uuid) is
  'Начисляет бонусы клиенту после completed, если service_bonus_earn_amount > 0. Не зависит от bonus_program_status.';
