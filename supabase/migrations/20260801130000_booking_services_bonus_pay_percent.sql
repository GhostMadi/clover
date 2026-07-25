-- Bonus phase 1: per-service bonus payment cap (% of service price).

alter table public.booking_services
  add column if not exists bonus_pay_percent smallint not null default 0;

alter table public.booking_services
  drop constraint if exists booking_services_bonus_pay_percent_range;

alter table public.booking_services
  add constraint booking_services_bonus_pay_percent_range
  check (bonus_pay_percent between 0 and 100);

comment on column public.booking_services.bonus_pay_percent is
  'Макс. доля стоимости услуги, оплачиваемая бонусами (0–100%). Учитывается только при profiles.bonus_program_status = active.';
