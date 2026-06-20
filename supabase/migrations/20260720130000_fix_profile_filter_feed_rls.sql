-- Fix 403 on list_user_feed_enriched_cursor when profile filters are active:
-- post_matches_profile_filter_selection must read post_profile_filter_links and
-- profile_filter_* tables that have revoke-all for authenticated (RPC-only access).

create or replace function public.post_matches_profile_filter_selection(
  p_post_id uuid,
  p_owner_id uuid,
  p_selection_keys text[]
)
returns boolean
language plpgsql
stable
security definer
set search_path = public
set row_security to off
as $fn$
declare
  v_group_count int;
  v_matched_groups int;
begin
  if p_selection_keys is null
     or coalesce(array_length(p_selection_keys, 1), 0) = 0 then
    return true;
  end if;

  if not exists (
    select 1
    from unnest(p_selection_keys) as u(k)
    where trim(k) <> ''
  ) then
    return true;
  end if;

  with raw_keys as (
    select trim(k) as key
    from unnest(p_selection_keys) as u(k)
    where trim(k) <> ''
  ),
  parsed as (
    select distinct
      left(rk.key, strpos(rk.key, ':') - 1)::uuid as category_id,
      trim(substring(rk.key from strpos(rk.key, ':') + 1)) as label
    from raw_keys rk
    where strpos(rk.key, ':') > 1
      and char_length(trim(substring(rk.key from strpos(rk.key, ':') + 1))) > 0
  ),
  resolved as (
    select p.category_id, v.id as value_id
    from parsed p
    join public.profile_filter_categories c
      on c.id = p.category_id
     and c.owner_id = p_owner_id
    join public.profile_filter_values v
      on v.category_id = c.id
     and lower(trim(v.label)) = lower(p.label)
  ),
  groups as (
    select category_id, array_agg(distinct value_id) as value_ids
    from resolved
    group by category_id
  )
  select
    count(*)::int,
    count(*) filter (
      where exists (
        select 1
        from public.post_profile_filter_links l
        where l.post_id = p_post_id
          and l.filter_value_id = any(g.value_ids)
      )
    )::int
  into v_group_count, v_matched_groups
  from groups g;

  if v_group_count = 0 then
    return false;
  end if;

  return v_matched_groups = v_group_count;
end;
$fn$;

revoke all on function public.post_matches_profile_filter_selection(uuid, uuid, text[]) from public;

comment on function public.post_matches_profile_filter_selection(uuid, uuid, text[]) is
  'SECURITY DEFINER helper for profile feed filter (reads post_profile_filter_links).';

-- Re-assert execute on feed RPC (idempotent).
revoke all on function public.list_user_feed_enriched_cursor(jsonb) from public;
grant execute on function public.list_user_feed_enriched_cursor(jsonb) to authenticated, anon;

notify pgrst, 'reload schema';
