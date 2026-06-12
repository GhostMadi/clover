-- Posts: Storage for post media + sends events.
-- Depends on: 20260402140000_posts_post_media_engagement.sql (posts, post_media, counters, RLS baseline)

-- --------------------------------------------------------------------------- Storage bucket: post_media
-- Path convention: posts/{post_id}/{media_id}.(jpg|mp4|...)
-- Client rule: use upsert=true for overwrites; remove objects before deleting post to avoid orphaned files.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
  (
    'post_media',
    'post_media',
    true,
    104857600,
    array[
      'image/jpeg',
      'image/png',
      'image/webp',
      'video/mp4',
      'video/quicktime',
      'video/webm'
    ]::text[]
  )
on conflict (id) do update
set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists post_media_public_read on storage.objects;
drop policy if exists post_media_write_own on storage.objects;
drop policy if exists post_media_update_own on storage.objects;
drop policy if exists post_media_delete_own on storage.objects;

create policy post_media_public_read
  on storage.objects
  for select to public
  using (bucket_id = 'post_media');

create policy post_media_write_own
  on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'post_media'
    and (storage.foldername(name))[1] = 'posts'
    and exists (
      select 1
      from public.posts p
      where p.id::text = (storage.foldername(name))[2]
        and p.user_id = auth.uid()
    )
  );

create policy post_media_update_own
  on storage.objects
  for update to authenticated
  using (
    bucket_id = 'post_media'
    and (storage.foldername(name))[1] = 'posts'
    and exists (
      select 1
      from public.posts p
      where p.id::text = (storage.foldername(name))[2]
        and p.user_id = auth.uid()
    )
  )
  with check (
    bucket_id = 'post_media'
    and (storage.foldername(name))[1] = 'posts'
    and exists (
      select 1
      from public.posts p
      where p.id::text = (storage.foldername(name))[2]
        and p.user_id = auth.uid()
    )
  );

create policy post_media_delete_own
  on storage.objects
  for delete to authenticated
  using (
    bucket_id = 'post_media'
    and (storage.foldername(name))[1] = 'posts'
    and exists (
      select 1
      from public.posts p
      where p.id::text = (storage.foldername(name))[2]
        and p.user_id = auth.uid()
    )
  );

-- --------------------------------------------------------------------------- post_send_events (optional but "Instagram-like")
-- Lightweight events table for "send/share" actions; counters update in posts.sends_count.
create table if not exists public.post_send_events (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references public.posts (id) on delete cascade,
  sender_id uuid not null references public.profiles (id) on delete cascade,
  created_at timestamptz not null default now(),
  constraint post_send_events_sender_is_authed check (sender_id = auth.uid())
);

create index if not exists post_send_events_post_id_idx on public.post_send_events (post_id);
create index if not exists post_send_events_sender_id_idx on public.post_send_events (sender_id);

alter table public.post_send_events enable row level security;

drop policy if exists post_send_events_insert_own on public.post_send_events;
create policy post_send_events_insert_own
  on public.post_send_events
  for insert
  to authenticated
  with check (sender_id = auth.uid());

-- For now: no public select (sends — analytics, not social graph)
revoke all on public.post_send_events from anon, authenticated;
grant insert on public.post_send_events to authenticated;

-- Sync posts.sends_count
create or replace function public.post_sends_sync_post_count()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if tg_op = 'INSERT' then
    update public.posts set sends_count = sends_count + 1 where id = new.post_id;
    return new;
  elsif tg_op = 'DELETE' then
    update public.posts set sends_count = greatest(0, sends_count - 1) where id = old.post_id;
    return old;
  end if;
  return null;
end;
$$;

drop trigger if exists trg_post_sends_count_ins on public.post_send_events;
create trigger trg_post_sends_count_ins
  after insert on public.post_send_events
  for each row
  execute function public.post_sends_sync_post_count();

drop trigger if exists trg_post_sends_count_del on public.post_send_events;
create trigger trg_post_sends_count_del
  after delete on public.post_send_events
  for each row
  execute function public.post_sends_sync_post_count();
