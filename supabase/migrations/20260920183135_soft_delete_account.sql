-- Soft delete account: hide like hibernate, no cascade wipe / no auth.admin.deleteUser.
-- Product: docs/business/account-delete.md

create or replace function public.soft_delete_account()
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  uid uuid;
begin
  uid := auth.uid();
  if uid is null then
    raise exception 'not_authenticated' using errcode = 'P0003';
  end if;

  update public.profiles
  set
    account_state = 'hibernate',
    content_visible = false
  where id = uid;
end;
$$;

revoke all on function public.soft_delete_account() from public;
grant execute on function public.soft_delete_account() to authenticated;

comment on function public.soft_delete_account() is
  'In-app "delete": soft-hide like hibernate (account_state=hibernate, content_visible=false). No row wipe, no auth.users delete. No 30d rate limit. Wake via wake_up_if_needed on next login.';
