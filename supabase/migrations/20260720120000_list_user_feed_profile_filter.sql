-- Profile feed: filter posts by selected profile filter values (post_profile_filter_links).
-- Semantics: AND across categories, OR within a category.

create or replace function public.post_matches_profile_filter_selection(
  p_post_id uuid,
  p_owner_id uuid,
  p_selection_keys text[]
)
returns boolean
language sql
stable
security invoker
set search_path = public
as $fn$
  with raw_keys as (
    select trim(k) as key
    from unnest(coalesce(p_selection_keys, '{}'::text[])) as u(k)
    where trim(k) <> ''
  ),
  parsed as (
    select distinct
      left(rk.key, strpos(rk.key, ':') - 1)::uuid as category_id,
      trim(substring(rk.key from strpos(rk.key, ':') + 1)) as label
    from raw_keys rk
    where strpos(rk.key, ':') > 1
      and char_length(trim(substring(rk.key from strpos(rk.key, ':') + 1))) > 0
  ),
  resolved as (
    select p.category_id, v.id as value_id
    from parsed p
    join public.profile_filter_categories c
      on c.id = p.category_id
     and c.owner_id = p_owner_id
    join public.profile_filter_values v
      on v.category_id = c.id
     and lower(trim(v.label)) = lower(p.label)
  ),
  groups as (
    select category_id, array_agg(distinct value_id) as value_ids
    from resolved
    group by category_id
  )
  select
    case
      when (select count(*) from raw_keys) = 0 then true
      when (select count(*) from groups) = 0 then false
      else (
        select count(*) = count(*) filter (
          where exists (
            select 1
            from public.post_profile_filter_links l
            where l.post_id = p_post_id
              and l.filter_value_id = any(g.value_ids)
          )
        )
        from groups g
      )
    end;
$fn$;

comment on function public.post_matches_profile_filter_selection(uuid, uuid, text[]) is
  'True when post has at least one selected value per category group (AND across categories, OR within).';

-- --------------------------------------------------------------------------- list_user_feed_enriched_cursor + filter
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
        end
      )
    ) as post,
    jsonb_build_object(
      'id', pr.id,
      'username', pr.username,
      'avatar_url', pr.avatar_url
    ) as author,
    r.kind as my_reaction,
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
  left join public.post_reactions r
    on r.post_id = p.id
   and r.user_id = auth.uid()
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

comment on function public.list_user_feed_enriched_cursor(jsonb) is
  'Profile feed: post + post_media + optional marker; optional p_filter_selection_keys (category_id:label).';

notify pgrst, 'reload schema';
