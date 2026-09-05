-- OTP resend cooldown per email (register / reset / settings).
-- Claim is atomic: 0 = allowed and timestamp updated; >0 = seconds left.

create table if not exists public.auth_email_otp_cooldown (
  email text primary key,
  last_sent_at timestamptz not null default now()
);

comment on table public.auth_email_otp_cooldown is
  'Last successful OTP send claim per email. Used to enforce client+server resend cooldown.';

alter table public.auth_email_otp_cooldown enable row level security;

-- No direct table access from clients; only via security definer RPCs.
revoke all on table public.auth_email_otp_cooldown from public, anon, authenticated;

create or replace function public.auth_email_otp_retry_after(
  p_email text,
  p_cooldown_seconds integer default 400
)
returns integer
language plpgsql
security definer
set search_path = public
set row_security to off
as $$
declare
  normalized text;
  last_at timestamptz;
  elapsed numeric;
  wait_s integer;
  cool integer;
begin
  normalized := lower(trim(coalesce(p_email, '')));
  if normalized = '' or position('@' in normalized) = 0 then
    return 0;
  end if;

  cool := greatest(coalesce(p_cooldown_seconds, 400), 1);

  select c.last_sent_at into last_at
  from public.auth_email_otp_cooldown c
  where c.email = normalized;

  if last_at is null then
    return 0;
  end if;

  elapsed := extract(epoch from (now() - last_at));
  wait_s := ceil(cool - elapsed)::integer;
  if wait_s < 0 then
    return 0;
  end if;
  return wait_s;
end;
$$;

comment on function public.auth_email_otp_retry_after(text, integer) is
  'Seconds until email may receive another OTP; 0 if allowed. Does not claim.';

create or replace function public.auth_claim_email_otp_send(
  p_email text,
  p_cooldown_seconds integer default 400
)
returns integer
language plpgsql
security definer
set search_path = public
set row_security to off
as $$
declare
  normalized text;
  last_at timestamptz;
  elapsed numeric;
  wait_s integer;
  cool integer;
begin
  normalized := lower(trim(coalesce(p_email, '')));
  if normalized = '' or position('@' in normalized) = 0 then
    return 0;
  end if;

  cool := greatest(coalesce(p_cooldown_seconds, 400), 1);

  select c.last_sent_at into last_at
  from public.auth_email_otp_cooldown c
  where c.email = normalized
  for update;

  if last_at is not null then
    elapsed := extract(epoch from (now() - last_at));
    wait_s := ceil(cool - elapsed)::integer;
    if wait_s > 0 then
      return wait_s;
    end if;
  end if;

  insert into public.auth_email_otp_cooldown as t (email, last_sent_at)
  values (normalized, now())
  on conflict (email) do update
    set last_sent_at = excluded.last_sent_at;

  return 0;
end;
$$;

comment on function public.auth_claim_email_otp_send(text, integer) is
  'Atomically claim OTP send. Returns 0 if claimed, else seconds to wait.';

revoke all on function public.auth_email_otp_retry_after(text, integer) from public;
revoke all on function public.auth_claim_email_otp_send(text, integer) from public;
grant execute on function public.auth_email_otp_retry_after(text, integer) to anon, authenticated;
grant execute on function public.auth_claim_email_otp_send(text, integer) to anon, authenticated;
