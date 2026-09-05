-- Fully registered = can login (password set OR OAuth identity).
-- Incomplete email OTP signup must NOT block register resend.

create or replace function public.auth_is_email_fully_registered(p_email text)
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
      and (
        (u.encrypted_password is not null and length(btrim(u.encrypted_password)) > 0)
        or exists (
          select 1
          from auth.identities i
          where i.user_id = u.id
            and i.provider is distinct from 'email'
        )
      )
  );
end;
$$;

comment on function public.auth_is_email_fully_registered(text) is
  'True if email belongs to a completed account (password or OAuth). Incomplete OTP signups are false so register may resend OTP.';

revoke all on function public.auth_is_email_fully_registered(text) from public;
grant execute on function public.auth_is_email_fully_registered(text) to anon, authenticated;

comment on function public.auth_is_email_registered(text) is
  'True if auth.users has this email (including incomplete OTP signup). Used for forgot-password gate.';
