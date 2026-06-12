-- Денормализация: число «живых» постов автора в ленте профиля (как posts_user_feed_idx:
-- deleted_at is null and is_archived = false). Обновляется только триггерами на public.posts.

alter table public.profiles
  add column post_count integer not null default 0
    constraint profiles_post_count_non_negative check (post_count >= 0);

comment on column public.profiles.post_count is
  'Посты в публичной сетке: не удалены (deleted_at is null) и не в архиве (is_archived = false); триггеры на posts';

-- Пересчёт для существующих строк
update public.profiles p
set post_count = (
  select count(*)::integer
  from public.posts po
  where po.user_id = p.id
    and po.deleted_at is null
    and po.is_archived = false
);

-- --------------------------------------------------------------------------- helpers + триггер

create or replace function public.profiles_apply_post_count_delta(p_profile_id uuid, p_delta integer)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if p_delta = 0 then
    return;
  end if;
  update public.profiles
  set post_count = greatest(post_count + p_delta, 0)
  where id = p_profile_id;
end;
$$;

create or replace function public.post_row_counts_toward_profile_post_count(p_deleted_at timestamptz, p_is_archived boolean)
returns boolean
language plpgsql
immutable
as $$
begin
  return p_deleted_at is null and not p_is_archived;
end;
$$;

create or replace function public.posts_sync_profile_post_count()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  old_live boolean;
  new_live boolean;
begin
  if tg_op = 'INSERT' then
    if public.post_row_counts_toward_profile_post_count(new.deleted_at, new.is_archived) then
      perform public.profiles_apply_post_count_delta(new.user_id, 1);
    end if;
    return new;

  elsif tg_op = 'DELETE' then
    if public.post_row_counts_toward_profile_post_count(old.deleted_at, old.is_archived) then
      perform public.profiles_apply_post_count_delta(old.user_id, -1);
    end if;
    return old;

  elsif tg_op = 'UPDATE' then
    old_live := public.post_row_counts_toward_profile_post_count(old.deleted_at, old.is_archived);
    new_live := public.post_row_counts_toward_profile_post_count(new.deleted_at, new.is_archived);

    if old.user_id is distinct from new.user_id then
      if old_live then
        perform public.profiles_apply_post_count_delta(old.user_id, -1);
      end if;
      if new_live then
        perform public.profiles_apply_post_count_delta(new.user_id, 1);
      end if;
      return new;
    end if;

    if old_live is distinct from new_live then
      if old_live and not new_live then
        perform public.profiles_apply_post_count_delta(new.user_id, -1);
      elsif not old_live and new_live then
        perform public.profiles_apply_post_count_delta(new.user_id, 1);
      end if;
    end if;
    return new;
  end if;

  return null;
end;
$$;

drop trigger if exists trg_posts_sync_profile_post_count on public.posts;
create trigger trg_posts_sync_profile_post_count
  after insert or delete or update of is_archived, deleted_at, user_id on public.posts
  for each row
  execute function public.posts_sync_profile_post_count();
