-- Relations system v3: Intent-based logic, Strict State Machine, Race-condition protection.
-- Standards: Canonical order, Explicit actions ('hire'/'join'), Status history-ready.

-- --------------------------------------------------------------------------- profiles: flags
alter table public.profiles
  add column if not exists open_for_memberships boolean not null default false,
  add column if not exists hiring_enabled boolean not null default false;

-- --------------------------------------------------------------------------- relations table
create table if not exists public.relations (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  
  from_account_id uuid not null references public.profiles (id) on delete cascade,
  to_account_id uuid not null references public.profiles (id) on delete cascade,
  initiator_id uuid not null references public.profiles (id) on delete cascade,
  
  -- Intent: why this relation was created
  relation_type text not null default 'hire'
    constraint relations_type_value check (relation_type in ('hire', 'join')),
    
  status text not null default 'pending'
    constraint relations_status_value check (status in ('pending', 'active', 'rejected', 'terminated')),

  -- Integrity constraints
  constraint relations_unique_pair unique (from_account_id, to_account_id),
  constraint relations_no_self check (from_account_id <> to_account_id),
  constraint relations_canonical_order check (from_account_id < to_account_id),
  constraint relations_valid_initiator check (initiator_id = from_account_id or initiator_id = to_account_id)
);

create index if not exists relations_from_idx on public.relations (from_account_id);
create index if not exists relations_to_idx on public.relations (to_account_id);

-- --------------------------------------------------------------------------- RPC: Request Relation
create or replace function public.request_relation(
  p_target_id uuid,
  p_action text -- 'hire' (я нанимаю его) or 'join' (я хочу к нему)
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  uid uuid := auth.uid();
  v_me_hiring boolean;
  v_target_open boolean;
  v_from uuid;
  v_to uuid;
  v_n int;
begin
  if uid is null then raise exception 'not_authenticated' using errcode = 'P0003'; end if;
  if uid = p_target_id then raise exception 'cannot_self_request' using errcode = 'P0007'; end if;
  if p_action not in ('hire', 'join') then raise exception 'invalid_action'; end if;

  -- Intent: hire → у инициатора включён hiring_enabled; join → у цели включён open_for_memberships
  if p_action = 'hire' then
    select coalesce(p.hiring_enabled, false) into v_me_hiring from public.profiles p where p.id = uid;
    if v_me_hiring is null then raise exception 'user_not_found'; end if;
    if not v_me_hiring then raise exception 'hiring_disabled_for_you'; end if;
  else
    select coalesce(p.open_for_memberships, false) into v_target_open from public.profiles p where p.id = p_target_id;
    if v_target_open is null then raise exception 'user_not_found'; end if;
    if not v_target_open then raise exception 'target_memberships_closed'; end if;
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

-- --------------------------------------------------------------------------- RPC: single row between auth user and peer (canonical pair on server)
create or replace function public.get_my_relation_with(p_other uuid)
returns public.relations
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  uid uuid := auth.uid();
  r public.relations%rowtype;
begin
  if uid is null then raise exception 'not_authenticated' using errcode = 'P0003'; end if;
  if p_other is null or p_other = uid then
    return null::public.relations;
  end if;

  select * into strict r
  from public.relations x
  where x.from_account_id = least(uid, p_other)
    and x.to_account_id = greatest(uid, p_other);

  return r;
exception
  when no_data_found then
    return null::public.relations;
end;
$$;

-- --------------------------------------------------------------------------- RPC: Update Status
create or replace function public.update_relation_status(
  p_relation_id uuid,
  p_new_status text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  uid uuid := auth.uid();
  r_row record;
  v_is_receiver boolean;
begin
  -- Валидация входного статуса
  if p_new_status not in ('active', 'rejected', 'terminated') then
    raise exception 'invalid_status_target';
  end if;

  select * into r_row from public.relations where id = p_relation_id for update; -- Row-level lock
  if not found then raise exception 'relation_not_found'; end if;

  v_is_receiver := (uid = r_row.from_account_id or uid = r_row.to_account_id) and (uid <> r_row.initiator_id);

  -- State Machine Logic
  case p_new_status
    when 'active' then
      if not v_is_receiver then raise exception 'only_receiver_can_accept'; end if;
      if r_row.status <> 'pending' then raise exception 'can_only_accept_pending'; end if;
      
    when 'rejected' then
      if not v_is_receiver then raise exception 'only_receiver_can_reject'; end if;
      if r_row.status <> 'pending' then raise exception 'can_only_reject_pending'; end if;

    when 'terminated' then
      if uid <> r_row.from_account_id and uid <> r_row.to_account_id then raise exception 'not_authorized'; end if;
      if r_row.status <> 'active' then raise exception 'can_only_terminate_active'; end if;
  end case;

  update public.relations
  set status = p_new_status,
      updated_at = now()
  where id = p_relation_id;
end;
$$;

-- --------------------------------------------------------------------------- Triggers: Updated At
create or replace function public.handle_updated_at()
returns trigger as $$ begin new.updated_at = now(); return new; end; $$ language plpgsql;

drop trigger if exists tr_relations_updated_at on public.relations;
create trigger tr_relations_updated_at before update on public.relations
for each row execute function public.handle_updated_at();

-- --------------------------------------------------------------------------- RLS: только SELECT своих рёбер; DML только через security definer RPC
alter table public.relations enable row level security;

drop policy if exists relations_select_involved on public.relations;
create policy relations_select_involved
  on public.relations
  for select
  to authenticated
  using (auth.uid() = from_account_id or auth.uid() = to_account_id);

revoke insert, update, delete, truncate, references, trigger on public.relations from public;
revoke insert, update, delete on public.relations from anon;

grant select on public.relations to authenticated;

-- --------------------------------------------------------------------------- Rights
grant execute on function public.request_relation(uuid, text) to authenticated;
grant execute on function public.update_relation_status(uuid, text) to authenticated;
grant execute on function public.get_my_relation_with(uuid) to authenticated;