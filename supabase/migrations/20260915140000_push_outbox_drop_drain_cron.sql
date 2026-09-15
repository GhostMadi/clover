-- Drop backup pg_cron; delivery is trigger-only on push_outbox INSERT.
-- Spec: docs/supabase/SPEC_PUSH_FCM.md

do $$
begin
  perform cron.unschedule('push_outbox_drain_backup');
exception
  when others then null;
end $$;

