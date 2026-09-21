-- Staff assignee push + in-app on create_booking.
-- Process: docs/business/notifications.md · docs/business/booking-tz.md §9
-- Spec: docs/supabase/SPEC_IN_APP_NOTIFICATIONS.md

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
    'booking_assigned_staff',
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
    'attendance_punch_due',
    'account_login'
  ));

create or replace function public.booking_notification_payload(p_booking public.bookings)
returns jsonb
language sql
immutable
as $$
  select jsonb_build_object(
    'booking_id', p_booking.id,
    'host_id', p_booking.host_id,
    'service_title', p_booking.service_title,
    'service_emoji', p_booking.service_emoji,
    'starts_at', p_booking.starts_at,
    'ends_at', p_booking.ends_at,
    'bonus_earn_amount', greatest(coalesce(p_booking.service_bonus_earn_amount, 0), 0)
  );
$$;

comment on function public.booking_notification_payload(public.bookings) is
  'Booking notification/push payload; booking_id + host_id for open (staff calendar).';

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
    when 'booking_assigned_staff' then
      v_title := 'new_booking';
      v_body := 'assigned_to_you';
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

create or replace function public.booking_notify_created(p_booking public.bookings)
returns void
language plpgsql
security definer
set search_path = public
set row_security to off
as $$
declare
  v_payload jsonb := public.booking_notification_payload(p_booking);
  v_staff_profile_id uuid;
begin
  perform public.upsert_notification(
    p_recipient_id := p_booking.host_id,
    p_actor_id := p_booking.client_id,
    p_kind := 'booking_created_host',
    p_dedupe_key := 'booking:' || p_booking.id::text || ':created:host',
    p_payload := v_payload,
    p_booking_id := p_booking.id
  );
  perform public.booking_enqueue_push(
    p_booking.host_id,
    'booking_created_host',
    'new_booking',
    'client_booked',
    v_payload
  );

  perform public.upsert_notification(
    p_recipient_id := p_booking.client_id,
    p_actor_id := p_booking.host_id,
    p_kind := 'booking_booked_client',
    p_dedupe_key := 'booking:' || p_booking.id::text || ':created:client',
    p_payload := v_payload,
    p_booking_id := p_booking.id
  );
  perform public.booking_enqueue_push(
    p_booking.client_id,
    'booking_booked_client',
    'booking_confirmed',
    'you_are_booked',
    v_payload
  );

  -- Executor with Clover account only (name-only staff → no notify).
  if p_booking.staff_id is not null then
    select s.profile_id
      into v_staff_profile_id
    from public.booking_staff s
    where s.id = p_booking.staff_id
      and s.is_active = true;

    if v_staff_profile_id is not null
       and v_staff_profile_id is distinct from p_booking.host_id
       and v_staff_profile_id is distinct from p_booking.client_id
    then
      perform public.upsert_notification(
        p_recipient_id := v_staff_profile_id,
        p_actor_id := p_booking.client_id,
        p_kind := 'booking_assigned_staff',
        p_dedupe_key := 'booking:' || p_booking.id::text || ':assigned:staff',
        p_payload := v_payload,
        p_booking_id := p_booking.id
      );
      perform public.booking_enqueue_push(
        v_staff_profile_id,
        'booking_assigned_staff',
        'new_booking',
        'assigned_to_you',
        v_payload
      );
    end if;
  end if;
end;
$$;

comment on function public.booking_notify_created(public.bookings) is
  'In-app + FCM for host, client, and linked staff (profile_id) on booking create.';
