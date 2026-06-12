-- «Сохранённое» не показывает посты в архиве (как лента профиля).

create or replace function public.list_my_saved_posts(
  p_limit int default 24,
  p_offset int default 0
)
returns table (post jsonb)
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
    ) as post
  from public.post_saves ps
  inner join public.posts p on p.id = ps.post_id
  where ps.user_id = auth.uid()
    and p.deleted_at is null
    and p.is_archived = false
  order by ps.created_at desc
  limit least(greatest(coalesce(p_limit, 24), 1), 100)
  offset greatest(coalesce(p_offset, 0), 0);
$$;

comment on function public.list_my_saved_posts(int, int) is
  'Текущий пользователь: сохранённые посты (без soft-deleted и без архива), JSON с post_media, новые сверху.';
