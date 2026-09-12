-- Primary vs guest login devices; confirm guest / mark revoked.
-- Product: docs/business/authentication.md § Сессии

alter table public.account_login_events
  add column if not exists role text not null default 'guest'
    check (role in ('primary', 'guest')),
  add column if not exists status text not null default 'active'
    check (status in ('active', 'confirmed', 'revoked')),
  add column if not exists session_id uuid null,
  add column if not exists fingerprint text null;

create index if not exists account_login_events_user_fp_idx
  on public.account_login_events (user_id, fingerprint, created_at desc);

-- Backfill: earliest event per user → primary
with firsts as (
  select distinct on (user_id) id
  from public.account_login_events
  order by user_id, created_at asc
)
update public.account_login_events e
set role = 'primary',
    status = 'confirmed',
    fingerprint = coalesce(
      e.fingerprint,
      e.client || '|' || e.platform || '|' || coalesce(e.device_label, '')
    )
from firsts f
where e.id = f.id;

update public.account_login_events
set fingerprint = coalesce(
  fingerprint,
  client || '|' || platform || '|' || coalesce(device_label, '')
)
where fingerprint is null;

drop function if exists public.report_account_login(text, text, text);

create or replace function public.report_account_login(
  p_client text,
  p_platform text,
  p_device_label text default null,
  p_session_id uuid default null
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
  v_fp text;
  v_id uuid;
  v_role text := 'guest';
  v_notify boolean := true;
  v_payload jsonb;
  v_has_primary boolean;
  v_known_trusted boolean := false;
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

  v_fp := v_client || '|' || v_platform || '|' || coalesce(v_label, '');

  select exists (
    select 1 from public.account_login_events e
    where e.user_id = uid and e.role = 'primary'
  ) into v_has_primary;

  if not v_has_primary then
    v_role := 'primary';
    v_notify := false;
  elsif exists (
    select 1
    from public.account_login_events e
    where e.user_id = uid
      and e.fingerprint = v_fp
      and e.role = 'primary'
      and e.status <> 'revoked'
  ) then
    v_role := 'primary';
    v_notify := false;
  elsif exists (
    select 1
    from public.account_login_events e
    where e.user_id = uid
      and e.fingerprint = v_fp
      and e.status = 'confirmed'
      and e.created_at > now() - interval '30 days'
  ) then
    v_known_trusted := true;
    v_notify := false;
  elsif exists (
    select 1
    from public.account_login_events e
    where e.user_id = uid
      and e.fingerprint = v_fp
      and e.created_at > now() - interval '12 hours'
  ) then
    v_notify := false;
  end if;

  insert into public.account_login_events (
    user_id, client, platform, device_label, role, status, session_id, fingerprint
  )
  values (
    uid,
    v_client,
    v_platform,
    v_label,
    v_role,
    case
      when v_role = 'primary' then 'confirmed'
      when v_known_trusted then 'confirmed'
      else 'active'
    end,
    p_session_id,
    v_fp
  )
  returning id into v_id;

  if not v_notify or v_role = 'primary' then
    return v_id;
  end if;

  v_payload := jsonb_build_object(
    'client', v_client,
    'platform', v_platform,
    'device_label', v_label,
    'login_event_id', v_id::text,
    'role', 'guest',
    'actions', jsonb_build_array('confirm', 'revoke_others', 'change_password')
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

revoke all on function public.report_account_login(text, text, text, uuid) from public;
grant execute on function public.report_account_login(text, text, text, uuid) to authenticated;

comment on function public.report_account_login(text, text, text, uuid) is
  'Record login; first fingerprint = primary; guest → account_login notify with actions.';

-- Confirm guest: "это я"
create or replace function public.confirm_account_login(p_event_id uuid)
returns void
language plpgsql
security definer
set search_path = public
set row_security to off
as $$
declare
  uid uuid := auth.uid();
begin
  if uid is null then
    raise exception 'auth required';
  end if;

  update public.account_login_events
  set status = 'confirmed'
  where id = p_event_id
    and user_id = uid
    and role = 'guest'
    and status <> 'revoked';

  update public.notifications
  set read_at = coalesce(read_at, now()),
      payload = coalesce(payload, '{}'::jsonb) || jsonb_build_object('resolved', 'confirmed')
  where recipient_id = uid
    and kind = 'account_login'
    and dedupe_key = 'account_login:' || p_event_id::text;
end;
$$;

revoke all on function public.confirm_account_login(uuid) from public;
grant execute on function public.confirm_account_login(uuid) to authenticated;

-- After client signOut(scope: others), mark other guest events revoked
create or replace function public.revoke_other_account_logins()
returns void
language plpgsql
security definer
set search_path = public
set row_security to off
as $$
declare
  uid uuid := auth.uid();
begin
  if uid is null then
    raise exception 'auth required';
  end if;

  update public.account_login_events
  set status = 'revoked'
  where user_id = uid
    and role = 'guest'
    and status in ('active', 'confirmed');

  update public.notifications n
  set read_at = coalesce(n.read_at, now()),
      payload = coalesce(n.payload, '{}'::jsonb) || jsonb_build_object('resolved', 'revoked_others')
  where n.recipient_id = uid
    and n.kind = 'account_login'
    and coalesce(n.payload->>'resolved', '') = '';
end;
$$;

revoke all on function public.revoke_other_account_logins() from public;
grant execute on function public.revoke_other_account_logins() to authenticated;

-- list with role/status
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
    'role', e.role,
    'status', e.status,
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
