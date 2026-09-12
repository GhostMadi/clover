-- Email OTP: max 3 sends per email per rolling hour (server gate via Send Email Hook).
-- Product: docs/business/authentication.md · SPEC_EMAIL_AUTH.md
-- Auth Send Email Hook records via auth_claim_email_otp_send (cannot bypass).

create table if not exists public.auth_email_otp_sends (
  id bigserial primary key,
  email text not null,
  sent_at timestamptz not null default now()
);

create index if not exists auth_email_otp_sends_email_sent_at_idx
  on public.auth_email_otp_sends (email, sent_at desc);

comment on table public.auth_email_otp_sends is
  'OTP email send log for hourly rate limit (max 3 / email / rolling hour).';

alter table public.auth_email_otp_sends enable row level security;
revoke all on table public.auth_email_otp_sends from public, anon, authenticated;
grant all on table public.auth_email_otp_sends to service_role;

-- Backfill last claim from legacy cooldown table if present
insert into public.auth_email_otp_sends (email, sent_at)
select c.email, c.last_sent_at
from public.auth_email_otp_cooldown c
where not exists (
  select 1 from public.auth_email_otp_sends s where s.email = c.email
);

drop function if exists public.auth_email_otp_retry_after(text, integer);
drop function if exists public.auth_claim_email_otp_send(text, integer);

create or replace function public.auth_email_otp_retry_after(
  p_email text,
  p_max_per_hour integer default 3
)
returns integer
language plpgsql
security definer
set search_path = public
set row_security to off
as $$
declare
  normalized text;
  max_n integer := greatest(coalesce(p_max_per_hour, 3), 1);
  cnt integer;
  oldest timestamptz;
  wait_s integer;
begin
  normalized := lower(trim(coalesce(p_email, '')));
  if normalized = '' or position('@' in normalized) = 0 then
    return 0;
  end if;

  select count(*)::integer, min(s.sent_at)
  into cnt, oldest
  from public.auth_email_otp_sends s
  where s.email = normalized
    and s.sent_at > now() - interval '1 hour';

  if cnt < max_n then
    return 0;
  end if;

  wait_s := ceil(extract(epoch from ((oldest + interval '1 hour') - now())))::integer;
  if wait_s < 1 then
    return 1;
  end if;
  return wait_s;
end;
$$;

create or replace function public.auth_claim_email_otp_send(
  p_email text,
  p_max_per_hour integer default 3
)
returns integer
language plpgsql
security definer
set search_path = public
set row_security to off
as $$
declare
  normalized text;
  max_n integer := greatest(coalesce(p_max_per_hour, 3), 1);
  wait_s integer;
begin
  normalized := lower(trim(coalesce(p_email, '')));
  if normalized = '' or position('@' in normalized) = 0 then
    return 0;
  end if;

  -- Serialize claims per email
  perform pg_advisory_xact_lock(hashtext('auth_email_otp:' || normalized));

  wait_s := public.auth_email_otp_retry_after(normalized, max_n);
  if wait_s > 0 then
    return wait_s;
  end if;

  insert into public.auth_email_otp_sends (email, sent_at)
  values (normalized, now());

  -- prune old rows for this email (keep window tidy)
  delete from public.auth_email_otp_sends s
  where s.email = normalized
    and s.sent_at <= now() - interval '2 hours';

  return 0;
end;
$$;

comment on function public.auth_claim_email_otp_send(text, integer) is
  'Claim OTP email send. 0 = allowed+recorded; else seconds until slot frees (max 3/hour).';

comment on function public.auth_email_otp_retry_after(text, integer) is
  'Seconds until email may receive another OTP under hourly cap; 0 if allowed.';

-- Undo last claim if Resend failed after insert (hook only).
create or replace function public.auth_release_last_email_otp_send(p_email text)
returns void
language plpgsql
security definer
set search_path = public
set row_security to off
as $$
declare
  normalized text;
  victim bigint;
begin
  normalized := lower(trim(coalesce(p_email, '')));
  if normalized = '' then
    return;
  end if;

  select s.id
  into victim
  from public.auth_email_otp_sends s
  where s.email = normalized
  order by s.sent_at desc, s.id desc
  limit 1;

  if victim is not null then
    delete from public.auth_email_otp_sends where id = victim;
  end if;
end;
$$;

comment on function public.auth_release_last_email_otp_send(text) is
  'Remove newest OTP send row for email (hook rollback after failed delivery).';

revoke all on function public.auth_email_otp_retry_after(text, integer) from public;
revoke all on function public.auth_claim_email_otp_send(text, integer) from public;
revoke all on function public.auth_release_last_email_otp_send(text) from public;
-- Drop legacy grants from 400s-era RPCs (CREATE OR REPLACE keeps ACLs).
revoke execute on function public.auth_claim_email_otp_send(text, integer) from anon, authenticated;
revoke execute on function public.auth_release_last_email_otp_send(text) from anon, authenticated;
-- Clients may peek wait time; only Auth Send Email Hook (service_role) may record/release.
grant execute on function public.auth_email_otp_retry_after(text, integer) to anon, authenticated, service_role;
grant execute on function public.auth_claim_email_otp_send(text, integer) to service_role;
grant execute on function public.auth_release_last_email_otp_send(text) to service_role;
