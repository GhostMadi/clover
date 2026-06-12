-- Двусторонняя связь пост ↔ маркер:
-- - markers.post_id  → на какой пост «ссылается» маркер (уже было)
-- - posts.marker_id → обратная ссылка с поста на маркер (восстанавливаем)

-- --------------------------------------------------------------------------- Schema
alter table public.posts
  add column if not exists marker_id uuid null references public.markers (id) on delete set null;

-- Один пост на маркер (два разных поста с одним marker_id нельзя)
create unique index if not exists posts_marker_id_unique
  on public.posts (marker_id)
  where marker_id is not null;

create index if not exists posts_marker_id_idx
  on public.posts (marker_id)
  where marker_id is not null and deleted_at is null;

comment on column public.posts.marker_id is
  'Обратная ссылка на маркер; дублирует связь markers.post_id для удобства запросов с поста.';

-- Синхронизировать существующие пары: markers.post_id → posts.marker_id
update public.posts p
set marker_id = m.id
from public.markers m
where m.post_id = p.id
  and (p.marker_id is null or p.marker_id <> m.id);

-- --------------------------------------------------------------------------- RLS: marker_id только на свой маркер
drop policy if exists posts_insert_author on public.posts;
create policy posts_insert_author
  on public.posts
  for insert
  to authenticated
  with check (
    user_id = auth.uid()
    and (
      cluster_id is null
      or exists (
        select 1 from public.clusters c
        where c.id = cluster_id
          and c.owner_id = auth.uid()
      )
    )
    and (
      marker_id is null
      or exists (
        select 1
        from public.markers m
        where m.id = marker_id
          and m.owner_id = auth.uid()
      )
    )
  );

drop policy if exists posts_update_author on public.posts;
create policy posts_update_author
  on public.posts
  for update
  to authenticated
  using (user_id = auth.uid())
  with check (
    user_id = auth.uid()
    and (
      cluster_id is null
      or exists (
        select 1 from public.clusters c
        where c.id = cluster_id
          and c.owner_id = auth.uid()
      )
    )
    and (
      marker_id is null
      or exists (
        select 1
        from public.markers m
        where m.id = marker_id
          and m.owner_id = auth.uid()
      )
    )
  );
