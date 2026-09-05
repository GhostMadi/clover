-- Profile grid / list_user_feed: post + media + tags + filters, без marker payload.
-- marker_id остаётся на posts; полный marker — только get_post_enriched.

create or replace function public.post_enriched_list_json(p public.posts)
returns jsonb
language sql
stable
set search_path = public
as $$
  select
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
      'tags', public.post_tags_json(p.id),
      'profile_filters', public.post_profile_filters_json(p.id)
    );
$$;

comment on function public.post_enriched_list_json(public.posts) is
  'List/card JSON: post row + media + tags + profile_filters; no marker subtree (use get_post_enriched for detail).';

revoke all on function public.post_enriched_list_json(public.posts) from public;
grant execute on function public.post_enriched_list_json(public.posts) to authenticated, anon;

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
    public.post_enriched_list_json(p) as post,
    jsonb_build_object(
      'id', pr.id,
      'username', pr.username,
      'avatar_url', pr.avatar_url
    ) as author,
    public.get_my_post_reaction_kind(p.id) as my_reaction,
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
      p_only_with_marker boolean,
      p_filter_selection_keys text[]
    )
  ) a
  inner join public.posts p
    on p.user_id = a.p_user_id
  inner join public.profiles pr on pr.id = p.user_id
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
    and public.post_matches_profile_filter_selection(
      p.id,
      a.p_user_id,
      a.p_filter_selection_keys
    )
    and (
      a.p_cursor_id is null
      or (p.created_at, p.id) < (a.p_cursor_created_at, a.p_cursor_id)
    )
  order by p.created_at desc, p.id desc
  limit (least(greatest(coalesce((p_args->>'p_limit')::int, 24), 1), 100));
$fn$;

comment on function public.list_user_feed_enriched_cursor(jsonb) is
  'Profile feed cursor; lightweight post JSON (no marker payload). Detail: get_post_enriched.';

revoke all on function public.list_user_feed_enriched_cursor(jsonb) from public;
grant execute on function public.list_user_feed_enriched_cursor(jsonb) to authenticated, anon;

notify pgrst, 'reload schema';
