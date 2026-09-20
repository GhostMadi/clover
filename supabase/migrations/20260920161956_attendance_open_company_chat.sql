-- Open company group chat: ensure conversation + sync all active members.
-- Fixes: client fell back to local stub when group_conversation_id was null;
-- active employees must all be participants in the company chat.

create or replace function public.attendance_open_company_chat(p_workplace_id uuid)
returns uuid
language plpgsql
security definer
set search_path = public
set row_security to off
as $$
declare
  uid uuid;
  cid uuid;
  r record;
begin
  uid := public.attendance_assert_authenticated();

  if not public.attendance_can_view_workplace(p_workplace_id, uid) then
    raise exception 'forbidden' using errcode = 'P0102';
  end if;

  cid := public.attendance_ensure_group_chat(p_workplace_id);

  -- All active members (owner may also be listed — keep them as member first).
  for r in
    select m.profile_id
    from public.attendance_memberships m
    where m.workplace_id = p_workplace_id
      and m.status = 'active'::public.attendance_membership_status
  loop
    insert into public.chat_participants (conversation_id, user_id, role)
    values (cid, r.profile_id, 'member')
    on conflict (conversation_id, user_id) do update
      set left_at = null;
  end loop;

  -- Owner always in chat as admin (wins over member role if also active).
  insert into public.chat_participants (conversation_id, user_id, role)
  select cid, w.owner_id, 'admin'
  from public.attendance_workplaces w
  where w.id = p_workplace_id
  on conflict (conversation_id, user_id) do update
    set left_at = null,
        role = 'admin';

  return cid;
end;
$$;

revoke all on function public.attendance_open_company_chat(uuid) from public;
grant execute on function public.attendance_open_company_chat(uuid) to authenticated;

comment on function public.attendance_open_company_chat(uuid) is
  'Ensure workplace group chat exists and sync owner + active members as participants; returns conversation id.';
