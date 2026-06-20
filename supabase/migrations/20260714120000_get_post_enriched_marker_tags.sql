-- get_post_enriched: теги маркера в post.marker.tags

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
        ),
        'marker',
        case
          when m.id is not null then
            jsonb_build_object(
              'id', m.id,
              'text_emoji', m.text_emoji,
              'address_primary', m.address_primary,
              'address_cyrillic', m.address_cyrillic,
              'country_code', m.country_code,
              'city_code', m.city_code,
              'event_time', m.event_time,
              'end_time', m.end_time,
              'status', m.status::text,
              'tags', coalesce(
                (
                  select jsonb_agg(
                    jsonb_build_object(
                      'id', t.id,
                      'key', t.key,
                      'group_key', t.group_key
                    )
                    order by t.group_key nulls last, t.key
                  )
                  from public.marker_tag_links l
                  join public.marker_tags t on t.id = l.tag_id
                  where l.marker_id = m.id
                ),
                '[]'::jsonb
              )
            )
          else 'null'::jsonb
        end
      )
    ) as post,
    public.author_mini_json(pr.id) as author,
    r.kind as my_reaction,
    (ps_me.post_id is not null) as my_saved,
    (
      auth.uid() is not null
      and auth.uid() <> p.user_id
      and public.is_following_user(p.user_id)
    ) as my_following_author
  from public.posts p
  inner join public.profiles pr on pr.id = p.user_id
  left join public.markers m
    on m.id = p.marker_id
  left join public.post_reactions r
    on r.post_id = p.id
   and r.user_id = auth.uid()
  left join public.post_saves ps_me
    on ps_me.post_id = p.id
   and ps_me.user_id = auth.uid()
  where p.id = p_post_id;
$fn$;

revoke all on function public.get_post_enriched(uuid) from public;
grant execute on function public.get_post_enriched(uuid) to authenticated, anon;

comment on function public.get_post_enriched(uuid) is
  'Post detail: post.marker incl. tags[], author, my reaction/saved, my_following_author.';

notify pgrst, 'reload schema';
