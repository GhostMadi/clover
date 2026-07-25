-- In-app notifications for post/comment reactions and comments (stage 1).
-- Rules:
--   • post like/dislike  → post owner (not self)
--   • post root comment  → post owner (not self)
--   • comment reply      → parent comment author (not self)
--   • comment like/dislike → comment author (not self)
--   • reaction removed   → notification deleted (dedupe_key)
--   • comment soft/hard deleted → notifications for that comment removed
-- Follow notifications stay in notification_events (follow_user RPC).

-- --------------------------------------------------------------------------- notifications
create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  recipient_id uuid not null
    references public.profiles (id) on delete cascade,
  actor_id uuid not null
    references public.profiles (id) on delete cascade,
  kind text not null
    constraint notifications_kind_check check (kind in (
      'post_like',
      'post_dislike',
      'post_comment',
      'comment_reply',
      'comment_like',
      'comment_dislike'
    )),
  dedupe_key text not null,
  post_id uuid
    references public.posts (id) on delete cascade,
  comment_id uuid
    references public.comments (id) on delete cascade,
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  read_at timestamptz,
  constraint notifications_dedupe_key_unique unique (dedupe_key),
  constraint notifications_actor_not_recipient check (actor_id <> recipient_id)
);

create index if not exists notifications_recipient_created_idx
  on public.notifications (recipient_id, created_at desc);

create index if not exists notifications_recipient_unread_idx
  on public.notifications (recipient_id, created_at desc)
  where read_at is null;

create index if not exists notifications_post_id_idx
  on public.notifications (post_id)
  where post_id is not null;

create index if not exists notifications_comment_id_idx
  on public.notifications (comment_id)
  where comment_id is not null;

comment on table public.notifications is
  'In-app notifications for reactions and comments. Written by DB triggers; dedupe_key enables upsert/delete.';

alter table public.notifications enable row level security;

drop policy if exists notifications_select_own on public.notifications;
create policy notifications_select_own
  on public.notifications
  for select
  to authenticated
  using (recipient_id = auth.uid());

drop policy if exists notifications_update_own on public.notifications;
create policy notifications_update_own
  on public.notifications
  for update
  to authenticated
  using (recipient_id = auth.uid())
  with check (recipient_id = auth.uid());

revoke all on table public.notifications from anon;
grant select, update on table public.notifications to authenticated;

-- --------------------------------------------------------------------------- helpers
create or replace function public.notifications_should_deliver(p_recipient uuid, p_actor uuid)
returns boolean
language sql
stable
security definer
set search_path = public
set row_security to off
as $$
  select
    p_recipient is not null
    and p_actor is not null
    and p_recipient <> p_actor
    and exists (
      select 1
      from public.profiles pr
      where pr.id = p_recipient
        and pr.account_state <> 'hibernate'
        and pr.content_visible = true
    )
    and public.can_user_interact(p_actor, p_recipient);
$$;

revoke all on function public.notifications_should_deliver(uuid, uuid) from public;
grant execute on function public.notifications_should_deliver(uuid, uuid) to authenticated, anon;

create or replace function public.upsert_notification(
  p_recipient_id uuid,
  p_actor_id uuid,
  p_kind text,
  p_dedupe_key text,
  p_post_id uuid default null,
  p_comment_id uuid default null,
  p_payload jsonb default '{}'::jsonb
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
    payload
  )
  values (
    p_recipient_id,
    p_actor_id,
    p_kind,
    p_dedupe_key,
    p_post_id,
    p_comment_id,
    coalesce(p_payload, '{}'::jsonb)
  )
  on conflict (dedupe_key) do update
  set
    kind = excluded.kind,
    payload = excluded.payload,
    post_id = excluded.post_id,
    comment_id = excluded.comment_id,
    created_at = now(),
    read_at = null;
end;
$$;

revoke all on function public.upsert_notification(uuid, uuid, text, text, uuid, uuid, jsonb) from public;

create or replace function public.delete_notification_by_dedupe(p_dedupe_key text)
returns void
language sql
security definer
set search_path = public
set row_security to off
as $$
  delete from public.notifications
  where dedupe_key = p_dedupe_key;
$$;

revoke all on function public.delete_notification_by_dedupe(text) from public;

create or replace function public.delete_notifications_for_comment(p_comment_id uuid)
returns void
language sql
security definer
set search_path = public
set row_security to off
as $$
  delete from public.notifications
  where comment_id = p_comment_id;
$$;

revoke all on function public.delete_notifications_for_comment(uuid) from public;

-- --------------------------------------------------------------------------- post_reactions → notifications
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
    p_payload := jsonb_build_object('reaction_kind', v_kind)
  );

  return coalesce(new, old);
end;
$$;

drop trigger if exists trg_notifications_post_reactions on public.post_reactions;
create trigger trg_notifications_post_reactions
  after insert or update of kind or delete on public.post_reactions
  for each row
  execute function public.notifications_sync_post_reaction();

-- --------------------------------------------------------------------------- comments → notifications
create or replace function public.notifications_sync_comment()
returns trigger
language plpgsql
security definer
set search_path = public
set row_security to off
as $$
declare
  v_recipient uuid;
  v_kind text;
  v_dedupe text;
  v_parent_author uuid;
  v_post_owner uuid;
  v_archived boolean;
  v_deleted timestamptz;
begin
  if tg_op = 'DELETE' then
    perform public.delete_notifications_for_comment(old.id);
    return old;
  end if;

  if tg_op = 'UPDATE' then
    if new.is_deleted and not old.is_deleted then
      perform public.delete_notifications_for_comment(new.id);
    end if;
    return new;
  end if;

  -- INSERT
  if new.is_deleted then
    return new;
  end if;

  select p.user_id, p.is_archived, p.deleted_at
  into v_post_owner, v_archived, v_deleted
  from public.posts p
  where p.id = new.post_id;

  if not found or v_archived or v_deleted is not null then
    return new;
  end if;

  if new.parent_comment_id is null then
    v_recipient := v_post_owner;
    v_kind := 'post_comment';
    v_dedupe := 'post_comment:' || new.id::text;
  else
    select c.user_id
    into v_parent_author
    from public.comments c
    where c.id = new.parent_comment_id
      and not c.is_deleted;

    if not found then
      return new;
    end if;

    v_recipient := v_parent_author;
    v_kind := 'comment_reply';
    v_dedupe := 'comment_reply:' || new.id::text;
  end if;

  perform public.upsert_notification(
    p_recipient_id := v_recipient,
    p_actor_id := new.user_id,
    p_kind := v_kind,
    p_dedupe_key := v_dedupe,
    p_post_id := new.post_id,
    p_comment_id := new.id,
    p_payload := jsonb_build_object(
      'comment_preview', left(trim(new.text), 240),
      'is_reply', new.parent_comment_id is not null
    )
  );

  return new;
end;
$$;

drop trigger if exists trg_notifications_comments on public.comments;
create trigger trg_notifications_comments
  after insert or update of is_deleted or delete on public.comments
  for each row
  execute function public.notifications_sync_comment();

-- --------------------------------------------------------------------------- comment_reactions → notifications
create or replace function public.notifications_sync_comment_reaction()
returns trigger
language plpgsql
security definer
set search_path = public
set row_security to off
as $$
declare
  v_author uuid;
  v_post_id uuid;
  v_deleted boolean;
  v_archived boolean;
  v_post_deleted timestamptz;
  v_actor uuid;
  v_comment_id uuid;
  v_kind text;
  v_dedupe text;
begin
  if tg_op = 'DELETE' then
    v_actor := old.user_id;
    v_comment_id := old.comment_id;
    perform public.delete_notification_by_dedupe(
      'comment_reaction:' || v_comment_id::text || ':' || v_actor::text
    );
    return old;
  end if;

  v_actor := new.user_id;
  v_comment_id := new.comment_id;
  v_kind := new.kind;
  v_dedupe := 'comment_reaction:' || v_comment_id::text || ':' || v_actor::text;

  select c.user_id, c.post_id, c.is_deleted, p.is_archived, p.deleted_at
  into v_author, v_post_id, v_deleted, v_archived, v_post_deleted
  from public.comments c
  join public.posts p on p.id = c.post_id
  where c.id = v_comment_id;

  if not found or v_deleted or v_archived or v_post_deleted is not null then
    perform public.delete_notification_by_dedupe(v_dedupe);
    return coalesce(new, old);
  end if;

  if tg_op = 'UPDATE' and old.kind is not distinct from new.kind then
    return new;
  end if;

  perform public.upsert_notification(
    p_recipient_id := v_author,
    p_actor_id := v_actor,
    p_kind := case when v_kind = 'like' then 'comment_like' else 'comment_dislike' end,
    p_dedupe_key := v_dedupe,
    p_post_id := v_post_id,
    p_comment_id := v_comment_id,
    p_payload := jsonb_build_object('reaction_kind', v_kind)
  );

  return coalesce(new, old);
end;
$$;

drop trigger if exists trg_notifications_comment_reactions on public.comment_reactions;
create trigger trg_notifications_comment_reactions
  after insert or update of kind or delete on public.comment_reactions
  for each row
  execute function public.notifications_sync_comment_reaction();

-- --------------------------------------------------------------------------- list RPC (for app stage 2)
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
  post_preview_url text
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
    ) as post_preview_url
  from public.notifications n
  where n.recipient_id = auth.uid()
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
  'In-app notifications feed for current user with actor mini-profile and post preview.';

create or replace function public.mark_notifications_read(p_ids uuid[] default null)
returns int
language plpgsql
security invoker
set search_path = public
as $$
declare
  v_count int;
begin
  if auth.uid() is null then
    raise exception 'not_authenticated' using errcode = 'P0003';
  end if;

  if p_ids is null or cardinality(p_ids) = 0 then
    update public.notifications n
    set read_at = now()
    where n.recipient_id = auth.uid()
      and n.read_at is null;
  else
    update public.notifications n
    set read_at = now()
    where n.recipient_id = auth.uid()
      and n.id = any(p_ids)
      and n.read_at is null;
  end if;

  get diagnostics v_count = row_count;
  return v_count;
end;
$$;

revoke all on function public.mark_notifications_read(uuid[]) from public;
grant execute on function public.mark_notifications_read(uuid[]) to authenticated;

comment on function public.mark_notifications_read(uuid[]) is
  'Mark notifications read for current user; null/empty ids = mark all unread.';

notify pgrst, 'reload schema';
