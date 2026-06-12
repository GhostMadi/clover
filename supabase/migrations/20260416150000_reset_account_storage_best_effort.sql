-- reset_account: DELETE из storage.objects без прав часто даёт 42501 → PostgREST 403.
-- Оставляем сброс данных в public.* обязательным; очистку Storage — best-effort (не роняем RPC).

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

  update public.posts
  set deleted_at = now()
  where user_id = uid
    and deleted_at is null;

  update public.clusters
  set
    deleted_at = now(),
    deleted_reason = 'reset'
  where owner_id = uid
    and deleted_at is null;

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
end;
$$;

revoke all on function public.reset_account() from public;
grant execute on function public.reset_account() to authenticated;

comment on function public.reset_account() is
  'Reset: soft-delete posts/clusters, clear profile visuals + reset_at; storage cleanup best-effort (errors ignored).';
