-- Комментарии + моя реакция (like|dislike) одним запросом — аналог get_post_enriched / enriched-ленты.

create or replace function public.list_post_root_comments_enriched(
  p_post_id uuid,
  p_limit int default 24,
  p_offset int default 0
)
returns table (
  comment jsonb,
  my_kind text
)
language sql
stable
security invoker
set search_path = public
as $$
  select
    (
      to_jsonb(c.*)
      || jsonb_build_object(
        'profiles',
        jsonb_build_object(
          'username', pr.username,
          'avatar_url', pr.avatar_url
        )
      )
    ) as comment,
    r.kind as my_kind
  from public.comments c
  inner join public.profiles pr on pr.id = c.user_id
  left join public.comment_reactions r
    on r.comment_id = c.id
   and r.user_id = auth.uid()
  where c.post_id = p_post_id
    and c.parent_comment_id is null
    and c.is_deleted = false
  order by c.created_at desc
  limit greatest(0, least(coalesce(p_limit, 24), 200))
  offset greatest(0, coalesce(p_offset, 0));
$$;

comment on function public.list_post_root_comments_enriched(uuid, int, int) is
  'Корневые комментарии поста + profiles + my_kind (comment_reactions для auth.uid()).';

create or replace function public.list_comment_replies_enriched(
  p_post_id uuid,
  p_parent_comment_id uuid,
  p_limit int default 50,
  p_offset int default 0
)
returns table (
  comment jsonb,
  my_kind text
)
language sql
stable
security invoker
set search_path = public
as $$
  select
    (
      to_jsonb(c.*)
      || jsonb_build_object(
        'profiles',
        jsonb_build_object(
          'username', pr.username,
          'avatar_url', pr.avatar_url
        )
      )
    ) as comment,
    r.kind as my_kind
  from public.comments c
  inner join public.profiles pr on pr.id = c.user_id
  left join public.comment_reactions r
    on r.comment_id = c.id
   and r.user_id = auth.uid()
  where c.post_id = p_post_id
    and c.parent_comment_id = p_parent_comment_id
    and c.is_deleted = false
  order by c.created_at asc
  limit greatest(0, least(coalesce(p_limit, 50), 200))
  offset greatest(0, coalesce(p_offset, 0));
$$;

comment on function public.list_comment_replies_enriched(uuid, uuid, int, int) is
  'Прямые ответы на комментарий + profiles + my_kind.';

revoke all on function public.list_post_root_comments_enriched(uuid, int, int) from public;
grant execute on function public.list_post_root_comments_enriched(uuid, int, int) to anon, authenticated;

revoke all on function public.list_comment_replies_enriched(uuid, uuid, int, int) from public;
grant execute on function public.list_comment_replies_enriched(uuid, uuid, int, int) to anon, authenticated;
