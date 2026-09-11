-- Site admin flag: ordinary profile can access /admin when true.
alter table public.profiles
  add column if not exists is_site_admin boolean not null default false;

comment on column public.profiles.is_site_admin is
  'Доступ к служебной админке сайта /admin (не путать с тегами booking/attendance).';

create index if not exists profiles_is_site_admin_idx
  on public.profiles (id)
  where is_site_admin;

-- Bootstrap: первый вошедший пользователь может назначить себя админом сайта.
-- Если админ уже есть — новые назначить через SQL / Dashboard.
create or replace function public.promote_self_to_site_admin()
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  uid uuid := auth.uid();
  admin_count int;
  already boolean;
begin
  if uid is null then
    raise exception 'not_authenticated';
  end if;

  select coalesce(is_site_admin, false) into already
  from public.profiles
  where id = uid;

  if already then
    return true;
  end if;

  select count(*)::int into admin_count
  from public.profiles
  where is_site_admin;

  if admin_count > 0 then
    raise exception 'site_admin_exists';
  end if;

  update public.profiles
  set is_site_admin = true, updated_at = now()
  where id = uid;

  if not found then
    raise exception 'profile_missing';
  end if;

  return true;
end;
$$;

revoke all on function public.promote_self_to_site_admin() from public;
grant execute on function public.promote_self_to_site_admin() to authenticated;

create or replace function public.is_site_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(
    (select is_site_admin from public.profiles where id = auth.uid()),
    false
  );
$$;

revoke all on function public.is_site_admin() from public;
grant execute on function public.is_site_admin() to authenticated;
