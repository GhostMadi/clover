-- clusters.posts_count: только не удалённые и не архивированные посты;
-- посты с архивированным маркером (ивент) тоже не считаются.

comment on column public.clusters.posts_count is
  'Посты в кластере: cluster_id задан, deleted_at is null, posts.is_archived = false, маркер (если есть) не архивирован';

create or replace function public.post_row_counts_toward_cluster_posts_count(
  p_post_id uuid,
  p_deleted_at timestamptz,
  p_is_archived boolean,
  p_cluster_id uuid
)
returns boolean
language sql
stable
as $$
  select p_cluster_id is not null
    and p_deleted_at is null
    and not p_is_archived
    and not exists (
      select 1
      from public.marker_posts mp
      inner join public.markers m on m.id = mp.marker_id
      where mp.post_id = p_post_id
        and m.is_archived = true
    );
$$;

create or replace function public.clusters_apply_posts_count_delta(p_cluster_id uuid, p_delta integer)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if p_cluster_id is null or p_delta = 0 then
    return;
  end if;
  update public.clusters
  set posts_count = greatest(posts_count + p_delta, 0)
  where id = p_cluster_id;
end;
$$;

create or replace function public.posts_sync_cluster_posts_count()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  old_live boolean;
  new_live boolean;
  old_c uuid;
  new_c uuid;
begin
  if tg_op = 'INSERT' then
    if public.post_row_counts_toward_cluster_posts_count(
      new.id, new.deleted_at, new.is_archived, new.cluster_id
    ) then
      perform public.clusters_apply_posts_count_delta(new.cluster_id, 1);
    end if;
    return new;

  elsif tg_op = 'DELETE' then
    if public.post_row_counts_toward_cluster_posts_count(
      old.id, old.deleted_at, old.is_archived, old.cluster_id
    ) then
      perform public.clusters_apply_posts_count_delta(old.cluster_id, -1);
    end if;
    return old;

  elsif tg_op = 'UPDATE' then
    old_live := public.post_row_counts_toward_cluster_posts_count(
      old.id, old.deleted_at, old.is_archived, old.cluster_id
    );
    new_live := public.post_row_counts_toward_cluster_posts_count(
      new.id, new.deleted_at, new.is_archived, new.cluster_id
    );
    old_c := old.cluster_id;
    new_c := new.cluster_id;

    if old_c is distinct from new_c then
      if old_live and old_c is not null then
        perform public.clusters_apply_posts_count_delta(old_c, -1);
      end if;
      if new_live and new_c is not null then
        perform public.clusters_apply_posts_count_delta(new_c, 1);
      end if;
      return new;
    end if;

    if new_c is not null and old_live is distinct from new_live then
      if old_live and not new_live then
        perform public.clusters_apply_posts_count_delta(new_c, -1);
      elsif not old_live and new_live then
        perform public.clusters_apply_posts_count_delta(new_c, 1);
      end if;
    end if;
    return new;
  end if;

  return null;
end;
$$;

create or replace function public.markers_sync_cluster_posts_count_on_archive()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if old.is_archived is not distinct from new.is_archived then
    return new;
  end if;

  if old.is_archived = false and new.is_archived = true then
    update public.clusters c
    set posts_count = greatest(0, c.posts_count - sub.cnt)
    from (
      select p.cluster_id as cid, count(*)::integer as cnt
      from public.marker_posts mp
      inner join public.posts p on p.id = mp.post_id
      where mp.marker_id = new.id
        and p.cluster_id is not null
        and p.deleted_at is null
        and not p.is_archived
      group by p.cluster_id
    ) sub
    where c.id = sub.cid;
  elsif old.is_archived = true and new.is_archived = false then
    update public.clusters c
    set posts_count = c.posts_count + sub.cnt
    from (
      select p.cluster_id as cid, count(*)::integer as cnt
      from public.marker_posts mp
      inner join public.posts p on p.id = mp.post_id
      where mp.marker_id = new.id
        and p.cluster_id is not null
        and p.deleted_at is null
        and not p.is_archived
      group by p.cluster_id
    ) sub
    where c.id = sub.cid;
  end if;

  return new;
end;
$$;

drop trigger if exists trg_posts_cluster_soft_delete on public.posts;
drop function if exists public.posts_sync_cluster_on_soft_delete();

drop trigger if exists trg_posts_cluster_count_upd on public.posts;
create trigger trg_posts_cluster_count_upd
  after update of cluster_id, deleted_at, is_archived on public.posts
  for each row
  execute function public.posts_sync_cluster_posts_count();

drop trigger if exists trg_markers_cluster_posts_count_archive on public.markers;
create trigger trg_markers_cluster_posts_count_archive
  after update of is_archived on public.markers
  for each row
  execute function public.markers_sync_cluster_posts_count_on_archive();

-- Пересчёт для существующих кластеров
update public.clusters c
set posts_count = coalesce(
  (
    select count(*)::integer
    from public.posts p
    where p.cluster_id = c.id
      and p.deleted_at is null
      and not p.is_archived
      and not exists (
        select 1
        from public.marker_posts mp
        inner join public.markers m on m.id = mp.marker_id
        where mp.post_id = p.id
          and m.is_archived = true
      )
  ),
  0
);

notify pgrst, 'reload schema';
