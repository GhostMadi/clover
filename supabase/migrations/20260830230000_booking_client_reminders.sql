-- Client in-app reminders before visit (confirmed bookings).
-- Business: docs/business/notifications.md · docs/business/booking.md

-- --------------------------------------------------------------------------- kind
alter table public.notifications
  drop constraint if exists notifications_kind_check;

alter table public.notifications
  add constraint notifications_kind_check check (kind in (
    'post_like',
    'post_dislike',
    'post_comment',
    'comment_reply',
    'comment_like',
    'comment_dislike',
    'user_follow',
    'booking_created_host',
    'booking_booked_client',
    'booking_reminder_client',
    'booking_visit_started',
    'booking_visit_needs_close',
    'booking_cancelled_host',
    'booking_cancelled_client',
    'booking_completed_client',
    'booking_no_show_client'
  ));

-- --------------------------------------------------------------------------- clear scheduled (host visit pings + client reminders)
create or replace function public.booking_notification_clear_visit_reminders(p_booking_id uuid)
returns void
language sql
security definer
set search_path = public
set row_security to off
as $$
  delete from public.notifications
  where dedupe_key in (
    'booking:' || p_booking_id::text || ':visit_started',
    'booking:' || p_booking_id::text || ':needs_close'
  )
  or dedupe_key like 'booking:' || p_booking_id::text || ':reminder:%';
$$;

comment on function public.booking_notification_clear_visit_reminders(uuid) is
  'Remove host visit pings and client pre-visit reminders for a booking.';

-- --------------------------------------------------------------------------- status change (re-use extended clear)
create or replace function public.booking_notify_status_change(
  p_booking public.bookings,
  p_old_status public.booking_status
)
returns void
language plpgsql
security definer
set search_path = public
set row_security to off
as $$
declare
  v_payload jsonb := public.booking_notification_payload(p_booking);
begin
  if p_old_status = p_booking.status then
    return;
  end if;

  if p_booking.status <> 'confirmed'::public.booking_status then
    perform public.booking_notification_clear_visit_reminders(p_booking.id);
  end if;

  if p_booking.status = 'cancelled'::public.booking_status then
    if p_booking.cancelled_by = p_booking.client_id then
      perform public.upsert_notification(
        p_recipient_id := p_booking.host_id,
        p_actor_id := p_booking.client_id,
        p_kind := 'booking_cancelled_host',
        p_dedupe_key := 'booking:' || p_booking.id::text || ':cancelled:host',
        p_payload := v_payload,
        p_booking_id := p_booking.id
      );
    elsif p_booking.cancelled_by = p_booking.host_id then
      perform public.upsert_notification(
        p_recipient_id := p_booking.client_id,
        p_actor_id := p_booking.host_id,
        p_kind := 'booking_cancelled_client',
        p_dedupe_key := 'booking:' || p_booking.id::text || ':cancelled:client',
        p_payload := v_payload,
        p_booking_id := p_booking.id
      );
    end if;
    return;
  end if;

  if p_booking.status = 'completed'::public.booking_status then
    perform public.upsert_notification(
      p_recipient_id := p_booking.client_id,
      p_actor_id := p_booking.host_id,
      p_kind := 'booking_completed_client',
      p_dedupe_key := 'booking:' || p_booking.id::text || ':completed:client',
      p_payload := v_payload,
      p_booking_id := p_booking.id
    );
    return;
  end if;

  if p_booking.status = 'no_show'::public.booking_status then
    perform public.upsert_notification(
      p_recipient_id := p_booking.client_id,
      p_actor_id := p_booking.host_id,
      p_kind := 'booking_no_show_client',
      p_dedupe_key := 'booking:' || p_booking.id::text || ':no_show:client',
      p_payload := v_payload,
      p_booking_id := p_booking.id
    );
  end if;
end;
$$;

-- --------------------------------------------------------------------------- client reminders (cron)
create or replace function public.booking_notifications_scan_client_reminders()
returns int
language plpgsql
security definer
set search_path = public
set row_security to off
as $$
declare
  v_row record;
  v_offset int;
  v_offsets int[] := array[1440, 180, 60, 30];
  v_count int := 0;
  v_now timestamptz := now();
  v_payload jsonb;
begin
  foreach v_offset in array v_offsets loop
    for v_row in
      select b.*
      from public.bookings b
      where b.status = 'confirmed'::public.booking_status
        and b.starts_at > v_now
        and b.created_at <= b.starts_at - make_interval(mins => v_offset)
        and v_now >= b.starts_at - make_interval(mins => v_offset)
    loop
      v_payload := public.booking_notification_payload(v_row)
        || jsonb_build_object('minutes_before', v_offset);

      perform public.upsert_notification(
        p_recipient_id := v_row.client_id,
        p_actor_id := v_row.host_id,
        p_kind := 'booking_reminder_client',
        p_dedupe_key := 'booking:' || v_row.id::text || ':reminder:' || v_offset::text,
        p_payload := v_payload,
        p_booking_id := v_row.id
      );
      v_count := v_count + 1;
    end loop;
  end loop;

  return v_count;
end;
$$;

revoke all on function public.booking_notifications_scan_client_reminders() from public;
grant execute on function public.booking_notifications_scan_client_reminders() to service_role;

-- wrapper for pg_cron (host visit + client reminders)
create or replace function public.booking_notifications_scan_scheduled()
returns int
language plpgsql
security definer
set search_path = public
set row_security to off
as $$
declare
  v_total int := 0;
begin
  v_total := v_total + public.booking_notifications_scan_visits();
  v_total := v_total + public.booking_notifications_scan_client_reminders();
  return v_total;
end;
$$;

revoke all on function public.booking_notifications_scan_scheduled() from public;
grant execute on function public.booking_notifications_scan_scheduled() to service_role;

do $$
begin
  perform cron.unschedule('booking_notifications_scan_visits');
exception
  when undefined_function then null;
  when undefined_table then null;
  when others then null;
end $$;

do $$
begin
  perform cron.schedule(
    'booking_notifications_scan_scheduled',
    '*/15 * * * *',
    $cron$select public.booking_notifications_scan_scheduled();$cron$
  );
exception
  when undefined_function then null;
  when undefined_table then null;
  when others then null;
end $$;

notify pgrst, 'reload schema';
