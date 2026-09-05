-- OTP create_user can populate encrypted_password immediately — do NOT treat that as registered.
-- Fully registered = clover_password_set metadata (after setPassword) OR OAuth identity.

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
        coalesce((u.raw_user_meta_data ->> 'clover_password_set')::boolean, false)
        or coalesce((u.raw_app_meta_data ->> 'clover_password_set')::boolean, false)
        or exists (
          select 1
          from auth.identities i
          where i.user_id = u.id
            and i.provider in (
              'google',
              'apple',
              'azure',
              'facebook',
              'github',
              'gitlab',
              'bitbucket',
              'discord',
              'linkedin',
              'linkedin_oidc',
              'spotify',
              'twitch',
              'twitter',
              'workos',
              'slack',
              'zoom',
              'keycloak',
              'notion'
            )
        )
      )
  );
end;
$$;

comment on function public.auth_is_email_fully_registered(text) is
  'Completed account: clover_password_set metadata after setPassword, or OAuth. Raw encrypted_password after OTP create is ignored.';
