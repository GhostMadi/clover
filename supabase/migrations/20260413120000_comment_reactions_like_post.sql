-- Реакции на комментарии как у постов: like | dislike, exclusive, счётчики на comments.
-- Миграция с comment_likes: данные переносятся как kind = 'like', затем старая таблица удаляется.

-- --------------------------------------------------------------------------- comments.dislikes_count
alter table public.comments
  add column if not exists dislikes_count integer not null default 0
    constraint comments_dislikes_count_non_negative check (dislikes_count >= 0);

comment on column public.comments.dislikes_count is
  'Денормализация: число реакций dislike; синхронизируется триггером на comment_reactions.';

-- --------------------------------------------------------------------------- Таблица comment_reactions (без триггеров до пересчёта счётчиков)
create table if not exists public.comment_reactions (
  comment_id uuid not null
    references public.comments (id) on delete cascade,
  user_id uuid not null
    references public.profiles (id) on delete cascade,
  kind text not null
    constraint comment_reactions_kind_check check (kind in ('like', 'dislike')),
  created_at timestamptz not null default now(),
  primary key (comment_id, user_id)
);

create index if not exists comment_reactions_user_id_idx on public.comment_reactions (user_id);
create index if not exists comment_reactions_comment_kind_idx
  on public.comment_reactions (comment_id, kind, created_at desc);

comment on table public.comment_reactions is
  'Реакция пользователя на комментарий: like или dislike (как post_reactions).';

-- Перенос старых лайков
insert into public.comment_reactions (comment_id, user_id, kind, created_at)
select cl.comment_id, cl.user_id, 'like', cl.created_at
from public.comment_likes cl
on conflict (comment_id, user_id) do nothing;

-- Полный пересчёт likes_count / dislikes_count (триггеров на comment_reactions ещё нет)
update public.comments set likes_count = 0, dislikes_count = 0;

update public.comments c
set
  likes_count = coalesce(s.likes_n, 0),
  dislikes_count = coalesce(s.dislikes_n, 0)
from (
  select
    comment_id,
    (count(*) filter (where kind = 'like'))::int as likes_n,
    (count(*) filter (where kind = 'dislike'))::int as dislikes_n
  from public.comment_reactions
  group by comment_id
) s
where c.id = s.comment_id;

-- Удаляем старую таблицу и функцию синхронизации лайков
drop trigger if exists trg_comment_likes_count_ins on public.comment_likes;
drop trigger if exists trg_comment_likes_count_del on public.comment_likes;

drop table if exists public.comment_likes;

drop function if exists public.comment_likes_sync_comment_count();

-- --------------------------------------------------------------------------- Триггеры счётчиков (аналог post_reactions_sync_post_counts)
create or replace function public.comment_reactions_sync_comment_counts()
returns trigger
language plpgsql
as $$
begin
  if tg_op = 'INSERT' then
    if new.kind = 'like' then
      update public.comments set likes_count = likes_count + 1 where id = new.comment_id;
    else
      update public.comments set dislikes_count = dislikes_count + 1 where id = new.comment_id;
    end if;
    return new;
  end if;

  if tg_op = 'DELETE' then
    if old.kind = 'like' then
      update public.comments set likes_count = greatest(0, likes_count - 1) where id = old.comment_id;
    else
      update public.comments set dislikes_count = greatest(0, dislikes_count - 1) where id = old.comment_id;
    end if;
    return old;
  end if;

  if tg_op = 'UPDATE' then
    if old.kind is distinct from new.kind then
      if old.kind = 'like' then
        update public.comments set likes_count = greatest(0, likes_count - 1) where id = old.comment_id;
      else
        update public.comments set dislikes_count = greatest(0, dislikes_count - 1) where id = old.comment_id;
      end if;

      if new.kind = 'like' then
        update public.comments set likes_count = likes_count + 1 where id = new.comment_id;
      else
        update public.comments set dislikes_count = dislikes_count + 1 where id = new.comment_id;
      end if;
    end if;
    return new;
  end if;

  return null;
end;
$$;

drop trigger if exists trg_comment_reactions_counts_ins on public.comment_reactions;
create trigger trg_comment_reactions_counts_ins
  after insert on public.comment_reactions
  for each row
  execute function public.comment_reactions_sync_comment_counts();

drop trigger if exists trg_comment_reactions_counts_del on public.comment_reactions;
create trigger trg_comment_reactions_counts_del
  after delete on public.comment_reactions
  for each row
  execute function public.comment_reactions_sync_comment_counts();

drop trigger if exists trg_comment_reactions_counts_upd on public.comment_reactions;
create trigger trg_comment_reactions_counts_upd
  after update of kind on public.comment_reactions
  for each row
  execute function public.comment_reactions_sync_comment_counts();

-- --------------------------------------------------------------------------- RPC: как set_post_reaction
create or replace function public.set_comment_reaction(p_comment_id uuid, p_kind text default null)
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
    delete from public.comment_reactions
    where comment_id = p_comment_id and user_id = v_uid;
    return query select null::text;
    return;
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
  'Текущая реакция на комментарий: like|dislike|null (как set_post_reaction).';

-- --------------------------------------------------------------------------- RPC: batch «мои» реакции
create or replace function public.get_my_comment_reactions(p_comment_ids uuid[])
returns table (comment_id uuid, kind text)
language sql
stable
set search_path = public
as $$
  select r.comment_id, r.kind
  from public.comment_reactions r
  where r.user_id = auth.uid()
    and r.comment_id = any(p_comment_ids);
$$;

revoke all on function public.get_my_comment_reactions(uuid[]) from public;
grant execute on function public.get_my_comment_reactions(uuid[]) to authenticated;

comment on function public.get_my_comment_reactions(uuid[]) is
  'Batch: реакции текущего пользователя для переданных comment_id.';

-- --------------------------------------------------------------------------- RLS
alter table public.comment_reactions enable row level security;

drop policy if exists comment_reactions_select_visible on public.comment_reactions;
create policy comment_reactions_select_visible
  on public.comment_reactions
  for select
  to anon, authenticated
  using (
    exists (
      select 1
      from public.comments c
      join public.posts p on p.id = c.post_id
      where c.id = comment_reactions.comment_id
        and (
          p.user_id = auth.uid()
          or (p.deleted_at is null and not p.is_archived)
        )
    )
  );

drop policy if exists comment_reactions_insert_own on public.comment_reactions;
create policy comment_reactions_insert_own
  on public.comment_reactions
  for insert
  to authenticated
  with check (
    auth.uid() = user_id
    and exists (
      select 1
      from public.comments c
      join public.posts p on p.id = c.post_id
      where c.id = comment_reactions.comment_id
        and (
          p.user_id = auth.uid()
          or (p.deleted_at is null and not p.is_archived)
        )
    )
  );

drop policy if exists comment_reactions_update_own on public.comment_reactions;
create policy comment_reactions_update_own
  on public.comment_reactions
  for update
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists comment_reactions_delete_own on public.comment_reactions;
create policy comment_reactions_delete_own
  on public.comment_reactions
  for delete
  to authenticated
  using (auth.uid() = user_id);

grant select on public.comment_reactions to anon;
grant select, insert, update, delete on public.comment_reactions to authenticated;
