-- Bonus phase 0: program status on profiles (zero extra HTTP on profile reads).
-- Navigator: migrations/_bonus/README.md

do $$ begin
  create type public.bonus_program_status as enum ('active', 'inactive');
exception
  when duplicate_object then null;
end $$;

alter table public.profiles
  add column if not exists bonus_program_status public.bonus_program_status not null default 'inactive';

comment on column public.profiles.bonus_program_status is
  'Бонусная программа host-аккаунта: active — клиенты могут копить и тратить бонусы.';

create index if not exists profiles_bonus_program_status_active_idx
  on public.profiles (bonus_program_status)
  where bonus_program_status = 'active';
