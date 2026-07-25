-- Host inbox: client_id в enriched list для открытия профиля клиента.
create or replace function public.list_host_bookings_enriched(
  p_from timestamptz,
  p_to timestamptz,
  p_query text default null,
  p_cursor jsonb default null,
  p_limit int default 50
)
returns setof jsonb
language plpgsql
stable
security definer
set search_path = public
set row_security to off
as $$
declare
  uid uuid;
  v_limit int;
  v_q text;
begin
  uid := public.booking_assert_authenticated();
  v_limit := greatest(1, least(coalesce(p_limit, 50), 100));
  v_q := nullif(trim(coalesce(p_query, '')), '');

  return query
  select jsonb_build_object(
    'id', b.id,
    'client_id', b.client_id,
    'client_name', coalesce(cp.full_name, ''),
    'client_username', cp.username,
    'client_phone', cp.phone,
    'service_title', b.service_title,
    'service_emoji', b.service_emoji,
    'duration_minutes', b.duration_minutes,
    'price', b.price,
    'executor_name', st.display_name,
    'starts_at', b.starts_at,
    'status', b.status,
    'notes', b.client_notes,
    'participants_count', b.participants_count,
    'created_at', b.created_at
  )
  from public.bookings b
  join public.profiles cp on cp.id = b.client_id
  join public.booking_staff st on st.id = b.staff_id
  where b.host_id = uid
    and b.starts_at >= coalesce(p_from, '-infinity'::timestamptz)
    and b.starts_at <= coalesce(p_to, 'infinity'::timestamptz)
    and (
      v_q is null
      or char_length(v_q) < 2
      or cp.full_name ilike ('%' || v_q || '%')
      or cp.username ilike ('%' || v_q || '%')
      or cp.phone ilike ('%' || v_q || '%')
      or b.service_title ilike ('%' || v_q || '%')
    )
    and (
      p_cursor is null
      or b.starts_at > coalesce((p_cursor ->> 'starts_at')::timestamptz, '-infinity'::timestamptz)
      or (
        b.starts_at = (p_cursor ->> 'starts_at')::timestamptz
        and b.id > coalesce((p_cursor ->> 'id')::uuid, '00000000-0000-0000-0000-000000000000'::uuid)
      )
    )
  order by b.starts_at asc, b.id asc
  limit v_limit;
end;
$$;
