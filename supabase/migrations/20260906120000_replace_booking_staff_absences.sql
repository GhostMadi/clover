-- Atomic replace of host staff absences (one round-trip; validates staff ownership).
-- Product: docs/business/booking.md · Spec: docs/supabase/booking_backend_spec.md

create or replace function public.replace_booking_staff_absences(p_absences jsonb)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_item jsonb;
  v_staff_id uuid;
  v_start date;
  v_end date;
  v_note text;
begin
  if v_uid is null then
    raise exception 'not_authenticated' using errcode = '42501';
  end if;

  delete from public.booking_staff_absences where host_id = v_uid;

  if p_absences is null or jsonb_typeof(p_absences) <> 'array' then
    return;
  end if;

  for v_item in select * from jsonb_array_elements(p_absences)
  loop
    v_staff_id := nullif(trim(v_item->>'staff_id'), '')::uuid;
    v_start := nullif(trim(v_item->>'start_date'), '')::date;
    v_end := nullif(trim(v_item->>'end_date'), '')::date;
    v_note := nullif(trim(v_item->>'note'), '');

    if v_staff_id is null or v_start is null or v_end is null then
      raise exception 'invalid_absence_payload' using errcode = '22023';
    end if;

    if v_end < v_start then
      raise exception 'invalid_absence_dates' using errcode = '22023';
    end if;

    if not exists (
      select 1
      from public.booking_staff s
      where s.id = v_staff_id
        and s.host_id = v_uid
    ) then
      raise exception 'staff_not_owned' using errcode = '42501';
    end if;

    insert into public.booking_staff_absences (host_id, staff_id, start_date, end_date, note)
    values (v_uid, v_staff_id, v_start, v_end, v_note);
  end loop;
end;
$$;

revoke all on function public.replace_booking_staff_absences(jsonb) from public;
grant execute on function public.replace_booking_staff_absences(jsonb) to authenticated;

comment on function public.replace_booking_staff_absences(jsonb) is
  'Host: delete all own booking_staff_absences then insert payload in one transaction.';
