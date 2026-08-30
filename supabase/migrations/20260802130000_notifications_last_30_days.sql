-- Notifications feed: only last 30 days + cursor pagination.
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
    and n.created_at >= (now() - interval '30 days')
    and (
      p_cursor_id is null
      or (n.created_at, n.id) < (p_cursor_created_at, p_cursor_id)
    )
  order by n.created_at desc, n.id desc
  limit least(greatest(coalesce(p_limit, 24), 1), 100);
$$;

comment on function public.list_notifications_enriched_cursor(int, timestamptz, uuid) is
  'In-app notifications for current user (last 30 days), cursor pagination, actor + post preview.';
