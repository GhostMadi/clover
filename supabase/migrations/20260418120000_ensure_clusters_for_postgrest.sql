  -- Ремонт: на части удалённых проектов таблица public.clusters отсутствует → PostgREST 404 на POST /rest/v1/clusters.
  -- Идемпотентно: безопасно, если объекты уже созданы старыми миграциями.

  alter table public.profiles
    add column if not exists cluster_count integer not null default 0;

  -- Для политики clusters_select_visible (как в account_state), если миграция ещё не добавила поля:
  alter table public.profiles
    add column if not exists content_visible boolean not null default true;

  alter table public.profiles
    add column if not exists account_state text not null default 'active';

  do $$
  begin
    if not exists (
      select 1 from pg_constraint
      where conname = 'profiles_cluster_count_non_negative'
    ) then
      alter table public.profiles
        add constraint profiles_cluster_count_non_negative check (cluster_count >= 0);
    end if;
  exception
    when duplicate_object then null;
  end $$;

  -- --------------------------------------------------------------------------- clusters (как в 20260402120000_clusters.sql)
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

  alter table public.clusters
    add column if not exists deleted_at timestamptz null,
    add column if not exists deleted_reason text null;

  create index if not exists clusters_owner_id_idx
    on public.clusters (owner_id);

  create index if not exists clusters_owner_sort_idx
    on public.clusters (owner_id, sort_order);

  comment on table public.clusters is 'Коллекции постов на профиле (ensure migration)';

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
  declare
    old_counts boolean;
    new_counts boolean;
  begin
    old_counts := coalesce(old.deleted_at, null) is null and old.is_archived = false;
    new_counts := coalesce(new.deleted_at, null) is null and new.is_archived = false;

    if (tg_op = 'INSERT') then
      if new_counts then
        perform public.profiles_apply_cluster_count_delta(new.owner_id, 1);
      end if;
      return new;
    end if;

    if (tg_op = 'DELETE') then
      if old_counts then
        perform public.profiles_apply_cluster_count_delta(old.owner_id, -1);
      end if;
      return old;
    end if;

    if (old.owner_id is distinct from new.owner_id) then
      if old_counts then
        perform public.profiles_apply_cluster_count_delta(old.owner_id, -1);
      end if;
      if new_counts then
        perform public.profiles_apply_cluster_count_delta(new.owner_id, 1);
      end if;
      return new;
    end if;

    if (old_counts is distinct from new_counts) then
      if old_counts and not new_counts then
        perform public.profiles_apply_cluster_count_delta(new.owner_id, -1);
      elsif not old_counts and new_counts then
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

  alter table public.clusters enable row level security;

  drop policy if exists clusters_select_visible on public.clusters;
  create policy clusters_select_visible
    on public.clusters
    for select
    to anon, authenticated
    using (
      owner_id = auth.uid()
      or (
        deleted_at is null
        and not is_archived
        and exists (
          select 1
          from public.profiles pr
          where pr.id = clusters.owner_id
            and pr.content_visible = true
            and pr.account_state <> 'hibernate'
        )
      )
    );

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

  grant select on public.clusters to anon;
  grant select, insert, update, delete on public.clusters to authenticated;

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
