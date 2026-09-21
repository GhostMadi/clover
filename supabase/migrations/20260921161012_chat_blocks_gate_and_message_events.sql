-- Chat: gate DM send/create via can_user_interact; broadcast delete/edit to open threads.

-- --------------------------------------------------------------------------- DM block gate
create or replace function public.chat_assert_dm_interactable(p_conversation_id uuid)
returns void
language plpgsql
security definer
set search_path = public
set row_security to off
as $$
declare
  uid uuid;
  peer uuid;
  ctype text;
begin
  uid := auth.uid();
  if uid is null then
    raise exception 'not_authenticated' using errcode = 'P0003';
  end if;

  select c.type::text into ctype
  from public.chat_conversations c
  where c.id = p_conversation_id;

  if ctype is distinct from 'dm' then
    return;
  end if;

  select p.user_id into peer
  from public.chat_participants p
  where p.conversation_id = p_conversation_id
    and p.user_id <> uid
    and p.left_at is null
  limit 1;

  if peer is null then
    return;
  end if;

  if not public.can_user_interact(uid, peer) then
    raise exception 'user_blocked' using errcode = 'P0009';
  end if;
end;
$$;

revoke all on function public.chat_assert_dm_interactable(uuid) from public;
grant execute on function public.chat_assert_dm_interactable(uuid) to authenticated;

comment on function public.chat_assert_dm_interactable(uuid) is
  'DM only: raises user_blocked (P0009) if profile_blocks prevents interact.';

-- --------------------------------------------------------------------------- create_dm
create or replace function public.create_dm(p_other_user_id uuid)
returns uuid
language plpgsql
security definer
set search_path = public
set row_security to off
as $$
declare
  uid uuid;
  cid uuid;
begin
  uid := auth.uid();
  if uid is null then
    raise exception 'not_authenticated' using errcode = 'P0003';
  end if;

  if p_other_user_id is null or p_other_user_id = uid then
    raise exception 'invalid_user' using errcode = 'P0007';
  end if;

  if not exists (select 1 from public.profiles pr where pr.id = p_other_user_id) then
    raise exception 'user_not_found' using errcode = 'P0008';
  end if;
  if exists (select 1 from public.profiles pr where pr.id = p_other_user_id and pr.account_state = 'hibernate') then
    raise exception 'user_sleeping' using errcode = 'P0006';
  end if;

  -- Reuse existing DM even if blocked (history); new create / send gated separately.
  select c.id into cid
  from public.chat_conversations c
  where c.type = 'dm'
    and exists (
      select 1 from public.chat_participants p
      where p.conversation_id = c.id and p.user_id = uid and p.left_at is null
    )
    and exists (
      select 1 from public.chat_participants p
      where p.conversation_id = c.id and p.user_id = p_other_user_id and p.left_at is null
    )
    and 2 = (
      select count(*) from public.chat_participants p
      where p.conversation_id = c.id and p.left_at is null
    )
  order by c.created_at desc
  limit 1;

  if cid is not null then
    return cid;
  end if;

  if not public.can_user_interact(uid, p_other_user_id) then
    raise exception 'user_blocked' using errcode = 'P0009';
  end if;

  insert into public.chat_conversations (type, title, created_by)
  values ('dm', null, uid)
  returning id into cid;

  insert into public.chat_participants (conversation_id, user_id, role)
  values
    (cid, uid, 'member'),
    (cid, p_other_user_id, 'member')
  on conflict do nothing;

  return cid;
end;
$$;

revoke all on function public.create_dm(uuid) from public;
grant execute on function public.create_dm(uuid) to authenticated;
