-- Auth helpers: check email before OTP; resolve username → email for password login.
-- Register must NOT send OTP to already-registered emails (product rule).

set search_path = public;

create or replace function public.auth_is_email_registered(p_email text)
returns boolean
language plpgsql
security definer
set search_path = auth, public
set row_security to off
as $$
declare
  normalized text;
begin
  normalized := lower(trim(coalesce(p_email, '')));
  if normalized = '' or position('@' in normalized) = 0 then
    return false;
  end if;

  return exists (
    select 1
    from auth.users u
    where lower(u.email) = normalized
      and u.deleted_at is null
  );
end;
$$;

comment on function public.auth_is_email_registered(text) is
  'True if auth.users already has this email. Used to block register OTP for existing accounts.';

revoke all on function public.auth_is_email_registered(text) from public;
grant execute on function public.auth_is_email_registered(text) to anon, authenticated;

create or replace function public.auth_resolve_login_email(p_identifier text)
returns text
language plpgsql
security definer
set search_path = auth, public
set row_security to off
as $$
declare
  raw text;
  normalized text;
  found_email text;
begin
  raw := trim(coalesce(p_identifier, ''));
  if raw = '' then
    return null;
  end if;

  -- Email as-is
  if position('@' in raw) > 0 then
    return lower(raw);
  end if;

  -- Username → profiles.email (strip leading @)
  normalized := lower(raw);
  if left(normalized, 1) = '@' then
    normalized := substring(normalized from 2);
  end if;
  if normalized = '' then
    return null;
  end if;

  select lower(trim(pr.email))
  into found_email
  from public.profiles pr
  where lower(trim(pr.username)) = normalized
    and pr.email is not null
    and trim(pr.email) <> ''
  limit 1;

  return found_email;
end;
$$;

comment on function public.auth_resolve_login_email(text) is
  'Maps login identifier (email or username) to auth email for signInWithPassword.';

revoke all on function public.auth_resolve_login_email(text) from public;
grant execute on function public.auth_resolve_login_email(text) to anon, authenticated;
