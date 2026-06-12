-- Unify post likes/dislikes into one reactions table (exclusive), add dislikes_count.
-- Note: dropping old post_likes is done in a follow-up migration after hot_posts_24h is updated.

-- --------------------------------------------------------------------------- posts: add dislikes_count
alter table public.posts
  add column if not exists dislikes_count integer not null default 0
    constraint posts_dislikes_count_non_negative check (dislikes_count >= 0);

-- --------------------------------------------------------------------------- post_reactions (one row per user per post)
create table if not exists public.post_reactions (
  post_id uuid not null references public.posts (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  kind text not null constraint post_reactions_kind_check check (kind in ('like', 'dislike')),
  created_at timestamptz not null default now(),
  primary key (post_id, user_id)
);

create index if not exists post_reactions_user_id_idx on public.post_reactions (user_id);
create index if not exists post_reactions_post_kind_created_idx
  on public.post_reactions (post_id, kind, created_at desc);

comment on table public.post_reactions is 'Exclusive reaction per user per post: like|dislike';

-- --------------------------------------------------------------------------- Counters sync: likes_count + dislikes_count on posts
create or replace function public.post_reactions_sync_post_counts()
returns trigger
language plpgsql
as $$
begin
  if tg_op = 'INSERT' then
    if new.kind = 'like' then
      update public.posts set likes_count = likes_count + 1 where id = new.post_id;
    else
      update public.posts set dislikes_count = dislikes_count + 1 where id = new.post_id;
    end if;
    return new;
  end if;

  if tg_op = 'DELETE' then
    if old.kind = 'like' then
      update public.posts set likes_count = greatest(0, likes_count - 1) where id = old.post_id;
    else
      update public.posts set dislikes_count = greatest(0, dislikes_count - 1) where id = old.post_id;
    end if;
    return old;
  end if;

  -- UPDATE: only care about kind change
  if tg_op = 'UPDATE' then
    if old.kind <> new.kind then
      if old.kind = 'like' then
        update public.posts set likes_count = greatest(0, likes_count - 1) where id = old.post_id;
      else
        update public.posts set dislikes_count = greatest(0, dislikes_count - 1) where id = old.post_id;
      end if;

      if new.kind = 'like' then
        update public.posts set likes_count = likes_count + 1 where id = new.post_id;
      else
        update public.posts set dislikes_count = dislikes_count + 1 where id = new.post_id;
      end if;
    end if;
    return new;
  end if;

  return null;
end;
$$;

drop trigger if exists trg_post_reactions_counts_ins on public.post_reactions;
create trigger trg_post_reactions_counts_ins
  after insert on public.post_reactions
  for each row
  execute function public.post_reactions_sync_post_counts();

drop trigger if exists trg_post_reactions_counts_del on public.post_reactions;
create trigger trg_post_reactions_counts_del
  after delete on public.post_reactions
  for each row
  execute function public.post_reactions_sync_post_counts();

drop trigger if exists trg_post_reactions_counts_upd on public.post_reactions;
create trigger trg_post_reactions_counts_upd
  after update of kind on public.post_reactions
  for each row
  execute function public.post_reactions_sync_post_counts();

-- --------------------------------------------------------------------------- RPC: exclusive toggles (atomic)
create or replace function public.toggle_post_like(p_post_id uuid)
returns table (liked boolean)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_kind text;
begin
  if v_uid is null then
    raise exception 'auth required';
  end if;

  select r.kind into v_kind
  from public.post_reactions r
  where r.post_id = p_post_id and r.user_id = v_uid;

  if v_kind is null then
    insert into public.post_reactions(post_id, user_id, kind) values (p_post_id, v_uid, 'like');
    return query select true;
    return;
  end if;

  if v_kind = 'like' then
    delete from public.post_reactions where post_id = p_post_id and user_id = v_uid;
    return query select false;
    return;
  end if;

  update public.post_reactions
    set kind = 'like'
  where post_id = p_post_id and user_id = v_uid;
  return query select true;
end;
$$;

create or replace function public.toggle_post_dislike(p_post_id uuid)
returns table (disliked boolean)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_kind text;
begin
  if v_uid is null then
    raise exception 'auth required';
  end if;

  select r.kind into v_kind
  from public.post_reactions r
  where r.post_id = p_post_id and r.user_id = v_uid;

  if v_kind is null then
    insert into public.post_reactions(post_id, user_id, kind) values (p_post_id, v_uid, 'dislike');
    return query select true;
    return;
  end if;

  if v_kind = 'dislike' then
    delete from public.post_reactions where post_id = p_post_id and user_id = v_uid;
    return query select false;
    return;
  end if;

  update public.post_reactions
    set kind = 'dislike'
  where post_id = p_post_id and user_id = v_uid;
  return query select true;
end;
$$;

revoke all on function public.toggle_post_like(uuid) from public;
revoke all on function public.toggle_post_dislike(uuid) from public;
grant execute on function public.toggle_post_like(uuid) to authenticated;
grant execute on function public.toggle_post_dislike(uuid) to authenticated;

-- --------------------------------------------------------------------------- RPC: list reactions (minimal: user_id + created_at)
create or replace function public.list_post_likes(p_post_id uuid, p_limit integer default 50, p_offset integer default 0)
returns table (user_id uuid, created_at timestamptz)
language sql
stable
set search_path = public
as $$
  select r.user_id, r.created_at
  from public.post_reactions r
  where r.post_id = p_post_id and r.kind = 'like'
  order by r.created_at desc
  limit greatest(0, p_limit) offset greatest(0, p_offset);
$$;

create or replace function public.list_post_dislikes(p_post_id uuid, p_limit integer default 50, p_offset integer default 0)
returns table (user_id uuid, created_at timestamptz)
language sql
stable
set search_path = public
as $$
  select r.user_id, r.created_at
  from public.post_reactions r
  where r.post_id = p_post_id and r.kind = 'dislike'
  order by r.created_at desc
  limit greatest(0, p_limit) offset greatest(0, p_offset);
$$;

revoke all on function public.list_post_likes(uuid, integer, integer) from public;
revoke all on function public.list_post_dislikes(uuid, integer, integer) from public;
grant execute on function public.list_post_likes(uuid, integer, integer) to anon, authenticated;
grant execute on function public.list_post_dislikes(uuid, integer, integer) to anon, authenticated;

-- --------------------------------------------------------------------------- RLS + grants: post_reactions
alter table public.post_reactions enable row level security;

drop policy if exists post_reactions_select_visible on public.post_reactions;
create policy post_reactions_select_visible
  on public.post_reactions
  for select
  to anon, authenticated
  using (
    exists (
      select 1
      from public.posts p
      where p.id = post_reactions.post_id
        and p.is_archived = false
        and p.deleted_at is null
    )
  );

drop policy if exists post_reactions_insert_own on public.post_reactions;
create policy post_reactions_insert_own
  on public.post_reactions
  for insert
  to authenticated
  with check (auth.uid() = user_id);

drop policy if exists post_reactions_update_own on public.post_reactions;
create policy post_reactions_update_own
  on public.post_reactions
  for update
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists post_reactions_delete_own on public.post_reactions;
create policy post_reactions_delete_own
  on public.post_reactions
  for delete
  to authenticated
  using (auth.uid() = user_id);

grant select on public.post_reactions to anon;
grant select, insert, update, delete on public.post_reactions to authenticated;
