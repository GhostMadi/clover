-- Отмена pending-заявки инициатором + enriched list для клиента.

-- --------------------------------------------------------------------------- withdraw (initiator, pending only)
create or replace function public.withdraw_relation(p_relation_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  uid uuid := auth.uid();
  r_row public.relations%rowtype;
begin
  if uid is null then
    raise exception 'not_authenticated' using errcode = 'P0003';
  end if;

  select * into r_row from public.relations where id = p_relation_id for update;
  if not found then
    raise exception 'relation_not_found';
  end if;

  if uid <> r_row.initiator_id then
    raise exception 'only_initiator_can_withdraw';
  end if;

  if r_row.status <> 'pending' then
    raise exception 'can_only_withdraw_pending';
  end if;

  delete from public.relations where id = p_relation_id;
end;
$$;

comment on function public.withdraw_relation(uuid) is
  'Initiator cancels own pending relation (DELETE row; pair may request again).';

grant execute on function public.withdraw_relation(uuid) to authenticated;

-- --------------------------------------------------------------------------- list with peer profile (involved user only)
create or replace function public.list_my_relations_enriched()
returns table (
  id uuid,
  relation_type text,
  status text,
  initiator_id uuid,
  from_account_id uuid,
  to_account_id uuid,
  created_at timestamptz,
  updated_at timestamptz,
  peer_id uuid,
  peer_username text,
  peer_full_name text,
  peer_avatar_url text
)
language sql
stable
security definer
set search_path = public
as $$
  select
    r.id,
    r.relation_type,
    r.status,
    r.initiator_id,
    r.from_account_id,
    r.to_account_id,
    r.created_at,
    r.updated_at,
    case
      when r.from_account_id = auth.uid() then r.to_account_id
      else r.from_account_id
    end as peer_id,
    case when p.reset_at is not null then 'noName' else p.username end as peer_username,
    p.full_name as peer_full_name,
    p.avatar_url as peer_avatar_url
  from public.relations r
  join public.profiles p
    on p.id = case
      when r.from_account_id = auth.uid() then r.to_account_id
      else r.from_account_id
    end
  where auth.uid() in (r.from_account_id, r.to_account_id)
  order by r.updated_at desc;
$$;

comment on function public.list_my_relations_enriched() is
  'All relations for auth user with peer profile fields; RLS bypass via definer.';

grant execute on function public.list_my_relations_enriched() to authenticated;
