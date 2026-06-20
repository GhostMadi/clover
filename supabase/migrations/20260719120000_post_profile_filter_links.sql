-- Post ↔ profile filter values (for feed filtering on profile).

create table if not exists public.post_profile_filter_links (
  post_id uuid not null
    references public.posts (id) on delete cascade,
  filter_value_id uuid not null
    references public.profile_filter_values (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (post_id, filter_value_id)
);

create index if not exists post_profile_filter_links_filter_value_idx
  on public.post_profile_filter_links (filter_value_id);

comment on table public.post_profile_filter_links is
  'Selected profile filter values attached to a post at publish time.';

-- --------------------------------------------------------------------------- RPC: replace post filter links
create or replace function public.set_post_profile_filters(
  p_post_id uuid,
  p_selection_keys text[]
)
returns void
language plpgsql
security definer
set search_path = public
set row_security to off
as $$
declare
  uid uuid;
  v_key text;
  v_sep int;
  v_category_id uuid;
  v_label text;
  v_value_id uuid;
begin
  uid := auth.uid();
  if uid is null then
    raise exception 'not_authenticated' using errcode = 'P0003';
  end if;

  if p_post_id is null then
    raise exception 'invalid_post' using errcode = 'P0007';
  end if;

  if not exists (
    select 1
    from public.posts p
    where p.id = p_post_id
      and p.user_id = uid
  ) then
    raise exception 'post_not_found' using errcode = 'P0008';
  end if;

  delete from public.post_profile_filter_links l
  where l.post_id = p_post_id;

  if p_selection_keys is null or coalesce(array_length(p_selection_keys, 1), 0) = 0 then
    return;
  end if;

  foreach v_key in array p_selection_keys loop
    v_key := trim(v_key);
    if char_length(v_key) = 0 then
      continue;
    end if;

    v_sep := strpos(v_key, ':');
    if v_sep <= 1 then
      raise exception 'invalid_selection_key' using errcode = 'P0007';
    end if;

    begin
      v_category_id := (left(v_key, v_sep - 1))::uuid;
    exception
      when invalid_text_representation then
        raise exception 'invalid_selection_key' using errcode = 'P0007';
    end;

    v_label := trim(substring(v_key from v_sep + 1));
    if char_length(v_label) = 0 then
      raise exception 'invalid_selection_key' using errcode = 'P0007';
    end if;

    select v.id
    into v_value_id
    from public.profile_filter_values v
    join public.profile_filter_categories c on c.id = v.category_id
    where c.id = v_category_id
      and c.owner_id = uid
      and lower(trim(v.label)) = lower(v_label)
    limit 1;

    if v_value_id is null then
      raise exception 'filter_value_not_found' using errcode = 'P0008';
    end if;

    insert into public.post_profile_filter_links (post_id, filter_value_id)
    values (p_post_id, v_value_id)
    on conflict do nothing;
  end loop;
end;
$$;

alter table public.post_profile_filter_links enable row level security;

revoke all on public.post_profile_filter_links from anon, authenticated;

revoke all on function public.set_post_profile_filters(uuid, text[]) from public;
grant execute on function public.set_post_profile_filters(uuid, text[]) to authenticated;

comment on function public.set_post_profile_filters(uuid, text[]) is
  'Replace filter tags on own post. Keys: "<category_uuid>:<label>".';
