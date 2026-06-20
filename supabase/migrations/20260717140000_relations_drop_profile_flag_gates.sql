-- Убираем gate по hiring_enabled / open_for_memberships: заявки hire/join без флагов профиля.

create or replace function public.request_relation(
  p_target_id uuid,
  p_action text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  uid uuid := auth.uid();
  v_from uuid;
  v_to uuid;
  v_n int;
begin
  if uid is null then
    raise exception 'not_authenticated' using errcode = 'P0003';
  end if;

  if uid = p_target_id then
    raise exception 'cannot_self_request' using errcode = 'P0007';
  end if;

  if p_action not in ('hire', 'join') then
    raise exception 'invalid_action';
  end if;

  if not exists (select 1 from public.profiles p where p.id = p_target_id) then
    raise exception 'user_not_found';
  end if;

  v_from := least(uid, p_target_id);
  v_to := greatest(uid, p_target_id);

  insert into public.relations (from_account_id, to_account_id, initiator_id, relation_type, status)
  values (v_from, v_to, uid, p_action, 'pending')
  on conflict (from_account_id, to_account_id)
  do update set
    initiator_id = excluded.initiator_id,
    relation_type = excluded.relation_type,
    status = excluded.status,
    updated_at = now()
  where public.relations.status in ('rejected', 'terminated');

  get diagnostics v_n = row_count;
  if v_n = 0 then
    raise exception 'relation_already_active_or_pending';
  end if;
end;
$$;

comment on function public.request_relation(uuid, text) is
  'Create or reopen pending relation (hire|join); no profile flag gates.';
