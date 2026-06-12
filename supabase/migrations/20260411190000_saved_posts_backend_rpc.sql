-- Сохранённые посты: вся логика на стороне БД; клиент только вызывает RPC (без прямого доступа к post_saves из приложения при желании можно ужесточить GRANT).

-- --------------------------------------------------------------------------- list_my_saved_posts
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
  order by ps.created_at desc
  limit least(greatest(coalesce(p_limit, 24), 1), 100)
  offset greatest(coalesce(p_offset, 0), 0);
$$;

revoke all on function public.list_my_saved_posts(int, int) from public;
grant execute on function public.list_my_saved_posts(int, int) to authenticated;

comment on function public.list_my_saved_posts(int, int) is
  'Текущий пользователь: сохранённые посты (JSON как в list_user_feed_enriched), новые сверху.';

-- --------------------------------------------------------------------------- is_post_saved_by_me
create or replace function public.is_post_saved_by_me(p_post_id uuid)
returns boolean
language sql
stable
security invoker
set search_path = public
as $$
  select exists(
    select 1
    from public.post_saves s
    where s.user_id = auth.uid()
      and s.post_id = p_post_id
  );
$$;

revoke all on function public.is_post_saved_by_me(uuid) from public;
grant execute on function public.is_post_saved_by_me(uuid) to authenticated;

-- --------------------------------------------------------------------------- save_post (идемпотентно)
create or replace function public.save_post(p_post_id uuid)
returns void
language plpgsql
security invoker
set search_path = public
as $$
begin
  insert into public.post_saves (post_id, user_id)
  values (p_post_id, auth.uid())
  on conflict (post_id, user_id) do nothing;
end;
$$;

revoke all on function public.save_post(uuid) from public;
grant execute on function public.save_post(uuid) to authenticated;

-- --------------------------------------------------------------------------- unsave_post
create or replace function public.unsave_post(p_post_id uuid)
returns void
language plpgsql
security invoker
set search_path = public
as $$
begin
  delete from public.post_saves
  where post_id = p_post_id
    and user_id = auth.uid();
end;
$$;

revoke all on function public.unsave_post(uuid) from public;
grant execute on function public.unsave_post(uuid) to authenticated;
