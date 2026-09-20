-- Batch get_posts_enriched: same card shape as get_post_enriched, one round-trip for map stack / multi-open.

create or replace function public.get_posts_enriched(p_post_ids uuid[])
returns table (
  post jsonb,
  author jsonb,
  my_reaction text,
  my_saved boolean,
  my_following_author boolean
)
language sql
stable
security invoker
set search_path = public
as $fn$
  with requested as (
    select
      u.id,
      min(u.ord) as ord
    from unnest(coalesce(p_post_ids, '{}'::uuid[])) with ordinality as u(id, ord)
    where u.id is not null
    group by u.id
    order by min(u.ord)
    limit 50
  )
  select
    public.post_enriched_root_json(p) as post,
    public.author_mini_json(pr.id) as author,
    public.get_my_post_reaction_kind(p.id) as my_reaction,
    (ps_me.post_id is not null) as my_saved,
    (
      auth.uid() is not null
      and auth.uid() <> p.user_id
      and public.is_following_user(p.user_id)
    ) as my_following_author
  from requested r
  inner join public.posts p on p.id = r.id
  inner join public.profiles pr on pr.id = p.user_id
  left join public.post_saves ps_me
    on ps_me.post_id = p.id
   and ps_me.user_id = auth.uid()
  where p.deleted_at is null
  order by r.ord;
$fn$;

revoke all on function public.get_posts_enriched(uuid[]) from public;
grant execute on function public.get_posts_enriched(uuid[]) to authenticated, anon;

comment on function public.get_posts_enriched(uuid[]) is
  'Batch of get_post_enriched cards (max 50). Order follows first occurrence in p_post_ids. Map stack / multi detail.';

notify pgrst, 'reload schema';
