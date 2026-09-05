-- Бонусы управляются только полями на услуге; глобальный свитч программы убираем.

create or replace function public.bonus_apply_booking_payment_spend(p_booking_id uuid)
returns uuid
language plpgsql
security definer
set search_path = public
set row_security to off
as $$
declare
  v_booking public.bookings%rowtype;
  v_wallet_id uuid;
  v_balance bigint;
  v_max_spend bigint;
  v_spend bigint;
  v_ledger_id uuid;
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

  if not coalesce(v_booking.use_bonuses, true) then
    return null;
  end if;

  if coalesce(v_booking.service_bonus_pay_percent, 0) <= 0 then
    return null;
  end if;

  v_max_spend := floor(
    v_booking.price * coalesce(v_booking.service_bonus_pay_percent, 0) / 100.0
  )::bigint;

  if v_max_spend <= 0 then
    return null;
  end if;

  v_wallet_id := public.bonus_ensure_wallet(v_booking.client_id, v_booking.host_id);

  select w.balance
  into v_balance
  from public.bonus_wallets w
  where w.id = v_wallet_id
  for update;

  v_spend := least(coalesce(v_balance, 0), v_max_spend);
  if v_spend <= 0 then
    return null;
  end if;

  v_ledger_id := public.bonus_post_ledger_entry(
    p_client_id => v_booking.client_id,
    p_host_id => v_booking.host_id,
    p_kind => 'spend'::public.bonus_ledger_kind,
    p_amount => v_spend,
    p_title => 'Оплата бонусами',
    p_subtitle => v_booking.service_title,
    p_source => 'booking_payment'::public.bonus_ledger_source,
    p_source_id => v_booking.id
  );

  if v_ledger_id is not null then
    update public.bookings
    set bonus_spent_amount = v_spend
    where id = v_booking.id
      and bonus_spent_amount is null;
  end if;

  return v_ledger_id;
end;
$$;

revoke all on function public.bonus_apply_booking_payment_spend(uuid) from public;
grant execute on function public.bonus_apply_booking_payment_spend(uuid) to service_role;

comment on function public.bonus_apply_booking_payment_spend(uuid) is
  'Списывает бонусы при completed, если use_bonuses и service_bonus_pay_percent > 0.';

comment on column public.booking_services.bonus_pay_percent is
  'Макс. доля стоимости услуги, оплачиваемая бонусами (0–100%). 0 = списание недоступно.';

drop index if exists public.profiles_bonus_program_status_active_idx;

alter table public.profiles
  drop column if exists bonus_program_status;

drop type if exists public.bonus_program_status;
