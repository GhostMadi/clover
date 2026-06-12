-- Сброс контента: физическое удаление постов/кластеров и связанных строк (не soft-delete),
-- чтобы в БД не оставалось «следов» контента пользователя. Профиль (строка в profiles) сохраняется.

create or replace function public.reset_account()
returns void
language plpgsql
security definer
set search_path to public, storage
set row_security to off
as $$
declare
  uid uuid;
  last_ts timestamptz;
  post_ids text[];
begin
  uid := auth.uid();
  if uid is null then
    raise exception 'not_authenticated' using errcode = 'P0003';
  end if;

  select p.last_reset_at into last_ts
  from public.profiles p
  where p.id = uid;

  if last_ts is not null and now() < last_ts + interval '30 days' then
    raise exception 'reset_rate_limited' using errcode = 'P0005';
  end if;

  select array_agg(p.id::text) into post_ids
  from public.posts p
  where p.user_id = uid;

  -- 1) Посты пользователя — CASCADE убирает post_media, комментарии к ним, реакции, сохранения и т.д.
  delete from public.posts
  where user_id = uid;

  -- 2) Комментарии к чужим постам
  delete from public.comments
  where user_id = uid;

  -- 3) Реакции и сохранения на чужих постах
  delete from public.post_reactions
  where user_id = uid;

  delete from public.post_saves
  where user_id = uid;

  delete from public.comment_reactions
  where user_id = uid;

  -- 4) События «поделился» (если таблица развёрнута)
  if exists (
    select 1
    from information_schema.tables
    where table_schema = 'public'
      and table_name = 'post_send_events'
  ) then
    delete from public.post_send_events
    where sender_id = uid;
  end if;

  -- 5) Кластеры пользователя (чужие посты получат cluster_id = null по FK)
  delete from public.clusters
  where owner_id = uid;

  update public.profiles
  set
    avatar_url = null,
    background_url = null,
    reset_at = now(),
    last_reset_at = now()
  where id = uid;

  begin
    delete from storage.objects so
    where so.bucket_id in ('avatars', 'profile_backgrounds', 'cluster_covers')
      and (storage.foldername(so.name))[1] = uid::text;
  exception
    when others then
      null;
  end;

  if post_ids is not null and array_length(post_ids, 1) > 0 then
    begin
      delete from storage.objects so
      where so.bucket_id = 'post_media'
        and (storage.foldername(so.name))[1] = 'posts'
        and (storage.foldername(so.name))[2] = any(post_ids);
    exception
      when others then
        null;
    end;
  end if;

  begin
    perform public.refresh_hot_posts_24h();
  exception
    when others then
      null;
  end;
end;
$$;

revoke all on function public.reset_account() from public;
grant execute on function public.reset_account() to authenticated;

comment on function public.reset_account() is
  'Hard-delete user posts/clusters and related rows; clear profile visuals; storage + hot MV refresh best-effort.';
