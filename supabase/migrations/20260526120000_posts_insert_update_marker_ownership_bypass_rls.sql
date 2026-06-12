-- REST POST on posts падал (500) при create с marker_id: with_check на posts читал markers
-- под обычным RLS, политика markers (в т.ч. подзапрос к posts) давала тяжёлую/циклическую проверку.
-- Проверка владельца вынесена в SECURITY DEFINER + row_security off (см. chat_participants 20260427120100).

create or replace function public.posts_marker_ownership_allows(p_marker_id uuid)
returns boolean
language sql
security definer
set search_path = public
set row_security to off
stable
as $$
  select p_marker_id is null
    or exists (
      select 1
      from public.markers m
      where m.id = p_marker_id
        and m.owner_id = auth.uid()
    );
$$;

revoke all on function public.posts_marker_ownership_allows(uuid) from public;
grant execute on function public.posts_marker_ownership_allows(uuid) to authenticated;

drop policy if exists posts_insert_author on public.posts;
create policy posts_insert_author
  on public.posts
  for insert
  to authenticated
  with check (
    user_id = auth.uid()
    and (
      cluster_id is null
      or exists (
        select 1 from public.clusters c
        where c.id = cluster_id
          and c.owner_id = auth.uid()
      )
    )
    and public.posts_marker_ownership_allows(marker_id)
  );

drop policy if exists posts_update_author on public.posts;
create policy posts_update_author
  on public.posts
  for update
  to authenticated
  using (user_id = auth.uid())
  with check (
    user_id = auth.uid()
    and (
      cluster_id is null
      or exists (
        select 1 from public.clusters c
        where c.id = cluster_id
          and c.owner_id = auth.uid()
      )
    )
    and public.posts_marker_ownership_allows(marker_id)
  );

notify pgrst, 'reload schema';
