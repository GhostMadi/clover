-- delete_owned_post: DELETE из storage.objects без прав даёт 42501 → PostgREST 403.
-- Storage — best-effort (как reset_account); клиент дублирует через Storage API до RPC.

create or replace function public.delete_owned_post(p_post_id uuid)
returns void
language plpgsql
security definer
set search_path = public, storage
set row_security = off
as $$
declare
  v_uid uuid := auth.uid();
  v_owner uuid;
  v_marker_id uuid;
  v_remaining int;
begin
  if v_uid is null then
    raise exception 'not_authenticated' using errcode = 'P0003';
  end if;

  select p.user_id, p.marker_id
  into v_owner, v_marker_id
  from public.posts p
  where p.id = p_post_id;

  if not found then
    raise exception 'post_not_found' using errcode = 'P0002';
  end if;

  if v_owner is distinct from v_uid then
    raise exception 'forbidden' using errcode = 'P0004';
  end if;

  begin
    delete from storage.objects so
    where so.bucket_id = 'post_media'
      and so.name like ('posts/' || p_post_id::text || '/%');
  exception
    when others then
      null;
  end;

  delete from public.posts
  where id = p_post_id;

  if v_marker_id is not null then
    select count(*)::int
    into v_remaining
    from public.marker_posts mp
    where mp.marker_id = v_marker_id;

    if v_remaining = 0 then
      begin
        delete from public.markers m
        where m.id = v_marker_id
          and m.owner_id = v_uid;
      exception
        when others then
          null;
      end;
    end if;
  end if;
end;
$$;

comment on function public.delete_owned_post(uuid) is
  'Owner-only: best-effort post_media storage wipe, delete post (CASCADE), drop orphan marker.';

revoke all on function public.delete_owned_post(uuid) from public;
grant execute on function public.delete_owned_post(uuid) to authenticated;

alter function public.delete_owned_post(uuid) set row_security to off;
