-- Денормализация: число прямых неудалённых ответов на комментарий (для UI «Показать N ответов»).
-- Триггеры синхронизируют при insert / soft-delete / delete / смене parent.

alter table public.comments
  add column if not exists replies_count integer not null default 0
    constraint comments_replies_count_non_negative check (replies_count >= 0);

comment on column public.comments.replies_count is
  'Число прямых дочерних комментариев с is_deleted = false; обновляется триггерами.';

-- Бэкфилл существующих данных
update public.comments c
set replies_count = coalesce(
  (
    select count(*)::int
    from public.comments r
    where r.parent_comment_id = c.id
      and not r.is_deleted
  ),
  0
);

create or replace function public.comments_sync_parent_replies_count()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if tg_op = 'INSERT' then
    if new.parent_comment_id is not null and not new.is_deleted then
      update public.comments
      set replies_count = replies_count + 1
      where id = new.parent_comment_id;
    end if;
    return new;
  end if;

  if tg_op = 'UPDATE' then
    if old.parent_comment_id is distinct from new.parent_comment_id then
      if old.parent_comment_id is not null and not old.is_deleted then
        update public.comments
        set replies_count = greatest(0, replies_count - 1)
        where id = old.parent_comment_id;
      end if;
      if new.parent_comment_id is not null and not new.is_deleted then
        update public.comments
        set replies_count = replies_count + 1
        where id = new.parent_comment_id;
      end if;
      return new;
    end if;

    if old.is_deleted is distinct from new.is_deleted and new.parent_comment_id is not null then
      if new.is_deleted then
        update public.comments
        set replies_count = greatest(0, replies_count - 1)
        where id = new.parent_comment_id;
      else
        update public.comments
        set replies_count = replies_count + 1
        where id = new.parent_comment_id;
      end if;
    end if;
    return new;
  end if;

  if tg_op = 'DELETE' then
    if old.parent_comment_id is not null and not old.is_deleted then
      update public.comments
      set replies_count = greatest(0, replies_count - 1)
      where id = old.parent_comment_id;
    end if;
    return old;
  end if;

  return null;
end;
$$;

drop trigger if exists trg_comments_sync_parent_replies_ins on public.comments;
create trigger trg_comments_sync_parent_replies_ins
  after insert on public.comments
  for each row
  execute function public.comments_sync_parent_replies_count();

drop trigger if exists trg_comments_sync_parent_replies_upd on public.comments;
create trigger trg_comments_sync_parent_replies_upd
  after update of is_deleted, parent_comment_id on public.comments
  for each row
  execute function public.comments_sync_parent_replies_count();

drop trigger if exists trg_comments_sync_parent_replies_del on public.comments;
create trigger trg_comments_sync_parent_replies_del
  after delete on public.comments
  for each row
  execute function public.comments_sync_parent_replies_count();
