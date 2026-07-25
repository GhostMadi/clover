-- Events feed: optional marker tag keys filter (p_tag_keys in p_args jsonb).

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
        end,
        'profile_filters', public.post_profile_filters_json(p.id)
      )
    ) as post,
    public.author_mini_json(pr.id) as author,
    r.kind as my_reaction,
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
  left join public.post_reactions r
    on r.post_id = p.id
   and r.user_id = auth.uid()
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
