-- Одна сигнатура: (p_args jsonb) — PostgREST стабильно находит RPC; тело — те же поля, что в клиенте.
-- Снимаем все перегрузки с разным числом аргументов (история миграций / старые 4–6 параметров).

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
  from (
    select * from jsonb_to_record(coalesce(p_args, '{}'::jsonb)) as x(
      p_user_id uuid,
      p_limit int,
      p_cursor_created_at timestamptz,
      p_cursor_id uuid,
      p_cluster_id uuid,
      p_only_without_cluster boolean,
      p_exclude_with_marker boolean,
      p_only_with_marker boolean
    )
  ) a
  inner join public.posts p
    on p.user_id = a.p_user_id
  inner join public.profiles pr on pr.id = p.user_id
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
    and (
      a.p_cursor_id is null
      or (p.created_at, p.id) < (a.p_cursor_created_at, a.p_cursor_id)
    )
  order by p.created_at desc, p.id desc
  -- В LANGUAGE sql LIMIT не может ссылаться на поля строки (a.p_limit); только на аргументы функции.
  limit (least(greatest(coalesce((p_args->>'p_limit')::int, 24), 1), 100));
$fn$;

revoke all on function public.list_user_feed_enriched_cursor(jsonb) from public;
grant execute on function public.list_user_feed_enriched_cursor(jsonb) to authenticated, anon;

comment on function public.list_user_feed_enriched_cursor(jsonb) is
  'Profile keyset: единый аргумент p_args (json) — поля p_user_id, p_limit, p_cursor_*, p_cluster_id, p_only_without_cluster, p_exclude_with_marker, p_only_with_marker.';

NOTIFY pgrst, 'reload schema';
