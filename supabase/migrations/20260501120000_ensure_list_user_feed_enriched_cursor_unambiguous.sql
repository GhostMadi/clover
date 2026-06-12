-- PostgREST не должен видеть несколько рутин public.list_user_feed_enriched_cursor с разными списками аргументов —
-- иначе /rest/v1/rpc/list_user_feed_enriched_cursor может стабильно отвечать 404.
-- Оставляем одну сигнатуру (8-й аргумент: p_only_with_marker).

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

create or replace function public.list_user_feed_enriched_cursor(
  p_user_id uuid,
  p_limit int default 24,
  p_cursor_created_at timestamptz default null,
  p_cursor_id uuid default null,
  p_cluster_id uuid default null,
  p_only_without_cluster boolean default false,
  p_exclude_with_marker boolean default false,
  p_only_with_marker boolean default false
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
        when coalesce(p_only_with_marker, false) then p.marker_id is not null
        when coalesce(p_exclude_with_marker, false) then p.marker_id is null
        else true
      end
    )
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
$fn$;

revoke all on function public.list_user_feed_enriched_cursor(
  uuid, int, timestamptz, uuid, uuid, boolean, boolean, boolean
) from public;
grant execute on function public.list_user_feed_enriched_cursor(
  uuid, int, timestamptz, uuid, uuid, boolean, boolean, boolean
) to authenticated, anon;

comment on function public.list_user_feed_enriched_cursor(
  uuid, int, timestamptz, uuid, uuid, boolean, boolean, boolean
) is
  'Profile keyset: cluster / only_without_cluster / exclude_with_marker / only_with_marker. Single overload for PostgREST.';

-- Обновить кэш схемы API (сразу подхватывать create/drop function).
NOTIFY pgrst, 'reload schema';
