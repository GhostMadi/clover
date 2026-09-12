-- Soft rate-limit for public support form (anon/authenticated insert).
-- Product: docs/business/support.md · SPEC_SUPPORT_REQUESTS.md

create or replace function public.support_requests_enforce_rate_limit()
returns trigger
language plpgsql
security definer
set search_path = public
set row_security to off
as $$
declare
  v_contact text := lower(trim(coalesce(new.contact, '')));
  v_count int;
begin
  if char_length(v_contact) = 0 then
    raise exception 'contact_required' using errcode = 'P0001';
  end if;

  select count(*)::int into v_count
  from public.support_requests r
  where lower(trim(r.contact)) = v_contact
    and r.created_at > now() - interval '1 hour';

  if v_count >= 5 then
    raise exception 'rate_limited' using errcode = 'P0001';
  end if;

  return new;
end;
$$;

drop trigger if exists trg_support_requests_rate_limit on public.support_requests;
create trigger trg_support_requests_rate_limit
  before insert on public.support_requests
  for each row
  execute function public.support_requests_enforce_rate_limit();

comment on function public.support_requests_enforce_rate_limit() is
  'Max 5 support_requests per contact per hour.';
