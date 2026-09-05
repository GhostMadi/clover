-- Fix follow_user: PL/pgSQL requires PERFORM, not bare SELECT for side-effect calls.

create or replace function public.follow_user(p_target uuid)
returns void
language plpgsql
security definer
set search_path = public
set row_security to off
as $$
declare
  uid uuid;
  st text;
  n int;
  v_inserted int;
begin
  uid := auth.uid();
  if uid is null then
    raise exception 'not_authenticated' using errcode = 'P0003';
  end if;

  if p_target is null or p_target = uid then
    raise exception 'cannot_follow_self' using errcode = 'P0007';
  end if;

  select p.account_state into st
  from public.profiles p
  where p.id = p_target;

  if not found then
    raise exception 'user_not_found' using errcode = 'P0008';
  end if;

  if st = 'hibernate' then
    raise exception 'user_sleeping' using errcode = 'P0006';
  end if;

  if not public.can_user_interact(uid, p_target) then
    raise exception 'user_blocked' using errcode = 'P0009';
  end if;

  select count(*)::int into n
  from public.profile_follows f
  where f.follower_id = uid
    and f.created_at > now() - interval '1 hour';

  if n >= 200 then
    raise exception 'follow_rate_limited' using errcode = 'P0010';
  end if;

  insert into public.profile_follows (follower_id, following_id)
  values (uid, p_target)
  on conflict do nothing;

  get diagnostics v_inserted = row_count;

  if v_inserted > 0 then
    perform public.upsert_notification(
      p_recipient_id := p_target,
      p_actor_id := uid,
      p_kind := 'user_follow',
      p_dedupe_key := 'follow:' || uid::text || ':' || p_target::text,
      p_post_id := null,
      p_comment_id := null,
      p_payload := jsonb_build_object('type', 'follow')
    );
  end if;
end;
$$;
