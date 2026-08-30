-- ============================================================
-- Phase 1: WhatsApp Phone Auth foundation (mirror only)
-- - No OTP tables
-- - No rate limit / events tables
-- - No unique index on profiles.phone
-- - Phone uniqueness remains auth.users.users_phone_key
-- ============================================================

-- A) Signup: mirror phone (+ safe empty email) without breaking Google
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $$
begin
  insert into public.profiles (id, email, phone)
  values (
    new.id,
    nullif(new.email, ''),
    nullif(new.phone, '')
  )
  on conflict (id) do update
    set
      email = coalesce(excluded.email, public.profiles.email),
      phone = coalesce(excluded.phone, public.profiles.phone),
      updated_at = now();

  return new;
end;
$$;

-- Existing trigger stays as-is:
-- on_auth_user_created AFTER INSERT ON auth.users → handle_new_user()

-- B) Sync auth.users.phone → profiles.phone on phone change
create or replace function public.handle_user_phone_update()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $$
begin
  if new.phone is distinct from old.phone then
    update public.profiles
    set
      phone = nullif(new.phone, ''),
      updated_at = now()
    where id = new.id;
  end if;

  return new;
end;
$$;

drop trigger if exists on_auth_user_phone_update on auth.users;

create trigger on_auth_user_phone_update
  after update of phone on auth.users
  for each row
  execute function public.handle_user_phone_update();
