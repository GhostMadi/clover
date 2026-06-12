-- reset_account: явное удаление объектов в post_media и cluster_covers по префиксам путей
-- (папка поста, папка кластера), плюс профильные бакеты.

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
  pid text;
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

  delete from public.posts
  where user_id = uid;

  delete from public.comments
  where user_id = uid;

  delete from public.post_reactions
  where user_id = uid;

  delete from public.post_saves
  where user_id = uid;

  delete from public.comment_reactions
  where user_id = uid;

  if exists (
    select 1
    from information_schema.tables
    where table_schema = 'public'
      and table_name = 'post_send_events'
  ) then
    delete from public.post_send_events
    where sender_id = uid;
  end if;

  delete from public.clusters
  where owner_id = uid;

  update public.profiles
  set
    avatar_url = null,
    background_url = null,
    reset_at = now(),
    last_reset_at = now()
  where id = uid;

  -- post_media: bucket posts/{post_id}/... — удаляем всё под префиксом папки поста
  if post_ids is not null then
    foreach pid in array post_ids loop
      if pid is not null and length(trim(pid)) > 0 then
        begin
          delete from storage.objects so
          where so.bucket_id = 'post_media'
            and so.name like ('posts/' || trim(pid) || '/%');
        exception
          when others then
            null;
        end;
      end if;
    end loop;
  end if;

  -- cluster_covers: путь {uid}/{cluster_id}/cover.jpg — всё под префиксом uid/
  begin
    delete from storage.objects so
    where so.bucket_id = 'cluster_covers'
      and so.name like (uid::text || '/%');
  exception
    when others then
      null;
  end;

  begin
    delete from storage.objects so
    where so.bucket_id in ('avatars', 'profile_backgrounds')
      and (storage.foldername(so.name))[1] = uid::text;
  exception
    when others then
      null;
  end;

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
  'Hard-delete content; Storage: post_media по posts/{id}/, cluster_covers по {uid}/, аватары/фон; MV refresh best-effort.';
