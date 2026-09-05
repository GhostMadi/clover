-- Follow notifications in in-app feed + unread count for dashboard badge.

-- --------------------------------------------------------------------------- kinds
alter table public.notifications
  drop constraint if exists notifications_kind_check;

alter table public.notifications
  add constraint notifications_kind_check check (kind in (
    'post_like',
    'post_dislike',
    'post_comment',
    'comment_reply',
    'comment_like',
    'comment_dislike',
    'user_follow'
  ));

-- --------------------------------------------------------------------------- follow_user → notifications
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

-- Backfill historical follow events into in-app feed.
insert into public.notifications (
  recipient_id,
  actor_id,
  kind,
  dedupe_key,
  payload,
  created_at
)
select
  ne.recipient_id,
  (ne.payload ->> 'actor_id')::uuid,
  'user_follow',
  ne.dedupe_key,
  coalesce(ne.payload, '{}'::jsonb) - 'message',
  ne.created_at
from public.notification_events ne
where ne.payload ->> 'type' = 'follow'
  and (ne.payload ->> 'actor_id') ~* '^[0-9a-f-]{36}$'
on conflict (dedupe_key) do nothing;

-- --------------------------------------------------------------------------- list RPC (+ is_following_actor)
drop function if exists public.list_notifications_enriched_cursor(int, timestamptz, uuid);

create or replace function public.list_notifications_enriched_cursor(
  p_limit int default 24,
  p_cursor_created_at timestamptz default null,
  p_cursor_id uuid default null
)
returns table (
  id uuid,
  kind text,
  actor jsonb,
  post_id uuid,
  comment_id uuid,
  payload jsonb,
  created_at timestamptz,
  read_at timestamptz,
  post_preview_url text,
  is_following_actor boolean
)
language sql
stable
security invoker
set search_path = public
as $$
  select
    n.id,
    n.kind,
    public.author_mini_json(n.actor_id) as actor,
    n.post_id,
    n.comment_id,
    n.payload,
    n.created_at,
    n.read_at,
    (
      select pm.url
      from public.post_media pm
      where pm.post_id = n.post_id
      order by pm.sort_order asc
      limit 1
    ) as post_preview_url,
    public.is_following_user(n.actor_id) as is_following_actor
  from public.notifications n
  where n.recipient_id = auth.uid()
    and n.created_at >= (now() - interval '30 days')
    and (
      p_cursor_id is null
      or (n.created_at, n.id) < (p_cursor_created_at, p_cursor_id)
    )
  order by n.created_at desc, n.id desc
  limit least(greatest(coalesce(p_limit, 24), 1), 100);
$$;

revoke all on function public.list_notifications_enriched_cursor(int, timestamptz, uuid) from public;
grant execute on function public.list_notifications_enriched_cursor(int, timestamptz, uuid) to authenticated;

comment on function public.list_notifications_enriched_cursor(int, timestamptz, uuid) is
  'In-app notifications (last 30 days): reactions, comments, follows; actor + post preview + follow-back state.';

-- --------------------------------------------------------------------------- unread count (dashboard badge)
create or replace function public.count_unread_notifications()
returns int
language sql
stable
security invoker
set search_path = public
as $$
  select count(*)::int
  from public.notifications n
  where n.recipient_id = auth.uid()
    and n.read_at is null
    and n.created_at >= (now() - interval '30 days');
$$;

revoke all on function public.count_unread_notifications() from public;
grant execute on function public.count_unread_notifications() to authenticated;

comment on function public.count_unread_notifications() is
  'Unread in-app notifications in retention window (30 days).';
