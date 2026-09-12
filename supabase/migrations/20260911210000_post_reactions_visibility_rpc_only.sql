-- Posts audit: reaction RPCs must enforce post visibility; DML only via RPC.

-- ---------------------------------------------------------------------------
-- set_post_reaction: require reactable post when setting kind (clear always ok)
-- ---------------------------------------------------------------------------
create or replace function public.set_post_reaction(p_post_id uuid, p_kind text default null)
returns table (kind text)
language plpgsql
security definer
set search_path = public
set row_security to off
as $$
declare
  v_uid uuid := auth.uid();
begin
  if v_uid is null then
    raise exception 'auth required';
  end if;

  if p_post_id is null then
    raise exception 'invalid_arguments';
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

  if not exists (
    select 1
    from public.posts p
    join public.profiles pr on pr.id = p.user_id
    where p.id = p_post_id
      and (
        p.user_id = v_uid
        or (
          p.deleted_at is null
          and p.is_archived = false
          and pr.content_visible = true
          and pr.account_state <> 'hibernate'
        )
      )
  ) then
    raise exception 'post_not_reactable';
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
  'Sets reaction like|dislike|null. Set requires visible post (or own); clear always allowed. RPC-only DML.';

-- ---------------------------------------------------------------------------
-- set_comment_reaction: same visibility via parent post
-- ---------------------------------------------------------------------------
create or replace function public.set_comment_reaction(p_comment_id uuid, p_kind text default null)
returns table (kind text)
language plpgsql
security definer
set search_path = public
set row_security to off
as $$
declare
  v_uid uuid := auth.uid();
begin
  if v_uid is null then
    raise exception 'auth required';
  end if;

  if p_comment_id is null then
    raise exception 'invalid_arguments';
  end if;

  if p_kind is not null and p_kind not in ('like', 'dislike') then
    raise exception 'invalid kind';
  end if;

  if p_kind is null then
    delete from public.comment_reactions
    where comment_id = p_comment_id and user_id = v_uid;
    return query select null::text;
    return;
  end if;

  if not exists (
    select 1
    from public.comments c
    join public.posts p on p.id = c.post_id
    join public.profiles pr on pr.id = p.user_id
    where c.id = p_comment_id
      and (
        p.user_id = v_uid
        or (
          p.deleted_at is null
          and p.is_archived = false
          and pr.content_visible = true
          and pr.account_state <> 'hibernate'
        )
      )
  ) then
    raise exception 'comment_not_reactable';
  end if;

  insert into public.comment_reactions (comment_id, user_id, kind)
  values (p_comment_id, v_uid, p_kind)
  on conflict (comment_id, user_id)
  do update set kind = excluded.kind;

  return query select p_kind;
end;
$$;

revoke all on function public.set_comment_reaction(uuid, text) from public;
grant execute on function public.set_comment_reaction(uuid, text) to authenticated;

comment on function public.set_comment_reaction(uuid, text) is
  'Sets comment reaction like|dislike|null. Set requires reactable parent post; clear always. RPC-only DML.';

-- ---------------------------------------------------------------------------
-- PostgREST: no direct DML (RPC-only writes)
-- ---------------------------------------------------------------------------
revoke insert, update, delete on public.post_reactions from authenticated;
revoke insert, update, delete on public.comment_reactions from authenticated;
grant select on public.post_reactions to anon, authenticated;
grant select on public.comment_reactions to anon, authenticated;

-- Defense-in-depth if grants are restored later
drop policy if exists post_reactions_insert_own on public.post_reactions;
create policy post_reactions_insert_own
  on public.post_reactions
  for insert
  to authenticated
  with check (
    auth.uid() = user_id
    and exists (
      select 1
      from public.posts p
      join public.profiles pr on pr.id = p.user_id
      where p.id = post_reactions.post_id
        and (
          p.user_id = auth.uid()
          or (
            p.deleted_at is null
            and p.is_archived = false
            and pr.content_visible = true
            and pr.account_state <> 'hibernate'
          )
        )
    )
  );
