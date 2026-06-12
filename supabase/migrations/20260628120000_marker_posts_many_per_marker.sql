-- Markers: один маркер = много постов.
-- Добавляем связующую таблицу public.marker_posts (вместо «массива id» на маркере).
-- Сохраняем:
--   - posts.marker_id — к какому маркеру относится пост (много постов с одним marker_id);
--   - markers.post_id   — денормализованный «главный» пост (превью карты / cover), синхронизируется из marker_posts.

-- --------------------------------------------------------------------------- 1) Таблица связей
create table if not exists public.marker_posts (
  marker_id uuid not null references public.markers (id) on delete cascade,
  post_id uuid not null references public.posts (id) on delete cascade,
  sort_order int not null default 0,
  is_primary boolean not null default false,
  created_at timestamptz not null default now(),
  primary key (marker_id, post_id)
);

comment on table public.marker_posts is
  'M2M: у одного маркера (события) может быть много постов. Один пост — максимум в одном маркере.';

comment on column public.marker_posts.is_primary is
  'Главный пост для превью/обложки; денормализуется в markers.post_id.';

create unique index if not exists marker_posts_post_id_key
  on public.marker_posts (post_id);

create index if not exists marker_posts_marker_id_idx
  on public.marker_posts (marker_id);

-- Ровно один is_primary = true на маркер (частичный уникальный индекс).
create unique index if not exists marker_posts_one_primary_per_marker
  on public.marker_posts (marker_id)
  where is_primary;

-- --------------------------------------------------------------------------- 2) Бэкапфилл из текущей модели (markers.post_id + posts.marker_id)
insert into public.marker_posts (marker_id, post_id, sort_order, is_primary, created_at)
select m.id, m.post_id, 0, true, now()
from public.markers m
where m.post_id is not null
on conflict (marker_id, post_id) do nothing;

insert into public.marker_posts (marker_id, post_id, sort_order, is_primary, created_at)
select
  p.marker_id,
  p.id,
  row_number() over (partition by p.marker_id order by p.created_at asc, p.id asc) - 1,
  false,
  coalesce(p.created_at, now())
from public.posts p
where p.marker_id is not null
  and not exists (
    select 1
    from public.marker_posts mp
    where mp.post_id = p.id
  );

-- Маркеры без явного primary: назначить первый по sort_order как primary.
with ranked as (
  select
    mp.marker_id,
    mp.post_id,
    row_number() over (
      partition by mp.marker_id
      order by mp.sort_order asc, mp.created_at asc, mp.post_id asc
    ) as rn,
    (
      select bool_or(mp2.is_primary)
      from public.marker_posts mp2
      where mp2.marker_id = mp.marker_id
    ) as has_primary
  from public.marker_posts mp
)
update public.marker_posts mp
set is_primary = true
from ranked r
where mp.marker_id = r.marker_id
  and mp.post_id = r.post_id
  and coalesce(r.has_primary, false) = false
  and r.rn = 1;

-- Дедуп primary: если случайно несколько true — оставить один.
with ranked as (
  select
    marker_id,
    post_id,
    row_number() over (
      partition by marker_id
      order by is_primary desc, sort_order asc, created_at asc, post_id asc
    ) as rn
  from public.marker_posts
  where is_primary
)
update public.marker_posts mp
set is_primary = false
from ranked r
where mp.marker_id = r.marker_id
  and mp.post_id = r.post_id
  and r.rn > 1;

-- Посты: выровнять marker_id по связи (если где-то рассинхрон).
update public.posts p
set marker_id = mp.marker_id
from public.marker_posts mp
where mp.post_id = p.id
  and (p.marker_id is null or p.marker_id <> mp.marker_id);

-- --------------------------------------------------------------------------- 3) Снять ограничение «один пост на маркер» с posts.marker_id
drop index if exists public.posts_marker_id_unique;

-- --------------------------------------------------------------------------- 4) Функции: денормализация markers.post_id + синхронизация из posts
create or replace function public.marker_refresh_denormalized_post_id(p_marker_id uuid)
returns void
language plpgsql
security definer
set search_path = public
set row_security = off
as $$
declare
  v_pick uuid;
begin
  if p_marker_id is null then
    return;
  end if;

  select mp.post_id
    into v_pick
  from public.marker_posts mp
  where mp.marker_id = p_marker_id
  order by mp.is_primary desc, mp.sort_order asc, mp.created_at asc, mp.post_id asc
  limit 1;

  update public.markers m
  set post_id = v_pick
  where m.id = p_marker_id;
end;
$$;

revoke all on function public.marker_refresh_denormalized_post_id(uuid) from public;
grant execute on function public.marker_refresh_denormalized_post_id(uuid) to postgres, service_role;

create or replace function public.trg_marker_posts_after_write_refresh_marker()
returns trigger
language plpgsql
security definer
set search_path = public
set row_security = off
as $$
declare
  v_marker uuid;
begin
  if tg_op = 'DELETE' then
    v_marker := old.marker_id;
  else
    v_marker := new.marker_id;
  end if;

  if v_marker is not null then
    perform public.marker_refresh_denormalized_post_id(v_marker);
  end if;

  if tg_op = 'UPDATE' and old.marker_id is distinct from new.marker_id and old.marker_id is not null then
    perform public.marker_refresh_denormalized_post_id(old.marker_id);
  end if;

  return coalesce(new, old);
end;
$$;

drop trigger if exists trg_marker_posts_after_write_refresh_marker on public.marker_posts;
create trigger trg_marker_posts_after_write_refresh_marker
  after insert or update or delete
  on public.marker_posts
  for each row
  execute function public.trg_marker_posts_after_write_refresh_marker();

create or replace function public.trg_posts_sync_marker_posts()
returns trigger
language plpgsql
security definer
set search_path = public
set row_security = off
as $$
declare
  v_has_rows boolean;
  v_sort int;
  v_primary boolean;
begin
  if tg_op = 'DELETE' then
    -- FK marker_posts ON DELETE CASCADE удалит связи; останется обновить markers.post_id по оставшимся постам маркера.
    if old.marker_id is not null then
      perform public.marker_refresh_denormalized_post_id(old.marker_id);
    end if;
    return old;
  end if;

  -- Смена / сброс маркера: убрать старую строку связи для этого поста.
  if tg_op = 'UPDATE' and old.marker_id is distinct from new.marker_id then
    delete from public.marker_posts mp
    where mp.post_id = old.id;

    if old.marker_id is not null then
      perform public.marker_refresh_denormalized_post_id(old.marker_id);
    end if;
  end if;

  if new.marker_id is null then
    return new;
  end if;

  select exists(
    select 1
    from public.marker_posts mp
    where mp.marker_id = new.marker_id
  )
  into v_has_rows;

  select coalesce(max(mp.sort_order) + 1, 0)
    into v_sort
  from public.marker_posts mp
  where mp.marker_id = new.marker_id
    and mp.post_id <> new.id;

  v_primary := not coalesce(v_has_rows, false);

  insert into public.marker_posts (marker_id, post_id, sort_order, is_primary)
  values (new.marker_id, new.id, v_sort, v_primary)
  on conflict (marker_id, post_id) do nothing;

  -- Если вставка пропущена из-за conflict, всё равно обновим маркер.
  perform public.marker_refresh_denormalized_post_id(new.marker_id);

  return new;
end;
$$;

drop trigger if exists trg_posts_sync_marker_posts on public.posts;
create trigger trg_posts_sync_marker_posts
  after insert or update of marker_id or delete
  on public.posts
  for each row
  execute function public.trg_posts_sync_marker_posts();

-- Первичная денормализация после бэкапфилла
do $$
declare
  r record;
begin
  for r in
    select distinct marker_id from public.marker_posts
  loop
    perform public.marker_refresh_denormalized_post_id(r.marker_id);
  end loop;
end;
$$;

-- --------------------------------------------------------------------------- 5) RLS на marker_posts (по аналогии с marker_tag_links)
alter table public.marker_posts enable row level security;

drop policy if exists marker_posts_select_visible_marker on public.marker_posts;
create policy marker_posts_select_visible_marker
  on public.marker_posts
  for select
  to anon, authenticated
  using (
    exists (
      select 1
      from public.markers m
      where m.id = marker_posts.marker_id
        and m.status <> 'cancelled'::public.marker_status
        and m.end_time > now()
        and m.is_archived = false
    )
    or exists (
      select 1
      from public.markers m
      where m.id = marker_posts.marker_id
        and m.owner_id = auth.uid()
    )
  );

drop policy if exists marker_posts_write_marker_owner on public.marker_posts;
create policy marker_posts_write_marker_owner
  on public.marker_posts
  for all
  to authenticated
  using (
    exists (
      select 1
      from public.markers m
      where m.id = marker_posts.marker_id
        and m.owner_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1
      from public.markers m
      where m.id = marker_posts.marker_id
        and m.owner_id = auth.uid()
    )
  );

grant select on public.marker_posts to anon, authenticated;
grant insert, update, delete on public.marker_posts to authenticated;

-- --------------------------------------------------------------------------- 6) RPC list_markers_map: маркер «живой», если есть хотя бы одна связь
drop function if exists public.list_markers_map(
  double precision,
  double precision,
  double precision,
  timestamptz,
  text,
  text[],
  int,
  int
);

create function public.list_markers_map(
  p_lat double precision,
  p_lng double precision,
  p_radius_m double precision,
  p_at_time timestamptz default now(),
  p_emoji text default null,
  p_tag_keys text[] default null,
  p_limit int default 200,
  p_offset int default 0
)
returns table (
  id uuid,
  owner_id uuid,
  text_emoji text,
  address_text text,
  description text,
  cover_image_url text,
  event_time timestamptz,
  end_time timestamptz,
  status text,
  lat double precision,
  lng double precision,
  distance_m double precision,
  post_id uuid
)
language sql
stable
security invoker
set search_path = public
as $$
  with
  params as (
    select
      st_setsrid(st_makepoint(p_lng, p_lat), 4326)::geography as user_loc,
      greatest(coalesce(p_radius_m, 0), 0)::double precision as radius_m,
      coalesce(p_at_time, now()) as at_time,
      nullif(trim(coalesce(p_emoji, '')), '') as emoji
  )
  select
    m.id,
    m.owner_id,
    m.text_emoji,
    m.address_text,
    m.description,
    m.cover_image_url,
    m.event_time,
    m.end_time,
    (
      case
        when m.status = 'cancelled'::public.marker_status then 'cancelled'
        when (select at_time from params) < m.event_time then 'upcoming'
        when (select at_time from params) <= m.end_time then 'active'
        else 'finished'
      end
    ) as status,
    st_y(m.location::geometry)::double precision as lat,
    st_x(m.location::geometry)::double precision as lng,
    st_distance(m.location, (select user_loc from params))::double precision as distance_m,
    m.post_id
  from public.markers m
  where
    exists (select 1 from public.marker_posts mp where mp.marker_id = m.id)
    and m.is_archived = false
    and m.status <> 'cancelled'::public.marker_status
    and m.end_time > (select at_time from params)
    and st_dwithin(m.location, (select user_loc from params), (select radius_m from params))
    and (
      (select emoji from params) is null
      or m.text_emoji = (select emoji from params)
    )
    and (
      p_tag_keys is null
      or exists (
        select 1
        from public.marker_tag_links l
        join public.marker_tags t on t.id = l.tag_id
        where l.marker_id = m.id
          and t.key = any (p_tag_keys)
      )
    )
  order by
    st_distance(m.location, (select user_loc from params)) asc,
    m.event_time asc
  limit least(greatest(coalesce(p_limit, 200), 1), 500)
  offset greatest(coalesce(p_offset, 0), 0);
$$;

revoke all on function public.list_markers_map(double precision, double precision, double precision, timestamptz, text, text[], int, int) from public;
grant execute on function public.list_markers_map(double precision, double precision, double precision, timestamptz, text, text[], int, int) to authenticated, anon;

-- --------------------------------------------------------------------------- 7) RPC: список постов маркера (порядок для UI / ленты события)
create or replace function public.list_marker_posts(
  p_marker_id uuid,
  p_limit int default 100,
  p_offset int default 0
)
returns table (
  post_id uuid,
  sort_order int,
  is_primary boolean,
  created_at timestamptz
)
language sql
stable
security invoker
set search_path = public
as $$
  select
    mp.post_id,
    mp.sort_order,
    mp.is_primary,
    mp.created_at
  from public.marker_posts mp
  where mp.marker_id = p_marker_id
  order by
    mp.is_primary desc,
    mp.sort_order asc,
    mp.created_at asc,
    mp.post_id asc
  limit least(greatest(coalesce(p_limit, 100), 1), 500)
  offset greatest(coalesce(p_offset, 0), 0);
$$;

revoke all on function public.list_marker_posts(uuid, int, int) from public;
grant execute on function public.list_marker_posts(uuid, int, int) to authenticated, anon;

notify pgrst, 'reload schema';
