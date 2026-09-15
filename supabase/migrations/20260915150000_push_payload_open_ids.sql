-- Push/open contract: booking_id + social actor_id in outbox payload (FCM data).
-- Spec: docs/supabase/SPEC_PUSH_FCM.md § FCM data open contract

create or replace function public.booking_notification_payload(p_booking public.bookings)
returns jsonb
language sql
immutable
as $$
  select jsonb_build_object(
    'booking_id', p_booking.id,
    'service_title', p_booking.service_title,
    'service_emoji', p_booking.service_emoji,
    'starts_at', p_booking.starts_at,
    'ends_at', p_booking.ends_at,
    'bonus_earn_amount', greatest(coalesce(p_booking.service_bonus_earn_amount, 0), 0)
  );
$$;

comment on function public.booking_notification_payload(public.bookings) is
  'Booking notification/push payload; always includes booking_id for client open.';

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
declare
  v_is_new boolean;
  v_actor_username text;
  v_title text;
  v_body text;
  v_payload jsonb;
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
    read_at = null
  returning (xmax = 0) into v_is_new;

  -- Lock-screen push only on first insert (not on reaction toggle refresh).
  if not coalesce(v_is_new, false) then
    return;
  end if;

  if p_kind not in (
    'post_like',
    'post_dislike',
    'post_comment',
    'comment_reply',
    'comment_like',
    'comment_dislike',
    'user_follow'
  ) then
    return;
  end if;

  select nullif(trim(p.username), '')
  into v_actor_username
  from public.profiles p
  where p.id = p_actor_id;

  v_title := case p_kind
    when 'post_like' then 'new_like'
    when 'post_dislike' then 'new_dislike'
    when 'post_comment' then 'new_comment'
    when 'comment_reply' then 'new_reply'
    when 'comment_like' then 'new_comment_like'
    when 'comment_dislike' then 'new_comment_dislike'
    when 'user_follow' then 'new_follower'
    else 'notification'
  end;

  v_body := case p_kind
    when 'post_like' then 'liked_your_post'
    when 'post_dislike' then 'disliked_your_post'
    when 'post_comment' then 'commented_your_post'
    when 'comment_reply' then 'replied_to_comment'
    when 'comment_like' then 'liked_your_comment'
    when 'comment_dislike' then 'disliked_your_comment'
    when 'user_follow' then 'started_following_you'
    else 'notification'
  end;

  v_payload := coalesce(p_payload, '{}'::jsonb)
    || jsonb_build_object(
      'preview_key', v_body,
      'actor_id', p_actor_id,
      'actor_username', coalesce(v_actor_username, 'user'),
      'post_id', p_post_id,
      'comment_id', p_comment_id
    );

  insert into public.push_outbox (user_id, kind, title, body, payload)
  values (
    p_recipient_id,
    p_kind,
    v_title,
    v_body,
    v_payload
  );
end;
$$;

comment on function public.upsert_notification(uuid, uuid, text, text, uuid, uuid, jsonb, uuid) is
  'Upsert in-app notification; social kinds enqueue push_outbox with actor_id/post_id for FCM open.';
