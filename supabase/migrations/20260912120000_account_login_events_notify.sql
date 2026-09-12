-- Account login events + in-app/push notify (multi-session; no takeover).
-- Product: docs/business/authentication.md § Сессии · docs/business/notifications.md

-- --------------------------------------------------------------------------- table
create table if not exists public.account_login_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  client text not null
    check (client in ('mobile', 'web')),
  platform text not null
    check (platform in ('ios', 'android', 'web', 'unknown')),
  device_label text null,
  created_at timestamptz not null default now()
);

create index if not exists account_login_events_user_created_idx
  on public.account_login_events (user_id, created_at desc);

comment on table public.account_login_events is
  'Login audit trail; multi-session allowed. Notify via account_login kind.';

alter table public.account_login_events enable row level security;

drop policy if exists account_login_events_select_own on public.account_login_events;
create policy account_login_events_select_own
  on public.account_login_events
  for select
  to authenticated
  using (user_id = auth.uid());

revoke all on public.account_login_events from anon, authenticated;
grant select on public.account_login_events to authenticated;

-- --------------------------------------------------------------------------- notifications kind + self-actor allow
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
    'attendance_invite',
    'attendance_rules_ack',
    'attendance_duty',
    'attendance_correction',
    'account_login'
  ));

alter table public.notifications
  drop constraint if exists notifications_actor_not_recipient;

alter table public.notifications
  add constraint notifications_actor_not_recipient check (
    actor_id <> recipient_id or kind = 'account_login'
  );

-- --------------------------------------------------------------------------- report RPC
create or replace function public.report_account_login(
  p_client text,
  p_platform text,
  p_device_label text default null
)
returns uuid
language plpgsql
security definer
set search_path = public
set row_security to off
as $$
declare
  uid uuid := auth.uid();
  v_client text := lower(trim(coalesce(p_client, '')));
  v_platform text := lower(trim(coalesce(p_platform, '')));
  v_label text := nullif(trim(coalesce(p_device_label, '')), '');
  v_id uuid;
  v_notify boolean := true;
  v_payload jsonb;
begin
  if uid is null then
    raise exception 'auth required';
  end if;

  if v_client not in ('mobile', 'web') then
    raise exception 'invalid_client';
  end if;

  if v_platform not in ('ios', 'android', 'web', 'unknown') then
    v_platform := 'unknown';
  end if;

  insert into public.account_login_events (user_id, client, platform, device_label)
  values (uid, v_client, v_platform, v_label)
  returning id into v_id;

  -- Anti-spam: same fingerprint within 12h → journal only
  if exists (
    select 1
    from public.account_login_events e
    where e.user_id = uid
      and e.id <> v_id
      and e.client = v_client
      and e.platform = v_platform
      and coalesce(e.device_label, '') = coalesce(v_label, '')
      and e.created_at > now() - interval '12 hours'
  ) then
    v_notify := false;
  end if;

  if not v_notify then
    return v_id;
  end if;

  v_payload := jsonb_build_object(
    'client', v_client,
    'platform', v_platform,
    'device_label', v_label,
    'login_event_id', v_id::text
  );

  insert into public.notifications (
    recipient_id,
    actor_id,
    kind,
    dedupe_key,
    payload
  )
  values (
    uid,
    uid,
    'account_login',
    'account_login:' || v_id::text,
    v_payload
  );

  begin
    insert into public.push_outbox (user_id, kind, title, body, payload)
    values (
      uid,
      'account_login',
      'new_login',
      'login_from_device',
      v_payload
    );
  exception
    when undefined_table then null;
  end;

  return v_id;
end;
$$;

revoke all on function public.report_account_login(text, text, text) from public;
grant execute on function public.report_account_login(text, text, text) to authenticated;

comment on function public.report_account_login(text, text, text) is
  'Record login; notify owner (account_login) unless same fingerprint within 12h.';

-- --------------------------------------------------------------------------- list recent
create or replace function public.list_my_login_events(p_limit int default 20)
returns setof jsonb
language plpgsql
stable
security definer
set search_path = public
set row_security to off
as $$
declare
  uid uuid := auth.uid();
  v_limit int := greatest(1, least(coalesce(p_limit, 20), 50));
begin
  if uid is null then
    raise exception 'auth required';
  end if;

  return query
  select jsonb_build_object(
    'id', e.id,
    'client', e.client,
    'platform', e.platform,
    'device_label', e.device_label,
    'created_at', e.created_at
  )
  from public.account_login_events e
  where e.user_id = uid
  order by e.created_at desc
  limit v_limit;
end;
$$;

revoke all on function public.list_my_login_events(int) from public;
grant execute on function public.list_my_login_events(int) to authenticated;
