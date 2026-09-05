-- Does the signed-in user have a password set? (auth.users.encrypted_password)
-- Used by Settings → Account: "Установить пароль" vs "Сбросить пароль".

set search_path = public;

create or replace function public.auth_current_user_has_password()
returns boolean
language plpgsql
security definer
set search_path = auth, public
set row_security to off
as $$
declare
  uid uuid := auth.uid();
  enc text;
begin
  if uid is null then
    return false;
  end if;

  select u.encrypted_password
  into enc
  from auth.users u
  where u.id = uid
    and u.deleted_at is null;

  return enc is not null and length(btrim(enc)) > 0;
end;
$$;

comment on function public.auth_current_user_has_password() is
  'True if auth.users.encrypted_password is set for auth.uid(). OAuth-only users are false until they set a password.';

revoke all on function public.auth_current_user_has_password() from public;
grant execute on function public.auth_current_user_has_password() to authenticated;
