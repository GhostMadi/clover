-- Лента профиля: опциональный фильтр по кластеру или только посты без кластера («Остальное»).
-- + RPC для числа таких постов (карточка в UI).

create or replace function public.count_user_posts_without_cluster(p_user_id uuid)
returns integer
language sql
stable
security invoker
set search_path = public
as $$
  select count(*)::integer
  from public.posts p
  where p.user_id = p_user_id
    and p.is_archived = false
    and p.deleted_at is null
    and p.cluster_id is null;
$$;

revoke all on function public.count_user_posts_without_cluster(uuid) from public;
grant execute on function public.count_user_posts_without_cluster(uuid) to authenticated, anon;

comment on function public.count_user_posts_without_cluster(uuid) is
  'Посты профиля без кластера (для карточки «Остальное»).';

-- Старая сигнатура (4 аргумента) — убираем, чтобы не плодить перегрузки.
drop function if exists public.list_user_feed_enriched_cursor(uuid, int, timestamptz, uuid);

-- Keyset-RPC: p_cluster_id и p_only_without_cluster.
create or replace function public.list_user_feed_enriched_cursor(
  p_user_id uuid,
  p_limit int default 24,
  p_cursor_created_at timestamptz default null,
  p_cursor_id uuid default null,
  p_cluster_id uuid default null,
  p_only_without_cluster boolean default false
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
      case
        when coalesce(p_only_without_cluster, false) then p.cluster_id is null
        when p_cluster_id is not null then p.cluster_id = p_cluster_id
        else true
      end
    )
    and (
      p_cursor_id is null
      or (p.created_at, p.id) < (p_cursor_created_at, p_cursor_id)
    )
  order by p.created_at desc, p.id desc
  limit least(greatest(coalesce(p_limit, 24), 1), 100);
$$;

revoke all on function public.list_user_feed_enriched_cursor(uuid, int, timestamptz, uuid, uuid, boolean) from public;
grant execute on function public.list_user_feed_enriched_cursor(uuid, int, timestamptz, uuid, uuid, boolean) to authenticated, anon;

comment on function public.list_user_feed_enriched_cursor(uuid, int, timestamptz, uuid, uuid, boolean) is
  'Profile feed keyset: optional cluster_id or only_without_cluster; cursor = older than (created_at, id).';
