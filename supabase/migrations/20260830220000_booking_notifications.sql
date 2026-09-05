-- In-app booking notifications (instant booking model).
-- Business: docs/business/booking.md · docs/supabase/SPEC_BOOKING_NOTIFICATIONS.md

-- --------------------------------------------------------------------------- schema
alter table public.notifications
  add column if not exists booking_id uuid
    references public.bookings (id) on delete cascade;

create index if not exists notifications_booking_id_idx
  on public.notifications (booking_id)
  where booking_id is not null;

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
    'booking_visit_started',
    'booking_visit_needs_close',
    'booking_cancelled_host',
    'booking_cancelled_client',
    'booking_completed_client',
    'booking_no_show_client'
  ));

comment on column public.notifications.booking_id is
  'Booking-related in-app notification; payload holds service_title, starts_at, bonus_earn_amount.';

-- Bonus integrity: stale visits default to no_show, not completed.
alter table public.booking_schedule_settings
  alter column auto_close_target set default 'no_show'::public.booking_status;

-- --------------------------------------------------------------------------- upsert (booking_id)
create or replace function public.upsert_notification(
  p_recipient_id uuid,
  p_actor_id uuid,
  p_kind text,
  p_dedupe_key text,
  p_post_id uuid default null,
  p_comment_id uuid default null,
  p_payload jsonb default '{}'::jsonb,
  p_booking_id uuid default null
)
returns void
language plpgsql
security definer
set search_path = public
set row_security to off
as $$
begin
  if not public.notifications_should_deliver(p_recipient_id, p_actor_id) then
    return;
  end if;

  insert into public.notifications (
    recipient_id,
    actor_id,
    kind,
    dedupe_key,
    post_id,
    comment_id,
    payload,
    booking_id
  )
  values (
    p_recipient_id,
    p_actor_id,
    p_kind,
    p_dedupe_key,
    p_post_id,
    p_comment_id,
    coalesce(p_payload, '{}'::jsonb),
    p_booking_id
  )
  on conflict (dedupe_key) do update
  set
    kind = excluded.kind,
    payload = excluded.payload,
    post_id = excluded.post_id,
    comment_id = excluded.comment_id,
    booking_id = excluded.booking_id,
    created_at = now(),
    read_at = null;
end;
$$;

-- --------------------------------------------------------------------------- booking payload + helpers
create or replace function public.booking_notification_payload(p_booking public.bookings)
returns jsonb
language sql
immutable
as $$
  select jsonb_build_object(
    'service_title', p_booking.service_title,
    'service_emoji', p_booking.service_emoji,
    'starts_at', p_booking.starts_at,
    'ends_at', p_booking.ends_at,
    'bonus_earn_amount', greatest(coalesce(p_booking.service_bonus_earn_amount, 0), 0)
  );
$$;

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
  );
$$;

create or replace function public.booking_notify_created(p_booking public.bookings)
returns void
language plpgsql
security definer
set search_path = public
set row_security to off
as $$
declare
  v_payload jsonb := public.booking_notification_payload(p_booking);
begin
  perform public.upsert_notification(
    p_recipient_id := p_booking.host_id,
    p_actor_id := p_booking.client_id,
    p_kind := 'booking_created_host',
    p_dedupe_key := 'booking:' || p_booking.id::text || ':created:host',
    p_payload := v_payload,
    p_booking_id := p_booking.id
  );

  perform public.upsert_notification(
    p_recipient_id := p_booking.client_id,
    p_actor_id := p_booking.host_id,
    p_kind := 'booking_booked_client',
    p_dedupe_key := 'booking:' || p_booking.id::text || ':created:client',
    p_payload := v_payload,
    p_booking_id := p_booking.id
  );
end;
$$;

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

  if public.booking_status_is_terminal(p_booking.status) then
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

-- --------------------------------------------------------------------------- triggers on bookings
create or replace function public.booking_notifications_after_insert()
returns trigger
language plpgsql
security definer
set search_path = public
set row_security to off
as $$
begin
  perform public.booking_notify_created(new);
  return new;
end;
$$;

create or replace function public.booking_notifications_after_update()
returns trigger
language plpgsql
security definer
set search_path = public
set row_security to off
as $$
begin
  if old.status is distinct from new.status then
    perform public.booking_notify_status_change(new, old.status);
  end if;
  return new;
end;
$$;

drop trigger if exists trg_booking_notifications_insert on public.bookings;
create trigger trg_booking_notifications_insert
  after insert on public.bookings
  for each row
  execute function public.booking_notifications_after_insert();

drop trigger if exists trg_booking_notifications_status on public.bookings;
create trigger trg_booking_notifications_status
  after update of status on public.bookings
  for each row
  execute function public.booking_notifications_after_update();

-- --------------------------------------------------------------------------- cron: visit started / needs close (host)
create or replace function public.booking_notifications_scan_visits()
returns int
language plpgsql
security definer
set search_path = public
set row_security to off
as $$
declare
  v_row record;
  v_count int := 0;
  v_payload jsonb;
  v_now timestamptz := now();
begin
  for v_row in
    select b.*
    from public.bookings b
    where b.status = 'confirmed'::public.booking_status
      and b.starts_at <= v_now
      and b.ends_at > v_now
  loop
    v_payload := public.booking_notification_payload(v_row);
    perform public.upsert_notification(
      p_recipient_id := v_row.host_id,
      p_actor_id := v_row.client_id,
      p_kind := 'booking_visit_started',
      p_dedupe_key := 'booking:' || v_row.id::text || ':visit_started',
      p_payload := v_payload,
      p_booking_id := v_row.id
    );
    v_count := v_count + 1;
  end loop;

  for v_row in
    select b.*
    from public.bookings b
    where b.status in (
      'confirmed'::public.booking_status,
      'client_arrived'::public.booking_status,
      'in_progress'::public.booking_status
    )
      and b.ends_at <= v_now
  loop
    v_payload := public.booking_notification_payload(v_row);
    perform public.upsert_notification(
      p_recipient_id := v_row.host_id,
      p_actor_id := v_row.client_id,
      p_kind := 'booking_visit_needs_close',
      p_dedupe_key := 'booking:' || v_row.id::text || ':needs_close',
      p_payload := v_payload,
      p_booking_id := v_row.id
    );
    v_count := v_count + 1;
  end loop;

  return v_count;
end;
$$;

revoke all on function public.booking_notifications_scan_visits() from public;
grant execute on function public.booking_notifications_scan_visits() to service_role;

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
    'booking_notifications_scan_visits',
    '*/15 * * * *',
    $cron$select public.booking_notifications_scan_visits();$cron$
  );
exception
  when undefined_function then null;
  when undefined_table then null;
  when others then null;
end $$;

-- --------------------------------------------------------------------------- list RPC (+ booking_id)
drop function if exists public.list_notifications_enriched_cursor(int, timestamptz, uuid);

create or replace function public.list_notifications_enriched_cursor(
  p_limit int default 24,
  p_cursor_created_at timestamptz default null,
  p_cursor_id uuid default null
)
returns table (
  id uuid,
  kind text,
  actor jsonb,
  post_id uuid,
  comment_id uuid,
  booking_id uuid,
  payload jsonb,
  created_at timestamptz,
  read_at timestamptz,
  post_preview_url text,
  is_following_actor boolean
)
language sql
stable
security invoker
set search_path = public
as $$
  select
    n.id,
    n.kind,
    public.author_mini_json(n.actor_id) as actor,
    n.post_id,
    n.comment_id,
    n.booking_id,
    n.payload,
    n.created_at,
    n.read_at,
    (
      select pm.url
      from public.post_media pm
      where pm.post_id = n.post_id
      order by pm.sort_order asc
      limit 1
    ) as post_preview_url,
    case
      when n.kind = 'user_follow' then public.is_following_user(n.actor_id)
      else false
    end as is_following_actor
  from public.notifications n
  where n.recipient_id = auth.uid()
    and n.created_at >= (now() - interval '30 days')
    and (
      p_cursor_id is null
      or (n.created_at, n.id) < (p_cursor_created_at, p_cursor_id)
    )
  order by n.created_at desc, n.id desc
  limit least(greatest(coalesce(p_limit, 24), 1), 100);
$$;

revoke all on function public.list_notifications_enriched_cursor(int, timestamptz, uuid) from public;
grant execute on function public.list_notifications_enriched_cursor(int, timestamptz, uuid) to authenticated;

comment on function public.list_notifications_enriched_cursor(int, timestamptz, uuid) is
  'In-app notifications (30d): social, follow, booking; actor + optional post preview / booking_id.';

notify pgrst, 'reload schema';
