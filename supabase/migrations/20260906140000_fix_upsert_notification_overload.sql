-- Fix likes/reactions 400: ambiguous upsert_notification overloads.
-- After booking added p_booking_id (8-arg), the old 7-arg function remained.
-- Trigger notifications_sync_post_reaction() called upsert_notification without
-- p_booking_id → PostgreSQL "function is not unique" → PostgREST 400 on set_post_reaction.

drop function if exists public.upsert_notification(uuid, uuid, text, text, uuid, uuid, jsonb);

-- Ensure the canonical 8-arg function exists (idempotent body from booking_notifications).
create or replace function public.upsert_notification(
  p_recipient_id uuid,
  p_actor_id uuid,
  p_kind text,
  p_dedupe_key text,
  p_post_id uuid default null,
  p_comment_id uuid default null,
  p_payload jsonb default '{}'::jsonb,
  p_booking_id uuid default null
)
returns void
language plpgsql
security definer
set search_path = public
set row_security to off
as $$
begin
  if not public.notifications_should_deliver(p_recipient_id, p_actor_id) then
    return;
  end if;

  insert into public.notifications (
    recipient_id,
    actor_id,
    kind,
    dedupe_key,
    post_id,
    comment_id,
    payload,
    booking_id
  )
  values (
    p_recipient_id,
    p_actor_id,
    p_kind,
    p_dedupe_key,
    p_post_id,
    p_comment_id,
    coalesce(p_payload, '{}'::jsonb),
    p_booking_id
  )
  on conflict (dedupe_key) do update
  set
    kind = excluded.kind,
    payload = excluded.payload,
    post_id = excluded.post_id,
    comment_id = excluded.comment_id,
    booking_id = excluded.booking_id,
    created_at = now(),
    read_at = null;
end;
$$;

revoke all on function public.upsert_notification(uuid, uuid, text, text, uuid, uuid, jsonb, uuid) from public;

-- Harden reaction RPC (bypass RLS inside SECURITY DEFINER).
create or replace function public.set_post_reaction(p_post_id uuid, p_kind text default null)
returns table (kind text)
language plpgsql
security definer
set search_path = public
set row_security to off
as $$
declare
  v_uid uuid := auth.uid();
begin
  if v_uid is null then
    raise exception 'auth required';
  end if;

  if p_post_id is null then
    raise exception 'invalid_arguments';
  end if;

  if p_kind is not null and p_kind not in ('like', 'dislike') then
    raise exception 'invalid kind';
  end if;

  if p_kind is null then
    delete from public.post_reactions
    where post_id = p_post_id and user_id = v_uid;
    return query select null::text;
    return;
  end if;

  insert into public.post_reactions(post_id, user_id, kind)
  values (p_post_id, v_uid, p_kind)
  on conflict (post_id, user_id)
  do update set kind = excluded.kind;

  return query select p_kind;
end;
$$;

revoke all on function public.set_post_reaction(uuid, text) from public;
grant execute on function public.set_post_reaction(uuid, text) to authenticated;

-- Explicit booking_id on reaction notification (no overload ambiguity).
create or replace function public.notifications_sync_post_reaction()
returns trigger
language plpgsql
security definer
set search_path = public
set row_security to off
as $$
declare
  v_owner uuid;
  v_archived boolean;
  v_deleted timestamptz;
  v_actor uuid;
  v_post_id uuid;
  v_kind text;
  v_dedupe text;
begin
  if tg_op = 'DELETE' then
    v_actor := old.user_id;
    v_post_id := old.post_id;
    perform public.delete_notification_by_dedupe(
      'post_reaction:' || v_post_id::text || ':' || v_actor::text
    );
    return old;
  end if;

  v_actor := new.user_id;
  v_post_id := new.post_id;
  v_kind := new.kind;
  v_dedupe := 'post_reaction:' || v_post_id::text || ':' || v_actor::text;

  select p.user_id, p.is_archived, p.deleted_at
  into v_owner, v_archived, v_deleted
  from public.posts p
  where p.id = v_post_id;

  if not found or v_archived or v_deleted is not null then
    perform public.delete_notification_by_dedupe(v_dedupe);
    return coalesce(new, old);
  end if;

  if tg_op = 'UPDATE' and old.kind is not distinct from new.kind then
    return new;
  end if;

  perform public.upsert_notification(
    p_recipient_id := v_owner,
    p_actor_id := v_actor,
    p_kind := case when v_kind = 'like' then 'post_like' else 'post_dislike' end,
    p_dedupe_key := v_dedupe,
    p_post_id := v_post_id,
    p_comment_id := null,
    p_payload := jsonb_build_object('reaction_kind', v_kind),
    p_booking_id := null
  );

  return coalesce(new, old);
end;
$$;

notify pgrst, 'reload schema';
