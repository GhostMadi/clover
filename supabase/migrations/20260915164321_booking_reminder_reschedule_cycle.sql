-- Booking notification cycle: reminder 24h+1h with FCM; booking_rescheduled in-app.
-- Process: docs/business/notifications.md § Уведомления по записи
-- Spec: docs/supabase/SPEC_IN_APP_NOTIFICATIONS.md

-- --------------------------------------------------------------------------- kind: allow booking_rescheduled
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
    'booking_no_show_client',
    'booking_rescheduled',
    'attendance_invite',
    'attendance_rules_ack',
    'attendance_duty',
    'attendance_correction',
    'account_login'
  ));

-- --------------------------------------------------------------------------- enqueue: EN keys for reminder; rescheduled owned by notify helper
create or replace function public.booking_enqueue_push(
  p_user_id uuid,
  p_kind text,
  p_title text,
  p_body text,
  p_payload jsonb
)
returns void
language plpgsql
security definer
set search_path = public
set row_security to off
as $$
declare
  v_kind text := coalesce(nullif(trim(p_kind), ''), 'booking');
  v_title text;
  v_body text;
begin
  if p_user_id is null then
    return;
  end if;

  -- History trigger / booking_notify_rescheduled owns this kind (avoid double FCM).
  if v_kind = 'booking_rescheduled' then
    return;
  end if;

  case v_kind
    when 'booking_created_host' then
      v_title := 'new_booking';
      v_body := 'client_booked';
    when 'booking_booked_client' then
      v_title := 'booking_confirmed';
      v_body := 'you_are_booked';
    when 'booking_cancelled_host' then
      v_title := 'booking_cancelled';
      v_body := 'client_cancelled';
    when 'booking_cancelled_client' then
      v_title := 'booking_cancelled';
      v_body := 'host_cancelled';
    when 'booking_completed_client' then
      v_title := 'visit_completed';
      v_body := 'marked_completed';
    when 'booking_no_show_client' then
      v_title := 'no_show';
      v_body := 'marked_no_show';
    when 'booking_reminder_client' then
      v_title := 'booking_reminder';
      v_body := 'visit_soon';
    else
      v_title := coalesce(nullif(trim(p_title), ''), v_kind);
      v_body := coalesce(nullif(trim(p_body), ''), v_kind);
  end case;

  insert into public.push_outbox (user_id, kind, title, body, payload)
  values (
    p_user_id,
    v_kind,
    v_title,
    v_body,
    coalesce(p_payload, '{}'::jsonb)
  );
exception
  when undefined_table then null;
end;
$$;

comment on function public.booking_enqueue_push(uuid, text, text, text, jsonb) is
  'Enqueue booking push; title/body EN keys. booking_rescheduled is no-op (see booking_notify_rescheduled).';

-- --------------------------------------------------------------------------- reschedule: in-app + FCM to other party; clear stale reminder/visit pings
create or replace function public.booking_notify_rescheduled(
  p_booking_id uuid,
  p_actor_id uuid
)
returns void
language plpgsql
security definer
set search_path = public
set row_security to off
as $$
declare
  v_booking public.bookings;
  v_other uuid;
  v_payload jsonb;
begin
  select * into v_booking
  from public.bookings
  where id = p_booking_id;

  if not found or p_actor_id is null then
    return;
  end if;

  perform public.booking_notification_clear_visit_reminders(p_booking_id);

  v_other := case
    when p_actor_id = v_booking.client_id then v_booking.host_id
    when p_actor_id = v_booking.host_id then v_booking.client_id
    else null
  end;

  if v_other is null or v_other = p_actor_id then
    return;
  end if;

  v_payload := public.booking_notification_payload(v_booking)
    || jsonb_build_object('for_host', v_other = v_booking.host_id);

  perform public.upsert_notification(
    p_recipient_id := v_other,
    p_actor_id := p_actor_id,
    p_kind := 'booking_rescheduled',
    p_dedupe_key := 'booking:' || p_booking_id::text || ':rescheduled',
    p_payload := v_payload,
    p_booking_id := p_booking_id
  );

  insert into public.push_outbox (user_id, kind, title, body, payload)
  values (
    v_other,
    'booking_rescheduled',
    'booking_rescheduled',
    'new_time',
    v_payload
  );
exception
  when undefined_table then
    null;
end;
$$;

comment on function public.booking_notify_rescheduled(uuid, uuid) is
  'After reschedule: clear reminder/visit keys; in-app + FCM to the other party.';

create or replace function public.booking_trg_notify_rescheduled()
returns trigger
language plpgsql
security definer
set search_path = public
set row_security to off
as $$
begin
  if new.action = 'rescheduled'::public.booking_history_action then
    perform public.booking_notify_rescheduled(new.booking_id, new.actor_id);
  end if;
  return new;
end;
$$;

drop trigger if exists trg_booking_history_rescheduled on public.booking_history;
create trigger trg_booking_history_rescheduled
  after insert on public.booking_history
  for each row
  when (new.action = 'rescheduled'::public.booking_history_action)
  execute function public.booking_trg_notify_rescheduled();

-- --------------------------------------------------------------------------- client reminders: 24h + 1h, in-app + FCM
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
  v_offsets int[] := array[1440, 60];
  v_count int := 0;
  v_now timestamptz := now();
  v_payload jsonb;
  v_dedupe text;
  v_already boolean;
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
      v_dedupe := 'booking:' || v_row.id::text || ':reminder:' || v_offset::text;
      v_already := exists (
        select 1 from public.notifications n where n.dedupe_key = v_dedupe
      );

      v_payload := public.booking_notification_payload(v_row)
        || jsonb_build_object('minutes_before', v_offset);

      perform public.upsert_notification(
        p_recipient_id := v_row.client_id,
        p_actor_id := v_row.host_id,
        p_kind := 'booking_reminder_client',
        p_dedupe_key := v_dedupe,
        p_payload := v_payload,
        p_booking_id := v_row.id
      );

      -- FCM once per window (cron may re-upsert in-app while window is open).
      if not v_already then
        perform public.booking_enqueue_push(
          v_row.client_id,
          'booking_reminder_client',
          'booking_reminder',
          'visit_soon',
          v_payload
        );
      end if;

      v_count := v_count + 1;
    end loop;
  end loop;

  return v_count;
end;
$$;

comment on function public.booking_notifications_scan_client_reminders() is
  'Client pre-visit reminders: 24h and 1h windows; in-app + FCM.';

-- Drop stale 3h / 30m pending reminder rows (noise windows retired).
delete from public.notifications
where kind = 'booking_reminder_client'
  and (
    dedupe_key like '%:reminder:180'
    or dedupe_key like '%:reminder:30'
  );

notify pgrst, 'reload schema';
