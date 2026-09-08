-- Split account power tags into admin / worker group definitions.
-- Product: docs/business/tag-powers.md

update public.marker_tags
set group_key = 'admin'
where key = 'booking';

update public.marker_tags
set group_key = 'worker'
where key = 'bookingCalendar';

insert into public.marker_tags (key, group_key)
values
  ('booking', 'admin'),
  ('bookingCalendar', 'worker')
on conflict (key) do update
set group_key = excluded.group_key;
