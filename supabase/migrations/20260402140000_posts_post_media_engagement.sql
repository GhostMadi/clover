-- Посты, медиа-строки, комментарии, лайки, сохранения постов.
-- Зависимости: public.profiles, public.clusters (миграция clusters).

-- Тип медиа (расширение: ALTER TYPE ... ADD VALUE)
do $$
begin
  create type public.media_type as enum ('image', 'video');
exception
  when duplicate_object then null;
end $$;

-- --------------------------------------------------------------------------- posts
create table if not exists public.posts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null
    references public.profiles (id) on delete cascade,
  cluster_id uuid null
    references public.clusters (id) on delete set null,
  title text null,
  subtitle text null,
  description text null,
  is_archived boolean not null default false,
  deleted_at timestamptz null,
  likes_count integer not null default 0
    constraint posts_likes_count_non_negative check (likes_count >= 0),
  comments_count integer not null default 0
    constraint posts_comments_count_non_negative check (comments_count >= 0),
  saves_count integer not null default 0
    constraint posts_saves_count_non_negative check (saves_count >= 0),
  sends_count integer not null default 0
    constraint posts_sends_count_non_negative check (sends_count >= 0),
  views_count integer not null default 0
    constraint posts_views_count_non_negative check (views_count >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists posts_user_id_idx on public.posts (user_id);
create index if not exists posts_cluster_id_idx on public.posts (cluster_id);
create index if not exists posts_created_at_desc_idx on public.posts (created_at desc);

-- Лента: только опубликованные «живые» посты (без архива и без soft delete)
create index if not exists posts_feed_idx
  on public.posts (created_at desc)
  where is_archived = false and deleted_at is null;

-- Лента кластера: ускоряет выборку постов конкретного кластера по времени.
create index if not exists posts_cluster_feed_idx
  on public.posts (cluster_id, created_at desc)
  where cluster_id is not null and is_archived = false and deleted_at is null;

-- Лента профиля (публичная): посты конкретного автора по времени.
create index if not exists posts_user_feed_idx
  on public.posts (user_id, created_at desc)
  where is_archived = false and deleted_at is null;

comment on table public.posts is 'Пост; медиа в post_media; счётчики денормализованы триггерами';
comment on column public.posts.cluster_id is 'Коллекция; null — пост без кластера';
comment on column public.posts.deleted_at is 'Soft delete; отличие от is_archived — скрытие из ленты / откат; не триггерить массово views_count';
comment on column public.posts.sends_count is '«Поделились»; без отдельной таблицы событий — обновление с клиента/джобы';
comment on column public.posts.views_count is 'Денормализация; накопливать событиями + batch/cron, не UPDATE на каждый просмотр (см. docs/clusters-posts-orientation.md §2.2b)';

-- --------------------------------------------------------------------------- post_media
create table if not exists public.post_media (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null
    references public.posts (id) on delete cascade,
  url text not null
    constraint post_media_url_not_blank check (char_length(trim(url)) > 0),
  type public.media_type not null,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  constraint post_media_post_sort_unique unique (post_id, sort_order)
);

create index if not exists post_media_type_idx on public.post_media (type);

comment on table public.post_media is 'Кадры поста; UNIQUE(post_id, sort_order) даёт индекс для порядка; расширение: thumbnail и т.д.';
comment on column public.post_media.type is 'public.media_type; новые значения — ALTER TYPE ... ADD VALUE';

-- --------------------------------------------------------------------------- comments
create table if not exists public.comments (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null
    references public.posts (id) on delete cascade,
  user_id uuid not null
    references public.profiles (id) on delete cascade,
  text text not null
    constraint comments_text_not_blank check (char_length(trim(text)) > 0)
    constraint comments_text_max_len check (char_length(text) <= 2000),
  parent_comment_id uuid null
    references public.comments (id) on delete cascade,
  likes_count integer not null default 0
    constraint comments_likes_count_non_negative check (likes_count >= 0),
  created_at timestamptz not null default now(),
  edited_at timestamptz null,
  is_deleted boolean not null default false
);

create index if not exists comments_post_id_idx on public.comments (post_id);
-- Дерево комментариев в рамках поста
create index if not exists comments_tree_idx on public.comments (post_id, parent_comment_id);

comment on table public.comments is 'Дерево через parent_comment_id; is_deleted — soft delete';

create or replace function public.comments_enforce_parent_same_post()
returns trigger
language plpgsql
as $$
begin
  if new.parent_comment_id is not null then
    if not exists (
      select 1 from public.comments pc
      where pc.id = new.parent_comment_id
        and pc.post_id = new.post_id
    ) then
      raise exception 'parent_comment_id must reference a comment on the same post';
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists trg_comments_parent_same_post on public.comments;
create trigger trg_comments_parent_same_post
  before insert or update of parent_comment_id, post_id on public.comments
  for each row
  execute function public.comments_enforce_parent_same_post();

-- --------------------------------------------------------------------------- post_likes (PK составной — без лишнего id)
create table if not exists public.post_likes (
  post_id uuid not null
    references public.posts (id) on delete cascade,
  user_id uuid not null
    references public.profiles (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (post_id, user_id)
);

create index if not exists post_likes_user_id_idx on public.post_likes (user_id);
create index if not exists post_likes_post_id_idx on public.post_likes (post_id);

-- --------------------------------------------------------------------------- comment_likes
create table if not exists public.comment_likes (
  comment_id uuid not null
    references public.comments (id) on delete cascade,
  user_id uuid not null
    references public.profiles (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (comment_id, user_id)
);

create index if not exists comment_likes_user_id_idx on public.comment_likes (user_id);
create index if not exists comment_likes_comment_id_idx on public.comment_likes (comment_id);

-- --------------------------------------------------------------------------- post_saves (для денормализации posts.saves_count)
create table if not exists public.post_saves (
  post_id uuid not null
    references public.posts (id) on delete cascade,
  user_id uuid not null
    references public.profiles (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (post_id, user_id)
);

create index if not exists post_saves_user_id_idx on public.post_saves (user_id);
create index if not exists post_saves_post_id_idx on public.post_saves (post_id);

-- --------------------------------------------------------------------------- posts.updated_at
create or replace function public.posts_set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

drop trigger if exists trg_posts_set_updated_at on public.posts;
create trigger trg_posts_set_updated_at
  before update of title, subtitle, description, cluster_id, is_archived, deleted_at on public.posts
  for each row
  execute function public.posts_set_updated_at();

-- --------------------------------------------------------------------------- Denormalized counts: SECURITY DEFINER (обход RLS на родительских строках)
create or replace function public.post_likes_sync_post_count()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if tg_op = 'INSERT' then
    update public.posts set likes_count = likes_count + 1 where id = new.post_id;
    return new;
  elsif tg_op = 'DELETE' then
    update public.posts set likes_count = greatest(0, likes_count - 1) where id = old.post_id;
    return old;
  end if;
  return null;
end;
$$;

drop trigger if exists trg_post_likes_count_ins on public.post_likes;
create trigger trg_post_likes_count_ins
  after insert on public.post_likes
  for each row
  execute function public.post_likes_sync_post_count();

drop trigger if exists trg_post_likes_count_del on public.post_likes;
create trigger trg_post_likes_count_del
  after delete on public.post_likes
  for each row
  execute function public.post_likes_sync_post_count();

create or replace function public.post_saves_sync_post_count()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if tg_op = 'INSERT' then
    update public.posts set saves_count = saves_count + 1 where id = new.post_id;
    return new;
  elsif tg_op = 'DELETE' then
    update public.posts set saves_count = greatest(0, saves_count - 1) where id = old.post_id;
    return old;
  end if;
  return null;
end;
$$;

drop trigger if exists trg_post_saves_count_ins on public.post_saves;
create trigger trg_post_saves_count_ins
  after insert on public.post_saves
  for each row
  execute function public.post_saves_sync_post_count();

drop trigger if exists trg_post_saves_count_del on public.post_saves;
create trigger trg_post_saves_count_del
  after delete on public.post_saves
  for each row
  execute function public.post_saves_sync_post_count();

create or replace function public.comment_likes_sync_comment_count()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if tg_op = 'INSERT' then
    update public.comments set likes_count = likes_count + 1 where id = new.comment_id;
    return new;
  elsif tg_op = 'DELETE' then
    update public.comments set likes_count = greatest(0, likes_count - 1) where id = old.comment_id;
    return old;
  end if;
  return null;
end;
$$;

drop trigger if exists trg_comment_likes_count_ins on public.comment_likes;
create trigger trg_comment_likes_count_ins
  after insert on public.comment_likes
  for each row
  execute function public.comment_likes_sync_comment_count();

drop trigger if exists trg_comment_likes_count_del on public.comment_likes;
create trigger trg_comment_likes_count_del
  after delete on public.comment_likes
  for each row
  execute function public.comment_likes_sync_comment_count();

create or replace function public.comments_sync_post_comments_count()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if tg_op = 'INSERT' then
    if new.parent_comment_id is null and not new.is_deleted then
      update public.posts set comments_count = comments_count + 1 where id = new.post_id;
    end if;
    return new;
  elsif tg_op = 'UPDATE' then
    if new.parent_comment_id is null and old.is_deleted is distinct from new.is_deleted then
      if new.is_deleted then
        update public.posts set comments_count = greatest(0, comments_count - 1) where id = new.post_id;
      else
        update public.posts set comments_count = comments_count + 1 where id = new.post_id;
      end if;
    end if;
    return new;
  elsif tg_op = 'DELETE' then
    if old.parent_comment_id is null and not old.is_deleted then
      update public.posts set comments_count = greatest(0, comments_count - 1) where id = old.post_id;
    end if;
    return old;
  end if;
  return null;
end;
$$;

drop trigger if exists trg_comments_sync_count_ins on public.comments;
create trigger trg_comments_sync_count_ins
  after insert on public.comments
  for each row
  execute function public.comments_sync_post_comments_count();

drop trigger if exists trg_comments_sync_count_upd on public.comments;
create trigger trg_comments_sync_count_upd
  after update of is_deleted on public.comments
  for each row
  execute function public.comments_sync_post_comments_count();

drop trigger if exists trg_comments_sync_count_del on public.comments;
create trigger trg_comments_sync_count_del
  after delete on public.comments
  for each row
  execute function public.comments_sync_post_comments_count();

-- --------------------------------------------------------------------------- clusters.posts_count (учёт только «живых» постов в кластере, без soft-deleted)
create or replace function public.posts_sync_cluster_posts_count()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  old_c uuid;
  new_c uuid;
begin
  if tg_op = 'INSERT' then
    if new.deleted_at is null and new.cluster_id is not null then
      update public.clusters set posts_count = posts_count + 1 where id = new.cluster_id;
    end if;
    return new;
  elsif tg_op = 'DELETE' then
    -- при soft delete счётчик уже уменьшен; уменьшаем только если пост ещё был в ленте кластера
    if old.deleted_at is null and old.cluster_id is not null then
      update public.clusters set posts_count = greatest(0, posts_count - 1) where id = old.cluster_id;
    end if;
    return old;
  elsif tg_op = 'UPDATE' then
    old_c := old.cluster_id;
    new_c := new.cluster_id;
    -- перенос между кластерами только пока пост не в soft delete
    if old.deleted_at is null and new.deleted_at is null and old_c is distinct from new_c then
      if old_c is not null then
        update public.clusters set posts_count = greatest(0, posts_count - 1) where id = old_c;
      end if;
      if new_c is not null then
        update public.clusters set posts_count = posts_count + 1 where id = new_c;
      end if;
    end if;
    return new;
  end if;
  return null;
end;
$$;

create or replace function public.posts_sync_cluster_on_soft_delete()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if old.deleted_at is not distinct from new.deleted_at then
    return new;
  end if;
  if old.deleted_at is null and new.deleted_at is not null then
    if new.cluster_id is not null then
      update public.clusters set posts_count = greatest(0, posts_count - 1) where id = new.cluster_id;
    end if;
  elsif old.deleted_at is not null and new.deleted_at is null then
    if new.cluster_id is not null then
      update public.clusters set posts_count = posts_count + 1 where id = new.cluster_id;
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists trg_posts_cluster_count_ins on public.posts;
create trigger trg_posts_cluster_count_ins
  after insert on public.posts
  for each row
  execute function public.posts_sync_cluster_posts_count();

drop trigger if exists trg_posts_cluster_count_del on public.posts;
create trigger trg_posts_cluster_count_del
  after delete on public.posts
  for each row
  execute function public.posts_sync_cluster_posts_count();

drop trigger if exists trg_posts_cluster_count_upd on public.posts;
create trigger trg_posts_cluster_count_upd
  after update of cluster_id on public.posts
  for each row
  execute function public.posts_sync_cluster_posts_count();

drop trigger if exists trg_posts_cluster_soft_delete on public.posts;
create trigger trg_posts_cluster_soft_delete
  after update of deleted_at on public.posts
  for each row
  execute function public.posts_sync_cluster_on_soft_delete();

-- --------------------------------------------------------------------------- RLS
alter table public.posts enable row level security;
alter table public.post_media enable row level security;
alter table public.comments enable row level security;
alter table public.post_likes enable row level security;
alter table public.comment_likes enable row level security;
alter table public.post_saves enable row level security;

-- posts: автор видит всё; остальные — без soft delete и без чужого архива
drop policy if exists posts_select_visible on public.posts;
create policy posts_select_visible
  on public.posts
  for select
  to anon, authenticated
  using (
    user_id = auth.uid()
    or (deleted_at is null and not is_archived)
  );

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
  );

drop policy if exists posts_delete_author on public.posts;
create policy posts_delete_author
  on public.posts
  for delete
  to authenticated
  using (user_id = auth.uid());

-- post_media: видимость как у поста; правки только автор поста
drop policy if exists post_media_select_visible on public.post_media;
create policy post_media_select_visible
  on public.post_media
  for select
  to anon, authenticated
  using (
    exists (
      select 1 from public.posts p
      where p.id = post_media.post_id
        and (
          p.user_id = auth.uid()
          or (p.deleted_at is null and not p.is_archived)
        )
    )
  );

drop policy if exists post_media_write_author on public.post_media;
create policy post_media_write_author
  on public.post_media
  for all
  to authenticated
  using (
    exists (
      select 1 from public.posts p
      where p.id = post_media.post_id
        and p.user_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1 from public.posts p
      where p.id = post_media.post_id
        and p.user_id = auth.uid()
    )
  );

-- comments
drop policy if exists comments_select_visible on public.comments;
create policy comments_select_visible
  on public.comments
  for select
  to anon, authenticated
  using (
    exists (
      select 1 from public.posts p
      where p.id = comments.post_id
        and (
          p.user_id = auth.uid()
          or (p.deleted_at is null and not p.is_archived)
        )
    )
  );

drop policy if exists comments_insert_auth on public.comments;
create policy comments_insert_auth
  on public.comments
  for insert
  to authenticated
  with check (
    user_id = auth.uid()
    and exists (
      select 1 from public.posts p
      where p.id = post_id
        and (
          p.user_id = auth.uid()
          or (p.deleted_at is null and not p.is_archived)
        )
    )
  );

drop policy if exists comments_update_own on public.comments;
create policy comments_update_own
  on public.comments
  for update
  to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

drop policy if exists comments_delete_own on public.comments;
create policy comments_delete_own
  on public.comments
  for delete
  to authenticated
  using (user_id = auth.uid());

-- post_likes: вставка/удаление только от своего user_id
drop policy if exists post_likes_select_visible on public.post_likes;
create policy post_likes_select_visible
  on public.post_likes
  for select
  to anon, authenticated
  using (
    exists (
      select 1 from public.posts p
      where p.id = post_likes.post_id
        and (
          p.user_id = auth.uid()
          or (p.deleted_at is null and not p.is_archived)
        )
    )
  );

drop policy if exists post_likes_insert_own on public.post_likes;
create policy post_likes_insert_own
  on public.post_likes
  for insert
  to authenticated
  with check (
    user_id = auth.uid()
    and exists (
      select 1 from public.posts p
      where p.id = post_id
        and (
          p.user_id = auth.uid()
          or (p.deleted_at is null and not p.is_archived)
        )
    )
  );

drop policy if exists post_likes_delete_own on public.post_likes;
create policy post_likes_delete_own
  on public.post_likes
  for delete
  to authenticated
  using (user_id = auth.uid());

-- comment_likes
drop policy if exists comment_likes_select_visible on public.comment_likes;
create policy comment_likes_select_visible
  on public.comment_likes
  for select
  to anon, authenticated
  using (
    exists (
      select 1
      from public.comments c
      join public.posts p on p.id = c.post_id
      where c.id = comment_id
        and (
          p.user_id = auth.uid()
          or (p.deleted_at is null and not p.is_archived)
        )
    )
  );

drop policy if exists comment_likes_insert_own on public.comment_likes;
create policy comment_likes_insert_own
  on public.comment_likes
  for insert
  to authenticated
  with check (
    user_id = auth.uid()
    and exists (
      select 1
      from public.comments c
      join public.posts p on p.id = c.post_id
      where c.id = comment_id
        and (
          p.user_id = auth.uid()
          or (p.deleted_at is null and not p.is_archived)
        )
    )
  );

drop policy if exists comment_likes_delete_own on public.comment_likes;
create policy comment_likes_delete_own
  on public.comment_likes
  for delete
  to authenticated
  using (user_id = auth.uid());

-- post_saves
drop policy if exists post_saves_select_own on public.post_saves;
create policy post_saves_select_own
  on public.post_saves
  for select
  to authenticated
  using (user_id = auth.uid());

drop policy if exists post_saves_insert_own on public.post_saves;
create policy post_saves_insert_own
  on public.post_saves
  for insert
  to authenticated
  with check (
    user_id = auth.uid()
    and exists (
      select 1 from public.posts p
      where p.id = post_id
        and (
          p.user_id = auth.uid()
          or (p.deleted_at is null and not p.is_archived)
        )
    )
  );

drop policy if exists post_saves_delete_own on public.post_saves;
create policy post_saves_delete_own
  on public.post_saves
  for delete
  to authenticated
  using (user_id = auth.uid());

-- --------------------------------------------------------------------------- Grants
grant select on public.posts to anon;
grant select, insert, update, delete on public.posts to authenticated;

grant select on public.post_media to anon;
grant select, insert, update, delete on public.post_media to authenticated;

grant select on public.comments to anon;
grant select, insert, update, delete on public.comments to authenticated;

grant select on public.post_likes to anon;
grant select, insert, delete on public.post_likes to authenticated;

grant select on public.comment_likes to anon;
grant select, insert, delete on public.comment_likes to authenticated;

grant select, insert, delete on public.post_saves to authenticated;

-- --------------------------------------------------------------------------- Edge Functions (where they fit)
--
-- Эта миграция покрывает "низконагруженные" действия напрямую через Supabase client + триггеры:
-- - likes:     insert/delete public.post_likes    → trigger updates posts.likes_count
-- - comments:  insert/update/delete public.comments → trigger updates posts.comments_count
-- - saves:     insert/delete public.post_saves    → trigger updates posts.saves_count
--
-- Edge Functions реально нужны только там, где:
-- - несколько шагов в одну операцию (создание поста + upload media)
-- - очень высокая частота событий (views, sends) + rate limit / антиспам / аналитика
--
-- Рекомендуемые endpoints (Supabase Edge Functions):
--
-- 1) create_post
--    POST /functions/v1/create_post
--    Делает атомарно:
--      - создаёт public.posts (user_id = auth.uid(), cluster_id валидируется)
--      - загружает файлы в Storage bucket 'post_media' по пути:
--          posts/{post_id}/{media_id}.*
--      - создаёт public.post_media (post_id, url, type, sort_order)
--
-- 2) register_post_view
--    POST /functions/v1/register_post_view
--    Пишет событие просмотра (append-only) и НЕ делает update posts.views_count на каждый view.
--    Реализация и батч-агрегация находятся в отдельной миграции:
--      supabase/migrations/20260402150000_post_view_events.sql
--
-- 3) register_post_send
--    POST /functions/v1/register_post_send
--    Пишет событие отправки/шера и обновляет posts.sends_count через триггер.
--    Реализация таблицы событий находится в:
--      supabase/migrations/20260407193000_posts_storage_views_sends.sql
