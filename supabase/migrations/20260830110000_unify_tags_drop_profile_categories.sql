-- Unify profile categories into marker_tags (single tag dictionary).

-- --------------------------------------------------------------------------- type tags (ex profile_categories)
insert into public.marker_tags (key, group_key)
values
  ('salon', 'type'),
  ('barbershop', 'type'),
  ('music', 'type'),
  ('sports', 'type'),
  ('food', 'type'),
  ('tech', 'type'),
  ('store', 'type')
on conflict (key) do update
set group_key = excluded.group_key;

comment on table public.marker_tags is
  'Единый справочник тегов: профиль, маркеры, фильтры (key + group_key).';

-- --------------------------------------------------------------------------- migrate profiles.category_code → profile_tag_links
do $$
declare
  r record;
  v_tag_id uuid;
  v_link_id uuid;
  v_tag_ids uuid[];
begin
  for r in
    select p.id as profile_id, p.tag_link_id, p.category_code
    from public.profiles p
    where p.category_code is not null
      and trim(p.category_code) <> ''
  loop
    select t.id into v_tag_id
    from public.marker_tags t
    where t.key = trim(r.category_code);

    if v_tag_id is null then
      continue;
    end if;

    if r.tag_link_id is null then
      insert into public.profile_tag_links (tag_ids)
      values (array[v_tag_id])
      returning id into v_link_id;

      update public.profiles
      set tag_link_id = v_link_id
      where id = r.profile_id;
    else
      select tag_ids into v_tag_ids
      from public.profile_tag_links
      where id = r.tag_link_id;

      if v_tag_ids is null then
        v_tag_ids := array[]::uuid[];
      end if;

      if not (v_tag_id = any (v_tag_ids)) then
        update public.profile_tag_links
        set tag_ids = array_append(v_tag_ids, v_tag_id)
        where id = r.tag_link_id;
      end if;
    end if;
  end loop;
end $$;

-- View expands p.* at creation time — drop before removing category_code.
drop view if exists public.profiles_with_sync_meta;

alter table public.profiles drop column if exists category_code;

drop table if exists public.profile_categories;

-- --------------------------------------------------------------------------- sync_meta: only countries, cities, tags
alter table public.sync_meta drop column if exists categories;

update public.sync_meta
set
  tags = 'v' || (coalesce(nullif(substring(tags from '^v(\d+)$'), ''), '0')::int + 1)::text,
  updated_at = now()
where id = 1;

create or replace function public.sync_meta_payload()
returns jsonb
language sql
stable
security definer
set search_path = public
as $$
  select jsonb_build_object(
    'countries', sm.countries,
    'cities', sm.cities,
    'tags', sm.tags
  )
  from public.sync_meta sm
  where sm.id = 1;
$$;

comment on function public.sync_meta_payload() is
  'Global dictionary version stamps as JSON for embedding in profile responses';

create view public.profiles_with_sync_meta
with (security_invoker = true)
as
select
  p.*,
  public.sync_meta_payload() as sync_meta
from public.profiles p;

comment on view public.profiles_with_sync_meta is
  'profiles + embedded global sync_meta (same for all rows)';

grant select on public.profiles_with_sync_meta to anon, authenticated;

notify pgrst, 'reload schema';
