-- Site admin platform stats + allow service_role on honest quiz admin RPCs.
-- Product: docs/business/website-admin.md · Spec: docs/supabase/SPEC_ADMIN_PLATFORM.md

create or replace function public.admin_platform_stats(p_days int default 7)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
set row_security to off
as $$
declare
  v_days int := greatest(1, least(coalesce(p_days, 7), 30));
  v_since timestamptz := now() - make_interval(days => v_days);
  v_out jsonb;
begin
  select jsonb_build_object(
    'period_days', v_days,
    'profiles_total', (select count(*)::int from public.profiles),
    'dau', (
      select count(distinct user_id)::int
      from public.account_login_events
      where created_at >= now() - interval '1 day'
    ),
    'active_logins', (
      select count(distinct user_id)::int
      from public.account_login_events
      where created_at >= v_since
    ),
    'new_profiles', (
      select count(*)::int
      from public.profiles
      where created_at >= v_since
    ),
    'tag_booking', (
      select count(distinct p.id)::int
      from public.profiles p
      join public.profile_tag_links l on l.id = p.tag_link_id
      join public.marker_tags t on t.id = any (l.tag_ids)
      where t.key = 'booking'
    ),
    'tag_attendance', (
      select count(distinct p.id)::int
      from public.profiles p
      join public.profile_tag_links l on l.id = p.tag_link_id
      join public.marker_tags t on t.id = any (l.tag_ids)
      where t.key = 'attendance'
    ),
    'tag_resources', (
      select count(distinct p.id)::int
      from public.profiles p
      join public.profile_tag_links l on l.id = p.tag_link_id
      join public.marker_tags t on t.id = any (l.tag_ids)
      where t.key = 'resources'
    ),
    'booking_points', (
      select count(*)::int from public.booking_points
    ),
    'attendance_workplaces', (
      select count(*)::int from public.attendance_workplaces
    ),
    'bookings_period', (
      select count(*)::int from public.bookings where created_at >= v_since
    ),
    'punches_period', (
      select count(*)::int from public.attendance_punches where created_at >= v_since
    ),
    'posts_period', (
      select count(*)::int from public.posts where created_at >= v_since
    ),
    'support_new', (
      select count(*)::int from public.support_requests where status = 'new'
    ),
    'honest_quiz_finished', (
      select count(*)::int from public.honest_quiz_runs where finished
    )
  )
  into v_out;

  return v_out;
end;
$$;

comment on function public.admin_platform_stats(int) is
  'Platform KPIs for /admin/analytics. service_role only.';

revoke all on function public.admin_platform_stats(int) from public;
grant execute on function public.admin_platform_stats(int) to service_role;

-- Honest quiz admin: allow service_role (site admin API) as well as is_site_admin().
create or replace function public.honest_quiz_admin_list()
returns setof jsonb
language plpgsql
stable
security definer
set search_path = public
set row_security to off
as $$
begin
  if not (
    coalesce(auth.role(), '') = 'service_role'
    or coalesce(public.is_site_admin(), false)
  ) then
    raise exception 'forbidden';
  end if;

  return query
  select jsonb_build_object(
    'id', r.id,
    'created_at', r.created_at,
    'updated_at', r.updated_at,
    'finished', r.finished,
    'answers', r.answers,
    'has_photo', r.photo_data_url is not null,
    'user_agent', r.user_agent
  )
  from public.honest_quiz_runs r
  order by r.created_at desc
  limit 100;
end;
$$;

revoke all on function public.honest_quiz_admin_list() from public;
grant execute on function public.honest_quiz_admin_list() to authenticated, service_role;

create or replace function public.honest_quiz_admin_get(p_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
set row_security to off
as $$
declare
  v jsonb;
begin
  if not (
    coalesce(auth.role(), '') = 'service_role'
    or coalesce(public.is_site_admin(), false)
  ) then
    raise exception 'forbidden';
  end if;

  select jsonb_build_object(
    'id', r.id,
    'created_at', r.created_at,
    'updated_at', r.updated_at,
    'finished', r.finished,
    'answers', r.answers,
    'has_photo', r.photo_data_url is not null,
    'user_agent', r.user_agent,
    'photo_data_url', r.photo_data_url
  )
  into v
  from public.honest_quiz_runs r
  where r.id = p_id;

  return v;
end;
$$;

revoke all on function public.honest_quiz_admin_get(uuid) from public;
grant execute on function public.honest_quiz_admin_get(uuid) to authenticated, service_role;
