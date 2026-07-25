-- Booking: enum values (отдельная транзакция перед использованием в функциях).

alter type public.booking_status add value if not exists 'no_show';

alter type public.booking_history_action add value if not exists 'auto_closed';

alter table public.bookings
  add column if not exists no_show_at timestamptz;

comment on column public.bookings.no_show_at is
  'Host отметил, что клиент не пришёл.';
