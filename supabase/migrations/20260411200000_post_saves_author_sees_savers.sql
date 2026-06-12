-- Одна таблица public.post_saves (post_id, user_id): и «мои сохранения», и «кто сохранил пост».
-- Счётчик posts.saves_count уже обновляется триггерами post_saves_sync_post_count (старая миграция).
--
-- Раньше SELECT был только на свои строки (user_id = auth.uid()). Добавляем политику OR:
-- автор поста может читать все строки post_saves для своих постов — чтобы видеть список сохранивших.

drop policy if exists post_saves_select_author_of_post on public.post_saves;
create policy post_saves_select_author_of_post
  on public.post_saves
  for select
  to authenticated
  using (
    exists (
      select 1 from public.posts p
      where p.id = post_saves.post_id
        and p.user_id = auth.uid()
    )
  );

comment on policy post_saves_select_author_of_post on public.post_saves is
  'Автор поста видит все сохранения своего поста (список пользователей).';

-- --------------------------------------------------------------------------- list_post_savers (RPC для приложения)
create or replace function public.list_post_savers(
  p_post_id uuid,
  p_limit int default 50,
  p_offset int default 0
)
returns table (
  user_id uuid,
  username text,
  avatar_url text,
  saved_at timestamptz
)
language sql
stable
security invoker
set search_path = public
as $$
  select
    pr.id as user_id,
    pr.username,
    pr.avatar_url,
    ps.created_at as saved_at
  from public.post_saves ps
  inner join public.profiles pr on pr.id = ps.user_id
  where ps.post_id = p_post_id
  order by ps.created_at desc
  limit least(greatest(coalesce(p_limit, 50), 1), 200)
  offset greatest(coalesce(p_offset, 0), 0);
$$;

revoke all on function public.list_post_savers(uuid, int, int) from public;
grant execute on function public.list_post_savers(uuid, int, int) to authenticated;

comment on function public.list_post_savers(uuid, int, int) is
  'Список профилей, сохранивших пост; видит только автор поста (RLS на post_saves + profiles).';
