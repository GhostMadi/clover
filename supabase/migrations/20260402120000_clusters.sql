-- Только таблица кластеров (коллекций). Таблица cluster_saves пока не создаётся.
-- Требуется существующая таблица public.profiles (id uuid).
--
-- Операционные нюансы (не решаются этим файлом целиком):
--
-- 1) Storage и cover_url
--    При DELETE кластера строка исчезает, объект в Storage сам не удалится. Без Edge: из клиента
--    (Flutter) — сначала storage.remove([path]), затем DELETE строки; нужен объектный path в бакете.
--    Иначе: Edge / Webhook / периодическая чистка. Удобный путь загрузки: {owner_id}/{cluster_id}/...
--
-- 2) posts_count
--    Счётчик НЕ обновляется из этого файла. Он поддерживается триггерами на таблице public.posts
--    в миграции 20260402140000_posts_post_media_engagement.sql (функции posts_sync_cluster_posts_count,
--    posts_sync_cluster_on_soft_delete). Клиенту не нужно вручную инкрементить clusters.posts_count.
--
-- 3) Индекс (owner_id, sort_order)
--    При Reorderable List обновляется несколько sort_order подряд — B-tree перестраивается; для десятков/
--    сотен кластеров на пользователя это обычно терпимо. При экстремальных объёмах — батчить перестановку
--    или пересчитывать порядок реже (редкий кейс).

-- --------------------------------------------------------------------------- clusters
create table if not exists public.clusters (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null
    references public.profiles (id) on delete cascade,
  title text not null,
  subtitle text null,
  cover_url text null,
  posts_count integer not null default 0
    constraint clusters_posts_count_non_negative check (posts_count >= 0),
  sort_order integer not null default 0,
  is_archived boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint clusters_title_not_blank check (char_length(trim(title)) > 0)
);

create index if not exists clusters_owner_id_idx
  on public.clusters (owner_id);

create index if not exists clusters_owner_sort_idx
  on public.clusters (owner_id, sort_order);

comment on index public.clusters_owner_sort_idx is
  'Список кластеров владельца по порядку; при массовом изменении sort_order индекс обновляется — норма для типичных объёмов';

comment on table public.clusters is 'Коллекции постов на профиле; см. миграцию posts: триггеры на posts обновляют posts_count';
comment on column public.clusters.owner_id is 'Создатель кластера (profiles.id)';
comment on column public.clusters.cover_url is 'Публичный URL обложки; при удалении кластера объект в Storage не удаляется сам по себе — см. комментарий в шапке миграции';
comment on column public.clusters.posts_count is 'Денормализация; синхронизируется триггерами на public.posts (другая миграция), не вручную из приложения';
comment on column public.clusters.sort_order is 'Порядок карточек; массовый reorder трогает индекс (owner_id, sort_order) — при очень больших списках см. шапку миграции';

-- --------------------------------------------------------------------------- updated_at
create or replace function public.clusters_set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

drop trigger if exists trg_clusters_set_updated_at on public.clusters;
create trigger trg_clusters_set_updated_at
  before update on public.clusters
  for each row
  execute function public.clusters_set_updated_at();

-- --------------------------------------------------------------------------- profiles.cluster_count (active clusters)
--
-- cluster_count в профиле — количество НЕархивированных кластеров.
-- Триггеры учитывают insert/delete и смену is_archived / owner_id.
create or replace function public.profiles_apply_cluster_count_delta(p_profile_id uuid, p_delta integer)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.profiles
  set cluster_count = greatest(cluster_count + p_delta, 0)
  where id = p_profile_id;
end;
$$;

create or replace function public.clusters_sync_profile_cluster_count()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if (tg_op = 'INSERT') then
    if (new.is_archived = false) then
      perform public.profiles_apply_cluster_count_delta(new.owner_id, 1);
    end if;
    return new;
  end if;

  if (tg_op = 'DELETE') then
    if (old.is_archived = false) then
      perform public.profiles_apply_cluster_count_delta(old.owner_id, -1);
    end if;
    return old;
  end if;

  -- UPDATE
  if (old.owner_id is distinct from new.owner_id) then
    if (old.is_archived = false) then
      perform public.profiles_apply_cluster_count_delta(old.owner_id, -1);
    end if;
    if (new.is_archived = false) then
      perform public.profiles_apply_cluster_count_delta(new.owner_id, 1);
    end if;
    return new;
  end if;

  if (old.is_archived is distinct from new.is_archived) then
    if (old.is_archived = false and new.is_archived = true) then
      perform public.profiles_apply_cluster_count_delta(new.owner_id, -1);
    elsif (old.is_archived = true and new.is_archived = false) then
      perform public.profiles_apply_cluster_count_delta(new.owner_id, 1);
    end if;
  end if;

  return new;
end;
$$;

drop trigger if exists trg_clusters_sync_profile_cluster_count on public.clusters;
create trigger trg_clusters_sync_profile_cluster_count
  after insert or update or delete on public.clusters
  for each row
  execute function public.clusters_sync_profile_cluster_count();

-- --------------------------------------------------------------------------- RLS
alter table public.clusters enable row level security;

drop policy if exists clusters_select_visible on public.clusters;
create policy clusters_select_visible
  on public.clusters
  for select
  to anon, authenticated
  using (not is_archived or owner_id = auth.uid());

drop policy if exists clusters_insert_owner on public.clusters;
create policy clusters_insert_owner
  on public.clusters
  for insert
  to authenticated
  with check (owner_id = (select auth.uid()));

drop policy if exists clusters_update_owner on public.clusters;
create policy clusters_update_owner
  on public.clusters
  for update
  to authenticated
  using (owner_id = (select auth.uid()))
  with check (owner_id = (select auth.uid()));

drop policy if exists clusters_delete_owner on public.clusters;
create policy clusters_delete_owner
  on public.clusters
  for delete
  to authenticated
  using (owner_id = (select auth.uid()));

-- --------------------------------------------------------------------------- Grants (PostgREST / клиент)
grant select on public.clusters to anon;
grant select, insert, update, delete on public.clusters to authenticated;

-- --------------------------------------------------------------------------- Storage bucket + policies for clusters.cover_url (cluster_covers)
-- Path convention: {auth.uid()}/{cluster_id}/cover.jpg
--
-- Важно: удаление объекта Storage при DELETE кластера делается из клиента (Flutter):
-- storage.remove([path]) → затем delete row. Upsert в тот же path при обновлении обложки.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
  (
    'cluster_covers',
    'cluster_covers',
    true,
    10485760,
    array['image/jpeg', 'image/png', 'image/webp']::text[]
  )
on conflict (id) do update
set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists cluster_covers_public_read on storage.objects;
drop policy if exists cluster_covers_write_own on storage.objects;
drop policy if exists cluster_covers_update_own on storage.objects;
drop policy if exists cluster_covers_delete_own on storage.objects;

create policy cluster_covers_public_read
  on storage.objects
  for select to public
  using (bucket_id = 'cluster_covers');

create policy cluster_covers_write_own
  on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'cluster_covers'
    and (storage.foldername(name))[1] = (select auth.uid()::text)
  );

create policy cluster_covers_update_own
  on storage.objects
  for update to authenticated
  using (
    bucket_id = 'cluster_covers'
    and (storage.foldername(name))[1] = (select auth.uid()::text)
  )
  with check (
    bucket_id = 'cluster_covers'
    and (storage.foldername(name))[1] = (select auth.uid()::text)
  );

create policy cluster_covers_delete_own
  on storage.objects
  for delete to authenticated
  using (
    bucket_id = 'cluster_covers'
    and (storage.foldername(name))[1] = (select auth.uid()::text)
  );
