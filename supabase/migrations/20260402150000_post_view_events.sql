-- События просмотров постов: append-only + батч-агрегация в posts.views_count.
-- Зависимость: public.posts (миграция posts_post_media_engagement).

-- --------------------------------------------------------------------------- post_view_events
create table if not exists public.post_view_events (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null
    references public.posts (id) on delete cascade,
  viewer_hash text not null
    constraint post_view_events_viewer_hash_len check (char_length(viewer_hash) between 1 and 512),
  bucket_date date not null,
  processed boolean not null default false,
  created_at timestamptz not null default now(),
  constraint post_view_events_unique_dedup unique (post_id, viewer_hash, bucket_date)
);

create index if not exists post_view_events_pending_idx
  on public.post_view_events (post_id)
  where not processed;

create index if not exists post_view_events_created_idx
  on public.post_view_events (created_at);

comment on table public.post_view_events is 'Сырые просмотры; дедуп по (post_id, viewer_hash, bucket_date); агрегация в posts.views_count батчем';
comment on column public.post_view_events.viewer_hash is 'Отпечаток зрителя: hash(user_id|device|salt) — не PII в сыром виде по возможности';
comment on column public.post_view_events.bucket_date is 'Обычно date (дневной дедуп); для часовых бакетов — отдельная миграция (например bucket_ts timestamptz)';
comment on column public.post_view_events.processed is 'false — ещё не учтено в posts.views_count; сбрасывает батч-функция';

-- --------------------------------------------------------------------------- Батч: перенос сумм в posts и пометка событий (SECURITY DEFINER — обход RLS на posts)
create or replace function public.flush_post_view_events_batch(p_limit integer default 5000)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  marked integer;
begin
  with batch_ids as (
    select id, post_id
    from public.post_view_events
    where not processed
    order by created_at
    limit greatest(1, p_limit)
    for update skip locked
  ),
  agg as (
    select b.post_id, count(*)::bigint as cnt
    from batch_ids b
    group by b.post_id
  ),
  u1 as (
    update public.posts p
    set views_count = p.views_count + agg.cnt
    from agg
    where p.id = agg.post_id
  ),
  u2 as (
    update public.post_view_events ev
    set processed = true
    where ev.id in (select id from batch_ids)
    returning ev.id
  )
  select count(*)::integer into marked from u2;

  return coalesce(marked, 0);
end;
$$;

comment on function public.flush_post_view_events_batch(integer) is
  'Вызывать по cron (1–5 мин) или из Edge; обрабатывает пачку unprocessed (limit) и возвращает число помеченных событий. Не вызывать из клиента.';

revoke all on function public.flush_post_view_events_batch(integer) from public;
grant execute on function public.flush_post_view_events_batch(integer) to service_role;
-- pg_cron / SQL в Dashboard часто выполняется от имени postgres
grant execute on function public.flush_post_view_events_batch(integer) to postgres;

-- --------------------------------------------------------------------------- RLS: клиент только вставляет событие по видимому посту; чтение событий — не для anon/authenticated
alter table public.post_view_events enable row level security;

drop policy if exists post_view_events_insert_visible_post on public.post_view_events;
create policy post_view_events_insert_visible_post
  on public.post_view_events
  for insert
  to authenticated
  with check (
    exists (
      select 1 from public.posts p
      where p.id = post_id
        and (
          p.user_id = auth.uid()
          or (p.deleted_at is null and not p.is_archived)
        )
    )
  );

-- Явно не даём SELECT обычным ролям (агрегация — service_role / cron)
-- service_role обходит RLS

-- --------------------------------------------------------------------------- Grants
grant insert on public.post_view_events to authenticated;
