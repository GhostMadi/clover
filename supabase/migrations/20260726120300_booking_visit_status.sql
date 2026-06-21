-- Booking: новые статусы визита + колонки времени.
-- Enum values must be committed before use in functions (see next migration).

alter type public.booking_status add value if not exists 'client_arrived';
alter type public.booking_status add value if not exists 'in_progress';

alter table public.bookings
  add column if not exists client_arrived_at timestamptz,
  add column if not exists service_started_at timestamptz;

comment on column public.bookings.client_arrived_at is
  'Host отметил, что клиент пришёл.';
comment on column public.bookings.service_started_at is
  'Host отметил начало оказания услуги.';
