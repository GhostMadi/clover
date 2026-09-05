-- Feed cards: include booking_service in post_enriched_root_json (same subtree as detail).

create or replace function public.post_enriched_root_json(p public.posts)
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
      'marker', public.marker_enriched_json(p.marker_id),
      'profile_filters', public.post_profile_filters_json(p.id),
      'booking_service', public.booking_service_enriched_json(p.booking_service_id)
    );
$$;

comment on function public.post_enriched_root_json(public.posts) is
  'Post row + media, tags, marker, profile_filters, booking_service for enriched RPCs.';

-- Detail can rely on root JSON only (booking_service already embedded).
drop function if exists public.get_post_enriched(uuid);

create function public.get_post_enriched(p_post_id uuid)
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
  from public.posts p
  inner join public.profiles pr on pr.id = p.user_id
  left join public.post_saves ps_me
    on ps_me.post_id = p.id
   and ps_me.user_id = auth.uid()
  where p.id = p_post_id;
$fn$;

revoke all on function public.get_post_enriched(uuid) from public;
grant execute on function public.get_post_enriched(uuid) to authenticated, anon;

comment on function public.get_post_enriched(uuid) is
  'Post detail: post_enriched_root_json (incl. booking_service when linked).';

notify pgrst, 'reload schema';
