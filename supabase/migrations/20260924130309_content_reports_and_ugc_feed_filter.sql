-- UGC safety (App Store 1.2): content_reports, report_content,
-- block_user notifies developer, Event/Map hide blocked authors.
-- Product: docs/business/ugc-safety.md · Spec: docs/supabase/SPEC_CONTENT_REPORTS.md

-- --------------------------------------------------------------------------- content_reports
create table if not exists public.content_reports (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid not null references public.profiles (id) on delete cascade,
  target_user_id uuid not null references public.profiles (id) on delete cascade,
  target_post_id uuid null references public.posts (id) on delete set null,
  reason_code text not null
    constraint content_reports_reason_check check (
      reason_code in (
        'objectionable_content',
        'abusive_user',
        'spam',
        'harassment',
        'other'
      )
    ),
  source text not null
    constraint content_reports_source_check check (source in ('report', 'block')),
  note text null,
  status text not null default 'open'
    constraint content_reports_status_check check (status in ('open', 'resolved', 'dismissed')),
  created_at timestamptz not null default now(),
  constraint content_reports_no_self check (reporter_id <> target_user_id)
);

create index if not exists content_reports_status_created_idx
  on public.content_reports (status, created_at desc);

create index if not exists content_reports_reporter_idx
  on public.content_reports (reporter_id, created_at desc);

create unique index if not exists content_reports_open_post_dedupe_idx
  on public.content_reports (reporter_id, target_user_id, target_post_id)
  where status = 'open' and target_post_id is not null;

create unique index if not exists content_reports_open_user_dedupe_idx
  on public.content_reports (reporter_id, target_user_id)
  where status = 'open' and target_post_id is null;

comment on table public.content_reports is
  'UGC flag/block notifications for moderation (EN reason_code; act within 24h).';

alter table public.content_reports enable row level security;

drop policy if exists content_reports_select_own on public.content_reports;
create policy content_reports_select_own
  on public.content_reports for select
  to authenticated
  using (reporter_id = auth.uid());

revoke all on table public.content_reports from public, anon, authenticated;
grant select on table public.content_reports to authenticated;
grant all on table public.content_reports to service_role;

-- --------------------------------------------------------------------------- viewer_is_blocked_with
create or replace function public.viewer_is_blocked_with(p_other uuid)
returns boolean
language sql
stable
security definer
set search_path = public
set row_security to off
as $$
  select
    auth.uid() is not null
    and p_other is not null
    and auth.uid() <> p_other
    and exists (
      select 1
      from public.profile_blocks b
      where (b.blocker_id = auth.uid() and b.blocked_id = p_other)
         or (b.blocker_id = p_other and b.blocked_id = auth.uid())
    );
$$;

revoke all on function public.viewer_is_blocked_with(uuid) from public;
grant execute on function public.viewer_is_blocked_with(uuid) to authenticated, anon;

comment on function public.viewer_is_blocked_with(uuid) is
  'True if current viewer and p_other have a profile_blocks edge either way.';

-- --------------------------------------------------------------------------- report_content
create or replace function public.report_content(
  p_target_user uuid,
  p_reason text,
  p_post_id uuid default null,
  p_note text default null
)
returns void
language plpgsql
security definer
set search_path = public
set row_security to off
as $$
declare
  uid uuid;
  v_reason text := nullif(trim(p_reason), '');
  v_note text := nullif(trim(p_note), '');
begin
  uid := auth.uid();
  if uid is null then
    raise exception 'not_authenticated' using errcode = 'P0003';
  end if;

  if p_target_user is null or p_target_user = uid then
    raise exception 'cannot_report_self' using errcode = 'P0007';
  end if;

  if not exists (select 1 from public.profiles pr where pr.id = p_target_user) then
    raise exception 'user_not_found' using errcode = 'P0008';
  end if;

  if v_reason is null or v_reason not in (
    'objectionable_content', 'abusive_user', 'spam', 'harassment', 'other'
  ) then
    raise exception 'invalid_reason' using errcode = 'P0001';
  end if;

  if p_post_id is not null then
    if not exists (
      select 1 from public.posts p
      where p.id = p_post_id
        and p.user_id = p_target_user
        and p.deleted_at is null
    ) then
      raise exception 'post_not_found' using errcode = 'P0008';
    end if;
  end if;

  if v_note is not null and char_length(v_note) > 500 then
    v_note := left(v_note, 500);
  end if;

  if exists (
    select 1
    from public.content_reports r
    where r.reporter_id = uid
      and r.target_user_id = p_target_user
      and r.status = 'open'
      and (
        (p_post_id is null and r.target_post_id is null)
        or r.target_post_id is not distinct from p_post_id
      )
  ) then
    return;
  end if;

  insert into public.content_reports (
    reporter_id, target_user_id, target_post_id, reason_code, source, note
  )
  values (uid, p_target_user, p_post_id, v_reason, 'report', v_note);
end;
$$;

revoke all on function public.report_content(uuid, text, uuid, text) from public;
grant execute on function public.report_content(uuid, text, uuid, text) to authenticated;

comment on function public.report_content(uuid, text, uuid, text) is
  'Authenticated user flags a profile/post; EN reason_code; open-dedupe.';

-- --------------------------------------------------------------------------- block_user (notify + optional reason/post)
drop function if exists public.block_user(uuid);

create or replace function public.block_user(
  p_target uuid,
  p_reason text default 'abusive_user',
  p_post_id uuid default null,
  p_note text default null
)
returns void
language plpgsql
security definer
set search_path = public
set row_security to off
as $$
declare
  uid uuid;
  v_reason text := coalesce(nullif(trim(p_reason), ''), 'abusive_user');
  v_note text := nullif(trim(p_note), '');
begin
  uid := auth.uid();
  if uid is null then
    raise exception 'not_authenticated' using errcode = 'P0003';
  end if;

  if p_target is null or p_target = uid then
    raise exception 'cannot_block_self' using errcode = 'P0007';
  end if;

  if not exists (select 1 from public.profiles pr where pr.id = p_target) then
    raise exception 'user_not_found' using errcode = 'P0008';
  end if;

  if v_reason not in (
    'objectionable_content', 'abusive_user', 'spam', 'harassment', 'other'
  ) then
    v_reason := 'abusive_user';
  end if;

  if p_post_id is not null and not exists (
    select 1 from public.posts p
    where p.id = p_post_id and p.user_id = p_target and p.deleted_at is null
  ) then
    p_post_id := null;
  end if;

  if v_note is not null and char_length(v_note) > 500 then
    v_note := left(v_note, 500);
  end if;

  insert into public.profile_blocks (blocker_id, blocked_id)
  values (uid, p_target)
  on conflict do nothing;

  delete from public.profile_follows
  where (follower_id = uid and following_id = p_target)
     or (follower_id = p_target and following_id = uid);

  -- Notify developer (App Store 1.2): block creates a moderation report.
  if not exists (
    select 1
    from public.content_reports r
    where r.reporter_id = uid
      and r.target_user_id = p_target
      and r.source = 'block'
      and r.status = 'open'
      and (
        (p_post_id is null and r.target_post_id is null)
        or r.target_post_id is not distinct from p_post_id
      )
  ) then
    insert into public.content_reports (
      reporter_id, target_user_id, target_post_id, reason_code, source, note
    )
    values (uid, p_target, p_post_id, v_reason, 'block', v_note);
  end if;
end;
$$;

revoke all on function public.block_user(uuid, text, uuid, text) from public;
grant execute on function public.block_user(uuid, text, uuid, text) to authenticated;

comment on function public.block_user(uuid, text, uuid, text) is
  'Block target, unfollow both ways, insert content_reports source=block.';

-- --------------------------------------------------------------------------- list_events_feed: hide blocked authors
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
        and not public.viewer_is_blocked_with(p.user_id)
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
        and not public.viewer_is_blocked_with(p.user_id)
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
  'Events/All feed: keyset page; excludes authors blocked with viewer.';

revoke all on function public.list_events_feed_enriched_cursor(jsonb) from public;
grant execute on function public.list_events_feed_enriched_cursor(jsonb) to authenticated, anon;

-- --------------------------------------------------------------------------- list_markers_map: hide blocked owners
create or replace function public.list_markers_map(
  p_lat double precision,
  p_lng double precision,
  p_radius_m double precision,
  p_at_time timestamptz default now(),
  p_emoji text default null,
  p_tag_keys text[] default null,
  p_limit integer default 200,
  p_offset integer default 0,
  p_country_code text default null,
  p_city_code text default null
)
returns table (
  id uuid,
  owner_id uuid,
  text_emoji text,
  address_primary text,
  address_cyrillic text,
  country_code text,
  city_code text,
  description text,
  cover_image_url text,
  event_time timestamptz,
  end_time timestamptz,
  status text,
  lat double precision,
  lng double precision,
  distance_m double precision,
  post_id uuid,
  post_count bigint,
  preview_image_urls text[]
)
language sql
stable
security invoker
set search_path = public
as $function$
  with
  params as (
    select
      st_setsrid(st_makepoint(p_lng, p_lat), 4326)::geography as user_loc,
      greatest(coalesce(p_radius_m, 0), 0)::double precision as radius_m,
      coalesce(p_at_time, now()) as at_time,
      nullif(trim(coalesce(p_emoji, '')), '') as emoji,
      nullif(trim(coalesce(p_country_code, '')), '') as country_code,
      nullif(trim(coalesce(p_city_code, '')), '') as city_code
  )
  select
    m.id,
    m.owner_id,
    m.text_emoji,
    m.address_primary,
    m.address_cyrillic,
    m.country_code,
    m.city_code,
    m.description,
    m.cover_image_url,
    m.event_time,
    m.end_time,
    (
      case
        when m.status = 'cancelled'::public.marker_status then 'cancelled'
        when (select at_time from params) < m.event_time then 'upcoming'
        when (select at_time from params) <= m.end_time then 'active'
        else 'finished'
      end
    ) as status,
    st_y(m.location::geometry)::double precision as lat,
    st_x(m.location::geometry)::double precision as lng,
    st_distance(m.location, (select user_loc from params))::double precision as distance_m,
    m.post_id,
    (
      select count(*)::bigint
      from public.marker_posts mp
      where mp.marker_id = m.id
    ) as post_count,
    coalesce(
      (
        select array_agg(r.u order by r.ord)
        from (
          select
            trim(both pm_first.url)::text as u,
            row_number() over (
              order by
                mp.is_primary desc,
                mp.sort_order asc,
                mp.created_at asc,
                mp.post_id asc
            ) as ord
          from public.marker_posts mp
          join public.posts p on p.id = mp.post_id
          left join lateral (
            select pm.url
            from public.post_media pm
            where pm.post_id = p.id
            order by pm.sort_order asc nulls last
            limit 1
          ) pm_first on true
          where mp.marker_id = m.id
            and pm_first.url is not null
            and length(trim(both pm_first.url)) > 0
        ) r
        where r.ord <= 4
      ),
      '{}'::text[]
    ) as preview_image_urls
  from public.markers m
  where
    m.is_archived = false
    and m.status <> 'cancelled'::public.marker_status
    and m.end_time > (select at_time from params)
    and st_dwithin(m.location, (select user_loc from params), (select radius_m from params))
    and not public.viewer_is_blocked_with(m.owner_id)
    and (
      (select emoji from params) is null
      or m.text_emoji = (select emoji from params)
    )
    and (
      (select country_code from params) is null
      or m.country_code = (select country_code from params)
    )
    and (
      (select city_code from params) is null
      or m.city_code = (select city_code from params)
    )
    and (
      p_tag_keys is null
      or exists (
        select 1
        from public.marker_tag_links l
        join public.marker_tags t on t.id = l.tag_id
        where l.marker_id = m.id
          and t.key = any (p_tag_keys)
      )
    )
  order by
    st_distance(m.location, (select user_loc from params)) asc,
    m.event_time asc
  limit least(greatest(coalesce(p_limit, 200), 1), 500)
  offset greatest(coalesce(p_offset, 0), 0);
$function$;

revoke all on function public.list_markers_map(
  double precision, double precision, double precision, timestamptz,
  text, text[], integer, integer, text, text
) from public;
grant execute on function public.list_markers_map(
  double precision, double precision, double precision, timestamptz,
  text, text[], integer, integer, text, text
) to authenticated, anon;

-- --------------------------------------------------------------------------- count_markers_map
create or replace function public.count_markers_map(
  p_lat double precision,
  p_lng double precision,
  p_radius_m double precision,
  p_at_time timestamptz default now(),
  p_emoji text default null,
  p_tag_keys text[] default null,
  p_country_code text default null,
  p_city_code text default null
)
returns bigint
language sql
stable
security invoker
set search_path = public
as $$
  with
  params as (
    select
      st_setsrid(st_makepoint(p_lng, p_lat), 4326)::geography as user_loc,
      greatest(coalesce(p_radius_m, 0), 0)::double precision as radius_m,
      coalesce(p_at_time, now()) as at_time,
      nullif(trim(coalesce(p_emoji, '')), '') as emoji,
      nullif(trim(coalesce(p_country_code, '')), '') as country_code,
      nullif(trim(coalesce(p_city_code, '')), '') as city_code
  )
  select count(*)::bigint
  from public.markers m
  where
    m.is_archived = false
    and m.status <> 'cancelled'::public.marker_status
    and m.end_time > (select at_time from params)
    and st_dwithin(m.location, (select user_loc from params), (select radius_m from params))
    and not public.viewer_is_blocked_with(m.owner_id)
    and (
      (select emoji from params) is null
      or m.text_emoji = (select emoji from params)
    )
    and (
      (select country_code from params) is null
      or m.country_code = (select country_code from params)
    )
    and (
      (select city_code from params) is null
      or m.city_code = (select city_code from params)
    )
    and (
      p_tag_keys is null
      or exists (
        select 1
        from public.marker_tag_links l
        join public.marker_tags t on t.id = l.tag_id
        where l.marker_id = m.id
          and t.key = any (p_tag_keys)
      )
    );
$$;

revoke all on function public.count_markers_map(
  double precision, double precision, double precision, timestamptz,
  text, text[], text, text
) from public;
grant execute on function public.count_markers_map(
  double precision, double precision, double precision, timestamptz,
  text, text[], text, text
) to authenticated, anon;

-- --------------------------------------------------------------------------- list_markers_map_clusters
create or replace function public.list_markers_map_clusters(
  p_lat double precision,
  p_lng double precision,
  p_radius_m double precision,
  p_zoom double precision,
  p_at_time timestamptz default now(),
  p_emoji text default null,
  p_tag_keys text[] default null,
  p_country_code text default null,
  p_city_code text default null,
  p_limit int default 200
)
returns table (
  lng double precision,
  lat double precision,
  point_count bigint,
  sample_emoji text,
  sample_marker_id uuid
)
language sql
stable
security invoker
set search_path = public
as $function$
  with
  params as (
    select
      st_setsrid(st_makepoint(p_lng, p_lat), 4326)::geography as user_loc,
      greatest(coalesce(p_radius_m, 0), 0)::double precision as radius_m,
      coalesce(p_at_time, now()) as at_time,
      nullif(trim(coalesce(p_emoji, '')), '') as emoji,
      nullif(trim(coalesce(p_country_code, '')), '') as country_code,
      nullif(trim(coalesce(p_city_code, '')), '') as city_code,
      coalesce(p_zoom, 0)::double precision as zoom,
      -- ~0.02° at z10; halves each zoom step up (z11→0.01, z12→0.005)
      greatest(
        0.02 * power(2.0, 10.0 - coalesce(p_zoom, 10)::double precision),
        0.001
      )::double precision as cell_deg
  ),
  filtered as (
    select
      m.id,
      m.text_emoji,
      m.location::geometry as geom
    from public.markers m
    where
      -- High zoom: empty — client switches to list_markers_map
      (select zoom from params) < 13
      and m.is_archived = false
      and m.status <> 'cancelled'::public.marker_status
      and m.end_time > (select at_time from params)
      and st_dwithin(m.location, (select user_loc from params), (select radius_m from params))
      and not public.viewer_is_blocked_with(m.owner_id)
      and (
        (select emoji from params) is null
        or m.text_emoji = (select emoji from params)
      )
      and (
        (select country_code from params) is null
        or m.country_code = (select country_code from params)
      )
      and (
        (select city_code from params) is null
        or m.city_code = (select city_code from params)
      )
      and (
        p_tag_keys is null
        or exists (
          select 1
          from public.marker_tag_links l
          join public.marker_tags t on t.id = l.tag_id
          where l.marker_id = m.id
            and t.key = any (p_tag_keys)
        )
      )
  ),
  snapped as (
    select
      f.id,
      f.text_emoji,
      f.geom,
      st_snaptogrid(f.geom, (select cell_deg from params)) as cell_geom
    from filtered f
  ),
  clustered as (
    select
      st_x(st_centroid(st_collect(s.geom)))::double precision as lng,
      st_y(st_centroid(st_collect(s.geom)))::double precision as lat,
      count(*)::bigint as point_count,
      (array_agg(
        s.text_emoji
        order by s.geom <-> st_centroid(s.cell_geom), s.id
      ))[1] as sample_emoji,
      (array_agg(
        s.id
        order by s.geom <-> st_centroid(s.cell_geom), s.id
      ))[1] as sample_marker_id
    from snapped s
    group by s.cell_geom
  )
  select
    c.lng,
    c.lat,
    c.point_count,
    c.sample_emoji,
    c.sample_marker_id
  from clustered c
  order by
    st_distance(
      st_setsrid(st_makepoint(c.lng, c.lat), 4326)::geography,
      (select user_loc from params)
    ) asc,
    c.point_count desc
  limit least(greatest(coalesce(p_limit, 200), 1), 500);
$function$;

revoke all on function public.list_markers_map_clusters(
  double precision, double precision, double precision, double precision,
  timestamptz, text, text[], text, text, integer
) from public;
grant execute on function public.list_markers_map_clusters(
  double precision, double precision, double precision, double precision,
  timestamptz, text, text[], text, text, integer
) to authenticated, anon;

notify pgrst, 'reload schema';
