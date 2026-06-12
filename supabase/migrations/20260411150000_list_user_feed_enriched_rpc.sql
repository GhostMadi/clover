-- Enriched user feed: posts + post_media + author profile + current user's reaction in one RPC.
-- Indexes: posts_user_feed_idx (user_id, created_at desc) + partial filter already exists in earlier migration.

create or replace function public.list_user_feed_enriched(
  p_user_id uuid,
  p_limit int default 24,
  p_offset int default 0
)
returns table (
  post jsonb,
  author jsonb,
  my_reaction text
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
    r.kind as my_reaction
  from public.posts p
  inner join public.profiles pr on pr.id = p.user_id
  left join public.post_reactions r
    on r.post_id = p.id
   and r.user_id = auth.uid()
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
  'Profile feed: post JSON (with post_media), author mini, current user reaction kind; RLS via invoker.';
