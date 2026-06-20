-- Теги аккаунта: одна ссылка на профиле → набор tag_ids (фильтр: tag_link_id is not null).

drop table if exists public.profile_tag_links cascade;

create table public.profile_tag_links (
  id uuid primary key default gen_random_uuid(),
  tag_ids uuid[] not null default '{}',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint profile_tag_links_tag_ids_not_empty check (cardinality(tag_ids) > 0)
);

comment on table public.profile_tag_links is
  'Набор id из marker_tags для одного профиля. profiles.tag_link_id ссылается сюда.';

create index if not exists profile_tag_links_tag_ids_gin_idx
  on public.profile_tag_links using gin (tag_ids);

alter table public.profiles
  add column if not exists tag_link_id uuid references public.profile_tag_links (id) on delete set null;

comment on column public.profiles.tag_link_id is
  'Ссылка на набор тегов аккаунта. NULL — тегов нет; фильтр «с тегами»: tag_link_id is not null.';

create index if not exists profiles_tag_link_id_not_null_idx
  on public.profiles (tag_link_id)
  where tag_link_id is not null;

alter table public.profile_tag_links enable row level security;

drop policy if exists profile_tag_links_select_all on public.profile_tag_links;
create policy profile_tag_links_select_all
  on public.profile_tag_links
  for select
  to anon, authenticated
  using (true);

drop policy if exists profile_tag_links_insert_own on public.profile_tag_links;
create policy profile_tag_links_insert_own
  on public.profile_tag_links
  for insert
  to authenticated
  with check (true);

drop policy if exists profile_tag_links_update_own on public.profile_tag_links;
create policy profile_tag_links_update_own
  on public.profile_tag_links
  for update
  to authenticated
  using (
    exists (
      select 1
      from public.profiles p
      where p.tag_link_id = profile_tag_links.id
        and p.id = auth.uid()
    )
  )
  with check (
    exists (
      select 1
      from public.profiles p
      where p.tag_link_id = profile_tag_links.id
        and p.id = auth.uid()
    )
  );

drop policy if exists profile_tag_links_delete_own on public.profile_tag_links;
create policy profile_tag_links_delete_own
  on public.profile_tag_links
  for delete
  to authenticated
  using (
    exists (
      select 1
      from public.profiles p
      where p.tag_link_id = profile_tag_links.id
        and p.id = auth.uid()
    )
  );

grant select on public.profile_tag_links to anon, authenticated;
grant insert, update, delete on public.profile_tag_links to authenticated;

-- Обновление profiles.tag_link_id — только свой профиль (стандартная RLS profiles).

create or replace function public.sync_profile_tag_link(p_tag_ids uuid[])
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_link_id uuid;
  v_normalized uuid[];
begin
  if v_uid is null then
    raise exception 'not authenticated';
  end if;

  select coalesce(array_agg(distinct t order by t), '{}'::uuid[])
  into v_normalized
  from unnest(coalesce(p_tag_ids, '{}'::uuid[])) as t
  where t is not null;

  select tag_link_id into v_link_id from public.profiles where id = v_uid for update;

  if cardinality(v_normalized) = 0 then
    if v_link_id is not null then
      update public.profiles set tag_link_id = null where id = v_uid;
      delete from public.profile_tag_links where id = v_link_id;
    end if;
    return null;
  end if;

  if v_link_id is null then
    insert into public.profile_tag_links (tag_ids)
    values (v_normalized)
    returning id into v_link_id;

    update public.profiles set tag_link_id = v_link_id where id = v_uid;
  else
    update public.profile_tag_links
    set tag_ids = v_normalized,
        updated_at = now()
    where id = v_link_id;
  end if;

  return v_link_id;
end;
$$;

revoke all on function public.sync_profile_tag_link(uuid[]) from public;
grant execute on function public.sync_profile_tag_link(uuid[]) to authenticated;

comment on function public.sync_profile_tag_link(uuid[]) is
  'Создаёт/обновляет/удаляет profile_tag_links для текущего пользователя и выставляет profiles.tag_link_id.';
