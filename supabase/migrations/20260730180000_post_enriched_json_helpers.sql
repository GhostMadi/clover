-- Posts: shared JSON builders for enriched post cards (DRY for feed/detail RPCs).

-- --------------------------------------------------------------------------- marker_enriched_json
create or replace function public.marker_enriched_json(p_marker_id uuid)
returns jsonb
language sql
stable
set search_path = public
as $$
  select case
    when p_marker_id is null then 'null'::jsonb
    else coalesce(
      (
        select jsonb_build_object(
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
        from public.markers m
        where m.id = p_marker_id
      ),
      'null'::jsonb
    )
  end;
$$;

comment on function public.marker_enriched_json(uuid) is
  'Marker subtree for enriched post JSON (null → json null).';

revoke all on function public.marker_enriched_json(uuid) from public;
grant execute on function public.marker_enriched_json(uuid) to authenticated, anon;

-- --------------------------------------------------------------------------- post_enriched_root_json
create or replace function public.post_enriched_root_json(p public.posts)
returns jsonb
language sql
stable
set search_path = public
as $$
  select
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
      'marker', public.marker_enriched_json(p.marker_id),
      'profile_filters', public.post_profile_filters_json(p.id)
    );
$$;

comment on function public.post_enriched_root_json(public.posts) is
  'Post row + post_media, tags, marker, profile_filters for enriched RPCs.';

revoke all on function public.post_enriched_root_json(public.posts) from public;
grant execute on function public.post_enriched_root_json(public.posts) to authenticated, anon;

-- --------------------------------------------------------------------------- get_post_enriched
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
    public.post_enriched_root_json(p) as post,
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
  left join public.post_saves ps_me
    on ps_me.post_id = p.id
   and ps_me.user_id = auth.uid()
  where p.id = p_post_id;
$fn$;

revoke all on function public.get_post_enriched(uuid) from public;
grant execute on function public.get_post_enriched(uuid) to authenticated, anon;

-- --------------------------------------------------------------------------- list_user_feed_enriched_cursor
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
    public.post_enriched_root_json(p) as post,
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

-- --------------------------------------------------------------------------- list_events_feed_enriched_cursor
create or replace function public.list_events_feed_enriched_cursor(p_args jsonb)
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
  with args as (
    select
      least(greatest(coalesce((p_args->>'p_limit')::int, 24), 1), 100) as lim,
      coalesce(nullif(trim(p_args->>'p_content_kind'), ''), 'events_only') as content_kind,
      nullif(trim(p_args->>'p_country_code'), '') as country_code,
      nullif(trim(p_args->>'p_city_code'), '') as city_code,
      nullif(trim(p_args->>'p_emoji'), '') as emoji,
      (p_args->>'p_date_from')::date as date_from,
      (p_args->>'p_date_to')::date as date_to,
      coalesce((p_args->>'p_at_time')::timestamptz, now()) as at_time,
      (p_args->>'p_cursor_event_time')::timestamptz as cursor_event_time,
      nullif(trim(p_args->>'p_cursor_id'), '')::uuid as cursor_id,
      (p_args->>'p_cursor_created_at')::timestamptz as cursor_created_at,
      case
        when p_args ? 'p_tag_keys'
          and jsonb_typeof(p_args->'p_tag_keys') = 'array'
          and jsonb_array_length(p_args->'p_tag_keys') > 0
        then (
          select array_agg(trim(both value))
          from jsonb_array_elements_text(p_args->'p_tag_keys') as t(value)
          where length(trim(both value)) > 0
        )
        else null
      end as tag_keys
  )
  select
    public.post_enriched_root_json(p) as post,
    public.author_mini_json(pr.id) as author,
    public.get_my_post_reaction_kind(p.id) as my_reaction,
    (ps_me.post_id is not null) as my_saved,
    (
      auth.uid() is not null
      and auth.uid() <> p.user_id
      and public.is_following_user(p.user_id)
    ) as my_following_author
  from public.posts p
  cross join args a
  inner join public.profiles pr on pr.id = p.user_id
  left join public.markers m on m.id = p.marker_id
  left join public.post_saves ps_me
    on ps_me.post_id = p.id
   and ps_me.user_id = auth.uid()
  where p.is_archived = false
    and p.deleted_at is null
    and pr.content_visible = true
    and pr.account_state <> 'hibernate'
    and (
      case
        when a.content_kind = 'all' then true
        else p.marker_id is not null
      end
    )
    and (m.id is null or m.is_archived = false)
    and (m.id is null or m.status <> 'cancelled')
    and (
      a.country_code is null
      or (m.id is not null and m.country_code = a.country_code)
      or (a.content_kind = 'all' and m.id is null)
    )
    and (
      a.city_code is null
      or (m.id is not null and m.city_code = a.city_code)
      or (a.content_kind = 'all' and m.id is null)
    )
    and (
      a.emoji is null
      or (m.id is not null and m.text_emoji = a.emoji)
    )
    and (
      a.date_from is null
      or (m.id is not null and m.event_time::date >= a.date_from)
      or (a.content_kind = 'all' and m.id is null)
    )
    and (
      a.date_to is null
      or (m.id is not null and m.event_time::date <= a.date_to)
      or (a.content_kind = 'all' and m.id is null)
    )
    and (
      a.tag_keys is null
      or (
        m.id is not null
        and exists (
          select 1
          from public.marker_tag_links l
          join public.marker_tags t on t.id = l.tag_id
          where l.marker_id = m.id
            and t.key = any (a.tag_keys)
        )
      )
    )
    and (
      case
        when a.content_kind = 'all' then
          a.cursor_created_at is null
          or a.cursor_id is null
          or (p.created_at, p.id) < (a.cursor_created_at, a.cursor_id)
        else
          a.cursor_event_time is null
          or a.cursor_id is null
          or (m.event_time, p.id) > (a.cursor_event_time, a.cursor_id)
      end
    )
  order by
    case when a.content_kind = 'all' then p.created_at end desc nulls last,
    case when a.content_kind = 'all' then p.id end desc nulls last,
    case when a.content_kind <> 'all' then m.event_time end asc nulls last,
    case when a.content_kind <> 'all' then p.id end asc nulls last
  limit (select lim from args);
$fn$;

revoke all on function public.list_events_feed_enriched_cursor(jsonb) from public;
grant execute on function public.list_events_feed_enriched_cursor(jsonb) to authenticated, anon;

notify pgrst, 'reload schema';
