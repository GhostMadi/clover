-- Audit tail: push_outbox title/body = EN keys (booking + attendance).
-- Drain Edge localizes for FCM. Dynamic names stay in payload.

-- --------------------------------------------------------------------------- booking
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

  -- Ignore caller locale strings; store EN keys by kind.
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
    when 'booking_rescheduled' then
      v_title := 'booking_rescheduled';
      v_body := 'new_time';
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
  'Enqueue booking push; title/body are EN keys (localized in drain_push_outbox).';

-- --------------------------------------------------------------------------- attendance
create or replace function public.attendance_notify(
  p_recipient_id uuid,
  p_actor_id uuid,
  p_kind text,
  p_dedupe_key text,
  p_title text,
  p_body text,
  p_payload jsonb default '{}'::jsonb
)
returns void
language plpgsql
security definer
set search_path = public
set row_security to off
as $$
declare
  v_kind text := coalesce(nullif(trim(p_kind), ''), 'attendance');
  v_title text;
  v_body text;
  v_payload jsonb := coalesce(p_payload, '{}'::jsonb);
  v_wp_id uuid;
  v_wp_name text;
  v_status text;
begin
  if p_recipient_id is null or p_recipient_id = p_actor_id then
    return;
  end if;

  begin
    v_wp_id := nullif(v_payload->>'workplace_id', '')::uuid;
  exception when others then
    v_wp_id := null;
  end;

  if v_wp_id is not null and nullif(trim(v_payload->>'workplace_name'), '') is null then
    select w.name into v_wp_name
    from public.attendance_workplaces w
    where w.id = v_wp_id;
    if v_wp_name is not null then
      v_payload := v_payload || jsonb_build_object('workplace_name', v_wp_name);
    end if;
  end if;

  v_status := lower(coalesce(nullif(trim(v_payload->>'status'), ''), ''));

  case v_kind
    when 'attendance_invite' then
      v_title := 'team_invite';
      v_body := 'invited_to_workplace';
    when 'attendance_rules_ack' then
      v_title := 'company_rules';
      v_body := 'accept_rules';
    when 'attendance_duty' then
      v_title := 'duty';
      v_body := 'duty_roster_updated';
    when 'attendance_correction' then
      v_title := 'punch_correction';
      v_body := case
        when v_status in ('approved', 'approve') then 'correction_approved'
        when v_status in ('rejected', 'reject') then 'correction_rejected'
        else 'correction_requested'
      end;
    else
      v_title := coalesce(nullif(trim(p_title), ''), v_kind);
      v_body := coalesce(nullif(trim(p_body), ''), v_kind);
  end case;

  perform public.upsert_notification(
    p_recipient_id,
    p_actor_id,
    p_kind,
    p_dedupe_key,
    null,
    null,
    v_payload,
    null
  );

  insert into public.push_outbox (user_id, kind, title, body, payload)
  values (
    p_recipient_id,
    v_kind,
    v_title,
    v_body,
    v_payload
  );
end;
$$;

comment on function public.attendance_notify(uuid, uuid, text, text, text, text, jsonb) is
  'In-app + push_outbox; push title/body = EN keys (localize in drain).';
