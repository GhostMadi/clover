-- Push outbox drain helpers for FCM Edge worker (service_role only).
-- Spec: docs/supabase/SPEC_PUSH_FCM.md

create or replace function public.push_outbox_claim_batch(p_limit int default 40)
returns setof public.push_outbox
language plpgsql
security definer
set search_path = public
set row_security to off
as $$
declare
  lim int := least(greatest(coalesce(p_limit, 40), 1), 100);
begin
  return query
  with picked as (
    select o.id
    from public.push_outbox o
    where o.sent_at is null
      and o.attempts < 8
    order by o.created_at asc
    for update skip locked
    limit lim
  ),
  bumped as (
    update public.push_outbox o
    set attempts = o.attempts + 1
    from picked p
    where o.id = p.id
    returning o.*
  )
  select * from bumped;
end;
$$;

revoke all on function public.push_outbox_claim_batch(int) from public;
grant execute on function public.push_outbox_claim_batch(int) to service_role;

create or replace function public.push_outbox_mark_sent(p_id uuid)
returns void
language plpgsql
security definer
set search_path = public
set row_security to off
as $$
begin
  update public.push_outbox
  set sent_at = now(),
      last_error = null
  where id = p_id;
end;
$$;

revoke all on function public.push_outbox_mark_sent(uuid) from public;
grant execute on function public.push_outbox_mark_sent(uuid) to service_role;

create or replace function public.push_outbox_mark_failed(p_id uuid, p_error text)
returns void
language plpgsql
security definer
set search_path = public
set row_security to off
as $$
begin
  update public.push_outbox
  set last_error = left(coalesce(nullif(trim(p_error), ''), 'unknown'), 2000)
  where id = p_id
    and sent_at is null;
end;
$$;

revoke all on function public.push_outbox_mark_failed(uuid, text) from public;
grant execute on function public.push_outbox_mark_failed(uuid, text) to service_role;

create or replace function public.push_device_tokens_delete_token(p_token text)
returns void
language plpgsql
security definer
set search_path = public
set row_security to off
as $$
begin
  if nullif(trim(p_token), '') is null then
    return;
  end if;
  delete from public.push_device_tokens where token = trim(p_token);
end;
$$;

revoke all on function public.push_device_tokens_delete_token(text) from public;
grant execute on function public.push_device_tokens_delete_token(text) to service_role;

notify pgrst, 'reload schema';
