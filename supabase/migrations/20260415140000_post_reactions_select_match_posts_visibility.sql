-- Раньше SELECT на post_reactions требовал not is_archived — лайк на архиве не читался обратно.
-- Условия is_archived / «как у ленты» не дублируем: достаточно связи с постом без soft delete;
-- какие посты видны пользователю (включая свой архив), решает RLS на public.posts.

drop policy if exists post_reactions_select_visible on public.post_reactions;

create policy post_reactions_select_visible
  on public.post_reactions
  for select
  to anon, authenticated
  using (
    exists (
      select 1
      from public.posts p
      where p.id = post_reactions.post_id
        and p.deleted_at is null
    )
  );

comment on policy post_reactions_select_visible on public.post_reactions is
  'Реакция видна, если существует не удалённый пост; видимость самой строки posts — через RLS posts.';
