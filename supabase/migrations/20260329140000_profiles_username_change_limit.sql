-- Поля лимита смены username + триггер (согласовано с основной схемой profiles).
-- Полная DDL таблицы, RLS, normalize_username и т.д. — в общем скрипте проекта / Supabase.

alter table public.profiles
  add column if not exists username_change_count integer not null default 0,
  add column if not exists username_next_change_allowed_at timestamptz null;

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'profiles_username_change_count_range'
  ) then
    alter table public.profiles
      add constraint profiles_username_change_count_range
      check (username_change_count >= 0 and username_change_count <= 4);
  end if;
end $$;

comment on column public.profiles.username_change_count is
  'Сколько смен ника в текущем окне; первое присвоение NULL→ник не считается.';

comment on column public.profiles.username_next_change_allowed_at is
  'Пока now() < этого момента — смена ника с непустого старого запрещена (пауза после 4 смен).';

-- После trg_profiles_normalize_username (имя триггера лексикографически раньше enforce).
create or replace function public.enforce_username_change_limit()
returns trigger
language plpgsql
as $$
declare
  old_u text;
  new_u text;

  eff_count integer;
  cool_until timestamptz;

  deadline_utc text;
begin
  old_u := case when old.username is null then null else lower(trim(old.username)) end;
  new_u := case when new.username is null then null else lower(trim(new.username)) end;

  eff_count := old.username_change_count;
  cool_until := old.username_next_change_allowed_at;

  if cool_until is not null and now() >= cool_until then
    eff_count := 0;
    cool_until := null;
  end if;

  new.username_change_count := eff_count;
  new.username_next_change_allowed_at := cool_until;

  if old_u is distinct from new_u then

    if old_u is null then
      new.username_change_count := eff_count;
      new.username_next_change_allowed_at := cool_until;
      return new;
    end if;

    if cool_until is not null and now() < cool_until then
      deadline_utc := to_char(cool_until at time zone 'utc', 'YYYY-MM-DD"T"HH24:MI:SS"Z"');
      raise exception 'username_change_cooldown'
        using errcode = 'P0002',
              hint = deadline_utc;
    end if;

    if eff_count >= 4 then
      raise exception 'username_change_limit_reached'
        using errcode = 'P0001';
    end if;

    eff_count := eff_count + 1;

    if eff_count >= 4 then
      cool_until := now() + interval '7 days';
    end if;

    new.username_change_count := eff_count;
    new.username_next_change_allowed_at := cool_until;
  end if;

  return new;
end;
$$;

drop trigger if exists trg_profiles_enforce_username_change_limit on public.profiles;

create trigger trg_profiles_enforce_username_change_limit
before update on public.profiles
for each row
execute function public.enforce_username_change_limit();
