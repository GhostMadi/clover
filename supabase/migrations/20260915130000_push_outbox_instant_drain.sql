-- Instant FCM: on push_outbox INSERT → call Edge drain (Supabase pg_net).
-- Delivery path = DB trigger only (no pg_cron backup).
-- Spec: docs/supabase/SPEC_PUSH_FCM.md
-- Secret: vault `push_worker_secret` (= Edge PUSH_WORKER_SECRET). Not stored in this file.

create extension if not exists pg_net;

create or replace function public.push_outbox_invoke_drain()
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_secret text;
  v_url text := 'https://wewrosbaxhkukbefjwzf.supabase.co/functions/v1/drain_push_outbox';
begin
  select ds.decrypted_secret
    into v_secret
  from vault.decrypted_secrets ds
  where ds.name = 'push_worker_secret'
  limit 1;

  if v_secret is null or length(trim(v_secret)) = 0 then
    return;
  end if;

  perform net.http_post(
    url := v_url,
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'x-push-worker-secret', trim(v_secret)
    ),
    body := '{"limit":40}'::jsonb,
    timeout_milliseconds := 20000
  );
exception
  when others then
    raise warning 'push_outbox_invoke_drain: %', sqlerrm;
end;
$$;

comment on function public.push_outbox_invoke_drain() is
  'HTTP POST drain_push_outbox via pg_net; secret from vault.push_worker_secret.';

create or replace function public.push_outbox_request_drain()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  perform public.push_outbox_invoke_drain();
  return null;
end;
$$;

comment on function public.push_outbox_request_drain() is
  'Trigger wrapper: AFTER INSERT on push_outbox → invoke_drain.';

revoke all on function public.push_outbox_invoke_drain() from public;
revoke all on function public.push_outbox_invoke_drain() from anon, authenticated;
revoke all on function public.push_outbox_request_drain() from public;
revoke all on function public.push_outbox_request_drain() from anon, authenticated;
grant execute on function public.push_outbox_invoke_drain() to postgres;

drop trigger if exists trg_push_outbox_request_drain on public.push_outbox;
create trigger trg_push_outbox_request_drain
  after insert on public.push_outbox
  for each statement
  execute function public.push_outbox_request_drain();
