-- Пост: text_emoji, location (денормализация), теги (post_tag_links).
-- Обычная публикация — всё в posts; ивент — posts + markers (период отличает режим).

alter table public.posts
  add column if not exists text_emoji text null,
  add column if not exists location_id uuid null
    references public.locations (id) on delete set null,
  add column if not exists address_primary text null,
  add column if not exists address_cyrillic text null,
  add column if not exists country_code text null,
  add column if not exists city_code text null;

create index if not exists posts_location_id_idx
  on public.posts (location_id)
  where location_id is not null;

comment on column public.posts.text_emoji is 'Эмодзи публикации (для постов без маркера или дубль на посте при ивенте).';
comment on column public.posts.location_id is 'Сохранённое местоположение; адрес/город денормализуются триггером.';

-- --------------------------------------------------------------------------- post_tag_links
create table if not exists public.post_tag_links (
  post_id uuid not null
    references public.posts (id) on delete cascade,
  tag_id uuid not null
    references public.marker_tags (id) on delete cascade,
  created_at timestamptz not null default now(),
  constraint post_tag_links_pkey primary key (post_id, tag_id)
);

create index if not exists post_tag_links_tag_id_idx on public.post_tag_links (tag_id);

comment on table public.post_tag_links is
  'Теги публикации (тот же справочник marker_tags); для ивента могут дублироваться на marker_tag_links.';

-- --------------------------------------------------------------------------- Location ownership on posts (reuse markers helper)
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
    and public.posts_marker_ownership_allows(marker_id)
    and public.markers_location_ownership_allows(location_id)
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
    and public.posts_marker_ownership_allows(marker_id)
    and public.markers_location_ownership_allows(location_id)
  );

-- --------------------------------------------------------------------------- Denormalize address from locations
create or replace function public.posts_sync_location_from_location_id()
returns trigger
language plpgsql
security definer
set search_path = public
set row_security to off
as $$
declare
  v_primary text;
  v_cyrillic text;
  v_country text;
  v_city text;
begin
  if new.location_id is null then
    new.address_primary := null;
    new.address_cyrillic := null;
    new.country_code := null;
    new.city_code := null;
    return new;
  end if;

  select
    l.address_primary,
    l.address_cyrillic,
    l.country_code,
    l.city_code
  into v_primary, v_cyrillic, v_country, v_city
  from public.locations l
  where l.id = new.location_id;

  new.address_primary := nullif(trim(coalesce(v_primary, '')), '');
  new.address_cyrillic := nullif(trim(coalesce(v_cyrillic, '')), '');

  if v_country is not null and v_city is not null then
    new.country_code := lower(trim(v_country));
    new.city_code := trim(v_city);
  else
    new.country_code := null;
    new.city_code := null;
  end if;

  return new;
end;
$$;

drop trigger if exists trg_posts_sync_location_from_location_id on public.posts;
create trigger trg_posts_sync_location_from_location_id
  before insert or update of location_id
  on public.posts
  for each row
  execute function public.posts_sync_location_from_location_id();

-- --------------------------------------------------------------------------- RLS: post_tag_links
alter table public.post_tag_links enable row level security;

drop policy if exists post_tag_links_select_visible_post on public.post_tag_links;
create policy post_tag_links_select_visible_post
  on public.post_tag_links
  for select
  to anon, authenticated
  using (
    exists (
      select 1
      from public.posts p
      where p.id = post_tag_links.post_id
        and (
          p.user_id = auth.uid()
          or (p.deleted_at is null and not p.is_archived)
        )
    )
  );

drop policy if exists post_tag_links_write_post_author on public.post_tag_links;
create policy post_tag_links_write_post_author
  on public.post_tag_links
  for all
  to authenticated
  using (
    exists (
      select 1 from public.posts p
      where p.id = post_tag_links.post_id
        and p.user_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1 from public.posts p
      where p.id = post_tag_links.post_id
        and p.user_id = auth.uid()
    )
  );

grant select, insert, delete on public.post_tag_links to authenticated;
grant select on public.post_tag_links to anon;

-- --------------------------------------------------------------------------- JSON helpers for enriched feeds
create or replace function public.post_tags_json(p_post_id uuid)
returns jsonb
language sql
stable
security definer
set search_path = public
set row_security to off
as $$
  select coalesce(
    (
      select jsonb_agg(
        jsonb_build_object(
          'id', t.id,
          'key', t.key,
          'group_key', t.group_key
        )
        order by t.group_key nulls last, t.key
      )
      from public.post_tag_links l
      join public.marker_tags t on t.id = l.tag_id
      where l.post_id = p_post_id
    ),
    '[]'::jsonb
  );
$$;

comment on function public.post_tags_json(uuid) is
  'Теги поста из post_tag_links для enriched payload.';

revoke all on function public.post_tags_json(uuid) from public;
grant execute on function public.post_tags_json(uuid) to authenticated, anon;

-- --------------------------------------------------------------------------- get_post_enriched: tags on post root
drop function if exists public.get_post_enriched(uuid);

create function public.get_post_enriched(p_post_id uuid)
returns table (
  post jsonb,
  author jsonb,
  my_reaction text,
  my_saved boolean,
  my_following_author boolean
)
language sql
stable
security invoker
set search_path = public
as $fn$
  select
    (
      to_jsonb(p.*)
      || jsonb_build_object(
        'post_media',
        coalesce(
          (
            select jsonb_agg(to_jsonb(pm.*) order by pm.sort_order asc)
            from public.post_media pm
            where pm.post_id = p.id
          ),
          '[]'::jsonb
        ),
        'tags', public.post_tags_json(p.id),
        'marker',
        case
          when m.id is not null then
            jsonb_build_object(
              'id', m.id,
              'text_emoji', m.text_emoji,
              'address_primary', m.address_primary,
              'address_cyrillic', m.address_cyrillic,
              'country_code', m.country_code,
              'city_code', m.city_code,
              'event_time', m.event_time,
              'end_time', m.end_time,
              'status', m.status::text,
              'tags', coalesce(
                (
                  select jsonb_agg(
                    jsonb_build_object(
                      'id', t.id,
                      'key', t.key,
                      'group_key', t.group_key
                    )
                    order by t.group_key nulls last, t.key
                  )
                  from public.marker_tag_links l
                  join public.marker_tags t on t.id = l.tag_id
                  where l.marker_id = m.id
                ),
                '[]'::jsonb
              )
            )
          else 'null'::jsonb
        end,
        'profile_filters', public.post_profile_filters_json(p.id)
      )
    ) as post,
    public.author_mini_json(pr.id) as author,
    public.get_my_post_reaction_kind(p.id) as my_reaction,
    (ps_me.post_id is not null) as my_saved,
    (
      auth.uid() is not null
      and auth.uid() <> p.user_id
      and public.is_following_user(p.user_id)
    ) as my_following_author
  from public.posts p
  inner join public.profiles pr on pr.id = p.user_id
  left join public.markers m
    on m.id = p.marker_id
  left join public.post_saves ps_me
    on ps_me.post_id = p.id
   and ps_me.user_id = auth.uid()
  where p.id = p_post_id;
$fn$;

revoke all on function public.get_post_enriched(uuid) from public;
grant execute on function public.get_post_enriched(uuid) to authenticated, anon;

-- --------------------------------------------------------------------------- list_user_feed_enriched_cursor: tags on post root
do $body$
declare
  sig regprocedure;
begin
  for sig in
    select p.oid::regprocedure
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where p.proname = 'list_user_feed_enriched_cursor'
      and n.nspname = 'public'
  loop
    execute format('drop function if exists %s', sig);
  end loop;
end$body$;

create or replace function public.list_user_feed_enriched_cursor(p_args jsonb)
returns table (
  post jsonb,
  author jsonb,
  my_reaction text,
  my_saved boolean
)
language sql
stable
security invoker
set search_path = public
as $fn$
  select
    (
      to_jsonb(p.*)
      || jsonb_build_object(
        'post_media',
        coalesce(
          (
            select jsonb_agg(to_jsonb(pm.*) order by pm.sort_order asc)
            from public.post_media pm
            where pm.post_id = p.id
          ),
          '[]'::jsonb
        ),
        'tags', public.post_tags_json(p.id),
        'marker',
        case
          when m.id is not null then
            jsonb_build_object(
              'id', m.id,
              'text_emoji', m.text_emoji,
              'address_primary', m.address_primary,
              'address_cyrillic', m.address_cyrillic,
              'country_code', m.country_code,
              'city_code', m.city_code,
              'event_time', m.event_time,
              'end_time', m.end_time,
              'status', m.status::text,
              'tags', coalesce(
                (
                  select jsonb_agg(
                    jsonb_build_object(
                      'id', t.id,
                      'key', t.key,
                      'group_key', t.group_key
                    )
                    order by t.group_key nulls last, t.key
                  )
                  from public.marker_tag_links l
                  join public.marker_tags t on t.id = l.tag_id
                  where l.marker_id = m.id
                ),
                '[]'::jsonb
              )
            )
          else 'null'::jsonb
        end,
        'profile_filters', public.post_profile_filters_json(p.id)
      )
    ) as post,
    jsonb_build_object(
      'id', pr.id,
      'username', pr.username,
      'avatar_url', pr.avatar_url
    ) as author,
    public.get_my_post_reaction_kind(p.id) as my_reaction,
    (ps_me.post_id is not null) as my_saved
  from (
    select * from jsonb_to_record(coalesce(p_args, '{}'::jsonb)) as x(
      p_user_id uuid,
      p_limit int,
      p_cursor_created_at timestamptz,
      p_cursor_id uuid,
      p_cluster_id uuid,
      p_only_without_cluster boolean,
      p_exclude_with_marker boolean,
      p_only_with_marker boolean,
      p_filter_selection_keys text[]
    )
  ) a
  inner join public.posts p
    on p.user_id = a.p_user_id
  inner join public.profiles pr on pr.id = p.user_id
  left join public.markers m
    on m.id = p.marker_id
  left join public.post_saves ps_me
    on ps_me.post_id = p.id
   and ps_me.user_id = auth.uid()
  where p.is_archived = false
    and p.deleted_at is null
    and (
      case
        when coalesce(a.p_only_with_marker, false) then p.marker_id is not null
        when coalesce(a.p_exclude_with_marker, false) then p.marker_id is null
        else true
      end
    )
    and (
      case
        when coalesce(a.p_only_without_cluster, false) then p.cluster_id is null
        when a.p_cluster_id is not null then p.cluster_id = a.p_cluster_id
        else true
      end
    )
    and public.post_matches_profile_filter_selection(
      p.id,
      a.p_user_id,
      a.p_filter_selection_keys
    )
    and (
      a.p_cursor_id is null
      or (p.created_at, p.id) < (a.p_cursor_created_at, a.p_cursor_id)
    )
  order by p.created_at desc, p.id desc
  limit (least(greatest(coalesce((p_args->>'p_limit')::int, 24), 1), 100));
$fn$;

revoke all on function public.list_user_feed_enriched_cursor(jsonb) from public;
grant execute on function public.list_user_feed_enriched_cursor(jsonb) to authenticated, anon;

notify pgrst, 'reload schema';
