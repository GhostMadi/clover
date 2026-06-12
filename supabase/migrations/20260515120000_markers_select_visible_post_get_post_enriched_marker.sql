-- Читать маркер могут не только владельцы: если существует видимый (по RLS) пост с posts.marker_id = markers.id.
-- Тогда владелец и гости видят в деталке то же, что владелец на карте/в кабинете (без сырой geography).

drop policy if exists markers_select_by_visible_post on public.markers;
create policy markers_select_by_visible_post
  on public.markers
  for select
  to authenticated, anon
  using (
    exists (
      select 1
      from public.posts p
      where p.marker_id = public.markers.id
    )
  );

comment on policy markers_select_by_visible_post on public.markers is
  'Маркер, привязанный к публикации, читается всем, кто видит пост (RLS на posts в подзапросе).';

create or replace function public.get_post_enriched(p_post_id uuid)
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
        ),
        'marker',
        case
          when m.id is not null then
            jsonb_build_object(
              'id', m.id,
              'text_emoji', m.text_emoji,
              'address_text', m.address_text,
              'event_time', m.event_time,
              'end_time', m.end_time,
              'status', m.status::text
            )
          else 'null'::jsonb
        end
      )
    ) as post,
    public.author_mini_json(pr.id) as author,
    r.kind as my_reaction,
    (ps_me.post_id is not null) as my_saved
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
  'Post detail: post JSON + post_media + optional marker (emoji/title/время/статус, без location).';

NOTIFY pgrst, 'reload schema';
