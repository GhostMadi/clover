-- Post ↔ booking service: posts.booking_service_id (optional showcase link).

alter table public.posts
  add column if not exists booking_service_id uuid
  references public.booking_services (id) on delete set null;

comment on column public.posts.booking_service_id is
  'Опциональная витрина услуги: CTA «Записаться на эту услугу» с деталки поста.';

create index if not exists posts_booking_service_id_idx
  on public.posts (booking_service_id)
  where booking_service_id is not null
    and deleted_at is null;

-- post.user_id must own the linked service (same host).
create or replace function public.posts_assert_booking_service_owner()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if new.booking_service_id is null then
    return new;
  end if;

  if not exists (
    select 1
    from public.booking_services s
    where s.id = new.booking_service_id
      and s.host_id = new.user_id
  ) then
    raise exception 'booking_service_not_owned' using errcode = 'P0030';
  end if;

  return new;
end;
$$;

drop trigger if exists trg_posts_assert_booking_service_owner on public.posts;
create trigger trg_posts_assert_booking_service_owner
  before insert or update of booking_service_id
  on public.posts
  for each row
  execute function public.posts_assert_booking_service_owner();

-- Guest read: service visible when linked to a non-deleted post (RLS on posts in subquery).
drop policy if exists booking_services_select_by_visible_post on public.booking_services;
create policy booking_services_select_by_visible_post
  on public.booking_services
  for select
  to authenticated, anon
  using (
    exists (
      select 1
      from public.posts p
      where p.booking_service_id = public.booking_services.id
        and p.deleted_at is null
    )
  );

comment on policy booking_services_select_by_visible_post on public.booking_services is
  'Услуга, привязанная к посту, читается всем, кто видит пост.';

-- Explicit link/unlink from app (owner only).
create or replace function public.set_post_booking_service(
  p_post_id uuid,
  p_service_id uuid default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  uid uuid := auth.uid();
  v_post public.posts%rowtype;
begin
  if uid is null then
    raise exception 'not_authenticated' using errcode = 'P0001';
  end if;

  select * into v_post
  from public.posts p
  where p.id = p_post_id
    and p.user_id = uid
    and p.deleted_at is null;

  if not found then
    raise exception 'post_not_found' using errcode = 'P0002';
  end if;

  if p_service_id is not null then
    if not exists (
      select 1
      from public.booking_services s
      where s.id = p_service_id
        and s.host_id = uid
    ) then
      raise exception 'booking_service_not_owned' using errcode = 'P0030';
    end if;
  end if;

  update public.posts
  set booking_service_id = p_service_id
  where id = p_post_id;
end;
$$;

comment on function public.set_post_booking_service(uuid, uuid) is
  'Host: link or unlink booking service on own post (null = unlink).';

revoke all on function public.set_post_booking_service(uuid, uuid) from public;
grant execute on function public.set_post_booking_service(uuid, uuid) to authenticated;

-- Detail-only subtree (list RPCs keep booking_service_id from to_jsonb(p.*) only).
create or replace function public.booking_service_enriched_json(p_service_id uuid)
returns jsonb
language sql
stable
set search_path = public
as $$
  select case
    when p_service_id is null then 'null'::jsonb
    else coalesce(
      (
        select jsonb_build_object(
          'id', bs.id,
          'title', bs.title,
          'emoji_text', bs.emoji_text,
          'price', bs.price,
          'duration_minutes', bs.duration_minutes,
          'is_active', bs.is_active
        )
        from public.booking_services bs
        where bs.id = p_service_id
      ),
      'null'::jsonb
    )
  end;
$$;

comment on function public.booking_service_enriched_json(uuid) is
  'Booking service subtree for post detail JSON (null → json null; RLS on booking_services applies).';

revoke all on function public.booking_service_enriched_json(uuid) from public;
grant execute on function public.booking_service_enriched_json(uuid) to authenticated, anon;

-- Detail enriched: optional booking_service snippet for CTA.
-- Must DROP first: return type differs from legacy 4-column versions on some DBs.
drop function if exists public.get_post_enriched(uuid);

create function public.get_post_enriched(p_post_id uuid)
returns table (
  post jsonb,
  author jsonb,
  my_reaction text,
  my_saved boolean,
  my_following_author boolean
)
language sql
stable
security invoker
set search_path = public
as $fn$
  select
    public.post_enriched_root_json(p)
    || jsonb_build_object(
      'booking_service',
      public.booking_service_enriched_json(p.booking_service_id)
    ) as post,
    public.author_mini_json(pr.id) as author,
    public.get_my_post_reaction_kind(p.id) as my_reaction,
    (ps_me.post_id is not null) as my_saved,
    (
      auth.uid() is not null
      and auth.uid() <> p.user_id
      and public.is_following_user(p.user_id)
    ) as my_following_author
  from public.posts p
  inner join public.profiles pr on pr.id = p.user_id
  left join public.post_saves ps_me
    on ps_me.post_id = p.id
   and ps_me.user_id = auth.uid()
  where p.id = p_post_id;
$fn$;

revoke all on function public.get_post_enriched(uuid) from public;
grant execute on function public.get_post_enriched(uuid) to authenticated, anon;

comment on function public.get_post_enriched(uuid) is
  'Post detail: post_enriched_root_json + optional booking_service for CTA.';

notify pgrst, 'reload schema';
