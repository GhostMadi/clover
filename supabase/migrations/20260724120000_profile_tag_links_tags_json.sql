-- Денormalized JSON тегов на profile_tag_links → один PostgREST embed с labels.

alter table public.profile_tag_links
  add column if not exists tags jsonb not null default '[]'::jsonb;

comment on column public.profile_tag_links.tags is
  'Кэш marker_tags для tag_ids; поддерживается триггером.';

create or replace function public.sync_profile_tag_links_tags_json()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  new.tags := coalesce(
    (
      select jsonb_agg(
        jsonb_build_object(
          'id', t.id,
          'key', t.key,
          'group_key', t.group_key,
          'created_at', t.created_at
        )
        order by t.group_key nulls last, t.key
      )
      from unnest(coalesce(new.tag_ids, '{}'::uuid[])) as tag_id
      join public.marker_tags t on t.id = tag_id
    ),
    '[]'::jsonb
  );

  return new;
end;
$$;

drop trigger if exists profile_tag_links_sync_tags_json on public.profile_tag_links;

create trigger profile_tag_links_sync_tags_json
  before insert or update of tag_ids
  on public.profile_tag_links
  for each row
  execute function public.sync_profile_tag_links_tags_json();

-- Пересчитать tags для существующих строк.
update public.profile_tag_links
set tag_ids = tag_ids
where true;

notify pgrst, 'reload schema';
