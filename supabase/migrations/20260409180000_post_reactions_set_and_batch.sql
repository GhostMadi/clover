-- Improve reactions API:
-- 1) set_post_reaction(post_id, kind) instead of toggle RPCs (race-safe)
-- 2) batch getter get_my_post_reactions(post_ids[])
-- 3) add helpful indexes

-- --------------------------------------------------------------------------- Indexes
create index if not exists post_reactions_post_id_idx on public.post_reactions (post_id);
create index if not exists post_reactions_post_id_kind_idx on public.post_reactions (post_id, kind);

-- --------------------------------------------------------------------------- RPC: set reaction explicitly (like|dislike|null)
create or replace function public.set_post_reaction(p_post_id uuid, p_kind text default null)
returns table (kind text)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
begin
  if v_uid is null then
    raise exception 'auth required';
  end if;

  if p_kind is not null and p_kind not in ('like', 'dislike') then
    raise exception 'invalid kind';
  end if;

  if p_kind is null then
    delete from public.post_reactions
    where post_id = p_post_id and user_id = v_uid;
    return query select null::text;
    return;
  end if;

  insert into public.post_reactions(post_id, user_id, kind)
  values (p_post_id, v_uid, p_kind)
  on conflict (post_id, user_id)
  do update set kind = excluded.kind;

  return query select p_kind;
end;
$$;

revoke all on function public.set_post_reaction(uuid, text) from public;
grant execute on function public.set_post_reaction(uuid, text) to authenticated;

comment on function public.set_post_reaction(uuid, text) is
  'Sets current user reaction for post: like|dislike|null (explicit, race-safe).';

-- --------------------------------------------------------------------------- RPC: batch get my reactions
create or replace function public.get_my_post_reactions(p_post_ids uuid[])
returns table (post_id uuid, kind text)
language sql
stable
set search_path = public
as $$
  select r.post_id, r.kind
  from public.post_reactions r
  where r.user_id = auth.uid()
    and r.post_id = any(p_post_ids);
$$;

revoke all on function public.get_my_post_reactions(uuid[]) from public;
grant execute on function public.get_my_post_reactions(uuid[]) to authenticated;

comment on function public.get_my_post_reactions(uuid[]) is
  'Batch: returns current user reactions for provided post ids.';

