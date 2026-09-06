-- Booking: never auto-mark visit as completed. Auto-close may only set no_show.
-- Process: docs/business/booking.md — «Оказана» только человек.

-- Drop old check, allow only no_show as auto target (completed forbidden).
alter table public.booking_schedule_settings
  drop constraint if exists booking_schedule_auto_close_target_allowed;

update public.booking_schedule_settings
set auto_close_target = 'no_show'::public.booking_status
where auto_close_target is distinct from 'no_show'::public.booking_status;

alter table public.booking_schedule_settings
  alter column auto_close_target set default 'no_show'::public.booking_status;

alter table public.booking_schedule_settings
  add constraint booking_schedule_auto_close_target_allowed check (
    auto_close_target = 'no_show'::public.booking_status
  );

alter table public.booking_schedule_settings
  alter column auto_close_hours_after_visit set default 0;

comment on column public.booking_schedule_settings.auto_close_hours_after_visit is
  'Hours after ends_at before optional auto no_show. 0 = disabled. Never auto-completes.';

comment on column public.booking_schedule_settings.auto_close_target is
  'Only no_show allowed. Completed is human-only.';

create or replace function public.booking_auto_close_stale_visits()
returns int
language plpgsql
security definer
set search_path = public
set row_security to off
as $$
declare
  v_row record;
  v_closed int := 0;
  v_now timestamptz := now();
  v_hours int;
begin
  -- Only pending/confirmed past ends_at+N → no_show.
  -- Never touch arrived / in_progress / completed. Never set completed.
  for v_row in
    select
      b.id,
      b.status,
      coalesce(s.auto_close_hours_after_visit, 0) as close_hours
    from public.bookings b
    left join public.booking_schedule_settings s on s.host_id = b.host_id
    where b.status in (
      'pending'::public.booking_status,
      'confirmed'::public.booking_status
    )
      and coalesce(s.auto_close_hours_after_visit, 0) > 0
      and b.ends_at + make_interval(hours => coalesce(s.auto_close_hours_after_visit, 0)) <= v_now
    for update skip locked
  loop
    v_hours := v_row.close_hours;
    if v_hours <= 0 then
      continue;
    end if;

    update public.bookings
    set status = 'no_show'::public.booking_status,
        no_show_at = v_now
    where id = v_row.id;

    insert into public.booking_history (booking_id, actor_id, action, old_status, new_status)
    values (
      v_row.id,
      null,
      'auto_closed'::public.booking_history_action,
      v_row.status,
      'no_show'::public.booking_status
    );

    v_closed := v_closed + 1;
  end loop;

  return v_closed;
end;
$$;

-- Host list: include staff_id for reschedule UI
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
    'staff_id', b.staff_id,
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

notify pgrst, 'reload schema';
