-- Enriched feed RPCs: добавить my_saved для текущего пользователя (как my_reaction).
-- Postgres: нельзя сменить RETURNS TABLE через CREATE OR REPLACE — дропаем и создаём заново.
drop function if exists public.list_user_feed_enriched(uuid, int, int);
drop function if exists public.list_hot_feed_enriched(int, int);
drop function if exists public.list_user_feed_enriched_cursor(uuid, int, timestamptz, uuid);

create function public.list_user_feed_enriched(
  p_user_id uuid,
  p_limit int default 24,
  p_offset int default 0
)
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
as $$
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
        )
      )
    ) as post,
    jsonb_build_object(
      'id', pr.id,
      'username', pr.username,
      'avatar_url', pr.avatar_url
    ) as author,
    r.kind as my_reaction,
    (ps_me.post_id is not null) as my_saved
  from public.posts p
  inner join public.profiles pr on pr.id = p.user_id
  left join public.post_reactions r
    on r.post_id = p.id
   and r.user_id = auth.uid()
  left join public.post_saves ps_me
    on ps_me.post_id = p.id
   and ps_me.user_id = auth.uid()
  where p.user_id = p_user_id
    and p.is_archived = false
    and p.deleted_at is null
  order by p.created_at desc
  limit least(greatest(coalesce(p_limit, 24), 1), 100)
  offset greatest(coalesce(p_offset, 0), 0);
$$;

revoke all on function public.list_user_feed_enriched(uuid, int, int) from public;
grant execute on function public.list_user_feed_enriched(uuid, int, int) to authenticated, anon;

comment on function public.list_user_feed_enriched(uuid, int, int) is
  'Profile feed: post JSON (with post_media), author mini, my reaction, my_saved flag; RLS via invoker.';

-- --------------------------------------------------------------------------- list_hot_feed_enriched

create function public.list_hot_feed_enriched(
  p_limit int default 24,
  p_offset int default 0
)
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
as $$
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
        )
      )
    ) as post,
    jsonb_build_object(
      'id', pr.id,
      'username', pr.username,
      'avatar_url', pr.avatar_url
    ) as author,
    r.kind as my_reaction,
    (ps_me.post_id is not null) as my_saved
  from public.hot_posts_24h h
  inner join public.posts p on p.id = h.post_id
  inner join public.profiles pr on pr.id = p.user_id
  left join public.post_reactions r
    on r.post_id = p.id
   and r.user_id = auth.uid()
  left join public.post_saves ps_me
    on ps_me.post_id = p.id
   and ps_me.user_id = auth.uid()
  where p.is_archived = false
    and p.deleted_at is null
  order by h.score_24h desc, p.created_at desc
  limit least(greatest(coalesce(p_limit, 24), 1), 100)
  offset greatest(coalesce(p_offset, 0), 0);
$$;

revoke all on function public.list_hot_feed_enriched(int, int) from public;
grant execute on function public.list_hot_feed_enriched(int, int) to authenticated, anon;

comment on function public.list_hot_feed_enriched(int, int) is
  'Hot MV: post JSON + author + my reaction + my_saved.';

-- --------------------------------------------------------------------------- list_user_feed_enriched_cursor

create function public.list_user_feed_enriched_cursor(
  p_user_id uuid,
  p_limit int default 24,
  p_cursor_created_at timestamptz default null,
  p_cursor_id uuid default null
)
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
as $$
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
        )
      )
    ) as post,
    jsonb_build_object(
      'id', pr.id,
      'username', pr.username,
      'avatar_url', pr.avatar_url
    ) as author,
    r.kind as my_reaction,
    (ps_me.post_id is not null) as my_saved
  from public.posts p
  inner join public.profiles pr on pr.id = p.user_id
  left join public.post_reactions r
    on r.post_id = p.id
   and r.user_id = auth.uid()
  left join public.post_saves ps_me
    on ps_me.post_id = p.id
   and ps_me.user_id = auth.uid()
  where p.user_id = p_user_id
    and p.is_archived = false
    and p.deleted_at is null
    and (
      p_cursor_id is null
      or (p.created_at, p.id) < (p_cursor_created_at, p_cursor_id)
    )
  order by p.created_at desc, p.id desc
  limit least(greatest(coalesce(p_limit, 24), 1), 100);
$$;

revoke all on function public.list_user_feed_enriched_cursor(uuid, int, timestamptz, uuid) from public;
grant execute on function public.list_user_feed_enriched_cursor(uuid, int, timestamptz, uuid) to authenticated, anon;

comment on function public.list_user_feed_enriched_cursor(uuid, int, timestamptz, uuid) is
  'Profile feed keyset: post + author + my reaction + my_saved; cursor = older than (created_at, id).';
