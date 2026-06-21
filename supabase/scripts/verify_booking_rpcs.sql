-- Smoke checks for booking RPC (run as authenticated user with booking host setup).
-- Usage: psql "$DATABASE_URL" -f supabase/scripts/verify_booking_rpcs.sql

\set ON_ERROR_STOP on

-- Schema objects exist
select 'booking_staff' as obj where exists (
  select 1 from information_schema.tables
  where table_schema = 'public' and table_name = 'booking_staff'
);

select 'bookings_exclude' as obj where exists (
  select 1 from pg_constraint
  where conname = 'bookings_staff_time_no_overlap'
);

-- RPCs exist
select p.proname
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public'
  and p.proname in (
    'create_booking',
    'get_booking_availability',
    'list_host_bookings_enriched',
    'list_my_bookings_enriched',
    'update_booking_status',
    'deactivate_booking_service',
    'get_booking_analytics',
    'booking_resolve_staff_day_window',
    'booking_host_has_booking_tag'
  )
order by p.proname;

-- Enums
select t.typname
from pg_type t
join pg_namespace n on n.oid = t.typnamespace
where n.nspname = 'public'
  and t.typname in ('booking_status', 'booking_horizon_kind', 'booking_history_action')
order by t.typname;

select 'verify_booking_rpcs ok' as status;
