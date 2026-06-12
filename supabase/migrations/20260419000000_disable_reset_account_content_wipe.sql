-- Сброс контента (удаление постов, кластеров, storage) отключён по продукту.
-- Доступно только изменение состояния аккаунта через hibernate_account / wake_up_if_needed.
-- Цепочка миграций reset_account → см. supabase/MIGRATIONS_INDEX.md («Состояние аккаунта»).

create or replace function public.reset_account()
returns void
language plpgsql
security definer
set search_path = public
set row_security to off
as $$
begin
  raise exception 'reset_account_disabled'
    using errcode = 'P0001',
          message = 'Сброс контента отключён. Используйте режим сна аккаунта (hibernate_account).';
end;
$$;

revoke all on function public.reset_account() from public;
revoke execute on function public.reset_account() from authenticated;

comment on function public.reset_account() is
  'Отключено: полное удаление контента не поддерживается. Только hibernate_account.';
