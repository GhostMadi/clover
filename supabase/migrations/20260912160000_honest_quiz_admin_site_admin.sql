-- Honest quiz admin: gate by is_site_admin (no p_secret).
-- Product: docs/business/honest-quiz.md

create or replace function public.honest_quiz_admin_list()
returns setof jsonb
language plpgsql
stable
security definer
set search_path = public
set row_security to off
as $$
begin
  if auth.uid() is null then
    raise exception 'auth required';
  end if;
  if not coalesce(public.is_site_admin(), false) then
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
grant execute on function public.honest_quiz_admin_list() to authenticated;

drop function if exists public.honest_quiz_admin_list(text);

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
  if auth.uid() is null then
    raise exception 'auth required';
  end if;
  if not coalesce(public.is_site_admin(), false) then
    raise exception 'forbidden';
  end if;

  select jsonb_build_object(
    'id', r.id,
    'created_at', r.created_at,
    'updated_at', r.updated_at,
    'finished', r.finished,
    'answers', r.answers,
    'photo_data_url', r.photo_data_url,
    'user_agent', r.user_agent
  )
  into v
  from public.honest_quiz_runs r
  where r.id = p_id;

  return v;
end;
$$;

revoke all on function public.honest_quiz_admin_get(uuid) from public;
grant execute on function public.honest_quiz_admin_get(uuid) to authenticated;

drop function if exists public.honest_quiz_admin_get(text, uuid);

drop function if exists public._honest_quiz_admin_ok(text);
