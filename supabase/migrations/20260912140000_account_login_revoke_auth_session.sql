-- Guest login: revoke one Auth session; kick others; notify actions confirm|revoke|change_password.
-- Product: docs/business/authentication.md § Сессии

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
    'actions', jsonb_build_array('confirm', 'revoke', 'change_password')
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
  'Record login; first fingerprint = primary; guest → notify with confirm|revoke|change_password.';

-- "Прервать" эту гостевую сессию
create or replace function public.revoke_account_login(p_event_id uuid)
returns void
language plpgsql
security definer
set search_path = public, auth
set row_security to off
as $$
declare
  uid uuid := auth.uid();
  v_session uuid;
begin
  if uid is null then
    raise exception 'auth required';
  end if;

  select e.session_id into v_session
  from public.account_login_events e
  where e.id = p_event_id
    and e.user_id = uid
    and e.role = 'guest';

  if not found then
    return;
  end if;

  update public.account_login_events
  set status = 'revoked'
  where id = p_event_id
    and user_id = uid;

  if v_session is not null then
    delete from auth.sessions
    where id = v_session
      and user_id = uid;
  end if;

  update public.notifications
  set read_at = coalesce(read_at, now()),
      payload = coalesce(payload, '{}'::jsonb) || jsonb_build_object('resolved', 'revoked')
  where recipient_id = uid
    and kind = 'account_login'
    and dedupe_key = 'account_login:' || p_event_id::text;
end;
$$;

revoke all on function public.revoke_account_login(uuid) from public;
grant execute on function public.revoke_account_login(uuid) to authenticated;

comment on function public.revoke_account_login(uuid) is
  'Revoke one guest login event and delete its auth.sessions row when known.';

-- Kick all other Auth sessions + mark guests revoked (owner acts from primary)
create or replace function public.revoke_other_account_logins()
returns void
language plpgsql
security definer
set search_path = public, auth
set row_security to off
as $$
declare
  uid uuid := auth.uid();
  v_current uuid;
begin
  if uid is null then
    raise exception 'auth required';
  end if;

  begin
    v_current := nullif(auth.jwt() ->> 'session_id', '')::uuid;
  exception
    when others then
      v_current := null;
  end;

  update public.account_login_events
  set status = 'revoked'
  where user_id = uid
    and role = 'guest'
    and status in ('active', 'confirmed');

  delete from auth.sessions s
  where s.user_id = uid
    and (v_current is null or s.id is distinct from v_current);

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

comment on function public.revoke_other_account_logins() is
  'Revoke all guest login events and delete other auth.sessions (keep caller JWT session).';
