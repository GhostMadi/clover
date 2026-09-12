-- Temporary romantic mini-quiz. Product: docs/business/honest-quiz.md
-- Remove with the feature when done.

create table if not exists public.honest_quiz_runs (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  client_token text not null,
  answers jsonb not null default '{}'::jsonb,
  photo_data_url text null,
  finished boolean not null default false,
  user_agent text null,
  constraint honest_quiz_runs_token_len check (
    char_length(client_token) >= 8 and char_length(client_token) <= 128
  ),
  constraint honest_quiz_runs_photo_len check (
    photo_data_url is null or char_length(photo_data_url) <= 900000
  )
);

create unique index if not exists honest_quiz_runs_client_token_uidx
  on public.honest_quiz_runs (client_token);

create index if not exists honest_quiz_runs_created_at_idx
  on public.honest_quiz_runs (created_at desc);

alter table public.honest_quiz_runs enable row level security;

revoke all on table public.honest_quiz_runs from public, anon, authenticated;
grant all on table public.honest_quiz_runs to service_role;

-- Change both here and web HONEST_QUIZ_ADMIN_SECRET
create or replace function public._honest_quiz_admin_ok(p_secret text)
returns boolean
language sql
immutable
as $$
  select coalesce(nullif(trim(p_secret), ''), '') = 'clover-honest-temp-2026';
$$;

create or replace function public.honest_quiz_upsert(
  p_client_token text,
  p_answers jsonb default '{}'::jsonb,
  p_finished boolean default false,
  p_user_agent text default null,
  p_photo_data_url text default null
)
returns uuid
language plpgsql
security definer
set search_path = public
set row_security to off
as $$
declare
  v_token text := trim(coalesce(p_client_token, ''));
  v_id uuid;
  v_photo text := nullif(trim(coalesce(p_photo_data_url, '')), '');
begin
  if char_length(v_token) < 8 or char_length(v_token) > 128 then
    raise exception 'invalid_token';
  end if;

  if v_photo is not null and char_length(v_photo) > 900000 then
    raise exception 'photo_too_large';
  end if;

  if v_photo is not null and v_photo not like 'data:image/%' then
    raise exception 'invalid_photo';
  end if;

  insert into public.honest_quiz_runs (
    client_token, answers, finished, user_agent, photo_data_url, updated_at
  )
  values (
    v_token,
    coalesce(p_answers, '{}'::jsonb),
    coalesce(p_finished, false),
    nullif(left(trim(coalesce(p_user_agent, '')), 400), ''),
    v_photo,
    now()
  )
  on conflict (client_token) do update
  set
    answers = coalesce(public.honest_quiz_runs.answers, '{}'::jsonb)
      || coalesce(excluded.answers, '{}'::jsonb),
    finished = public.honest_quiz_runs.finished or excluded.finished,
    user_agent = coalesce(excluded.user_agent, public.honest_quiz_runs.user_agent),
    photo_data_url = coalesce(excluded.photo_data_url, public.honest_quiz_runs.photo_data_url),
    updated_at = now()
  returning id into v_id;

  return v_id;
end;
$$;

revoke all on function public.honest_quiz_upsert(text, jsonb, boolean, text, text) from public;
grant execute on function public.honest_quiz_upsert(text, jsonb, boolean, text, text) to anon, authenticated;

create or replace function public.honest_quiz_admin_list(p_secret text)
returns setof jsonb
language plpgsql
stable
security definer
set search_path = public
set row_security to off
as $$
begin
  if not public._honest_quiz_admin_ok(p_secret) then
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

revoke all on function public.honest_quiz_admin_list(text) from public;
grant execute on function public.honest_quiz_admin_list(text) to anon, authenticated;

create or replace function public.honest_quiz_admin_get(p_secret text, p_id uuid)
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
  if not public._honest_quiz_admin_ok(p_secret) then
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

revoke all on function public.honest_quiz_admin_get(text, uuid) from public;
grant execute on function public.honest_quiz_admin_get(text, uuid) to anon, authenticated;

comment on table public.honest_quiz_runs is
  'TEMP romantic quiz runs — remove with honest-quiz feature.';
