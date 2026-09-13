-- Speed up events feed: id-first page, then enrich; use at_time for events_only.
-- Product: docs/business/website-gap-plan.md · Spec: docs/supabase/SPEC_POSTS_AND_EVENTS.md
-- Symptom: statement_timeout (57014) on list_events_feed_enriched_cursor from /app (Sentry).

create or replace function public.list_events_feed_enriched_cursor(p_args jsonb)
returns table (
  post jsonb,
  author jsonb,
  my_reaction text,
  my_saved boolean,
  my_following_author boolean
)
language plpgsql
stable
security invoker
set search_path = public
as $fn$
declare
  v_lim int := least(greatest(coalesce((p_args->>'p_limit')::int, 24), 1), 100);
  v_content_kind text := coalesce(nullif(trim(p_args->>'p_content_kind'), ''), 'events_only');
  v_country_code text := nullif(trim(p_args->>'p_country_code'), '');
  v_city_code text := nullif(trim(p_args->>'p_city_code'), '');
  v_emoji text := nullif(trim(p_args->>'p_emoji'), '');
  v_date_from date := (p_args->>'p_date_from')::date;
  v_date_to date := (p_args->>'p_date_to')::date;
  v_at_time timestamptz := coalesce((p_args->>'p_at_time')::timestamptz, now());
  v_cursor_event_time timestamptz := (p_args->>'p_cursor_event_time')::timestamptz;
  v_cursor_id uuid := nullif(trim(p_args->>'p_cursor_id'), '')::uuid;
  v_cursor_created_at timestamptz := (p_args->>'p_cursor_created_at')::timestamptz;
  v_tag_keys text[];
begin
  if p_args ? 'p_tag_keys'
    and jsonb_typeof(p_args->'p_tag_keys') = 'array'
    and jsonb_array_length(p_args->'p_tag_keys') > 0
  then
    select array_agg(trim(both value))
    into v_tag_keys
    from jsonb_array_elements_text(p_args->'p_tag_keys') as t(value)
    where length(trim(both value)) > 0;
  else
    v_tag_keys := null;
  end if;

  if v_content_kind = 'all' then
    return query
    with page as (
      select p.id
      from public.posts p
      inner join public.profiles pr on pr.id = p.user_id
      left join public.markers m on m.id = p.marker_id
      where p.is_archived = false
        and p.deleted_at is null
        and pr.content_visible = true
        and pr.account_state <> 'hibernate'
        and (m.id is null or m.is_archived = false)
        and (m.id is null or m.status <> 'cancelled')
        and (
          v_country_code is null
          or (m.id is not null and m.country_code = v_country_code)
          or m.id is null
        )
        and (
          v_city_code is null
          or (m.id is not null and m.city_code = v_city_code)
          or m.id is null
        )
        and (
          v_cursor_created_at is null
          or v_cursor_id is null
          or (p.created_at, p.id) < (v_cursor_created_at, v_cursor_id)
        )
      order by p.created_at desc, p.id desc
      limit v_lim
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
    from page pg
    inner join public.posts p on p.id = pg.id
    inner join public.profiles pr on pr.id = p.user_id
    left join public.post_saves ps_me
      on ps_me.post_id = p.id
     and ps_me.user_id = auth.uid()
    order by p.created_at desc, p.id desc;
  else
    return query
    with page as (
      select p.id
      from public.posts p
      inner join public.profiles pr on pr.id = p.user_id
      inner join public.markers m on m.id = p.marker_id
      where p.is_archived = false
        and p.deleted_at is null
        and pr.content_visible = true
        and pr.account_state <> 'hibernate'
        and m.is_archived = false
        and m.status <> 'cancelled'
        and coalesce(m.end_time, m.event_time) >= v_at_time
        and (v_country_code is null or m.country_code = v_country_code)
        and (v_city_code is null or m.city_code = v_city_code)
        and (v_emoji is null or m.text_emoji = v_emoji)
        and (v_date_from is null or m.event_time::date >= v_date_from)
        and (v_date_to is null or m.event_time::date <= v_date_to)
        and (
          v_tag_keys is null
          or exists (
            select 1
            from public.marker_tag_links l
            join public.marker_tags t on t.id = l.tag_id
            where l.marker_id = m.id
              and t.key = any (v_tag_keys)
          )
        )
        and (
          v_cursor_event_time is null
          or v_cursor_id is null
          or (m.event_time, p.id) > (v_cursor_event_time, v_cursor_id)
        )
      order by m.event_time asc, p.id asc
      limit v_lim
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
    from page pg
    inner join public.posts p on p.id = pg.id
    inner join public.profiles pr on pr.id = p.user_id
    left join public.post_saves ps_me
      on ps_me.post_id = p.id
     and ps_me.user_id = auth.uid()
    order by (
      select m2.event_time from public.markers m2 where m2.id = p.marker_id
    ) asc nulls last, p.id asc;
  end if;
end;
$fn$;

comment on function public.list_events_feed_enriched_cursor(jsonb) is
  'Events/All feed: keyset page of ids first, then enrich. events_only uses at_time (upcoming).';

revoke all on function public.list_events_feed_enriched_cursor(jsonb) from public;
grant execute on function public.list_events_feed_enriched_cursor(jsonb) to authenticated, anon;

-- Help events_only city + time scans.
create index if not exists markers_city_event_live_idx
  on public.markers (city_code, event_time asc, id)
  where is_archived = false and status <> 'cancelled';
