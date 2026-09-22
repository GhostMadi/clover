-- Admin power tag: reviews summary on profile showcase.
-- Product: docs/business/tag-powers.md · docs/business/point-reviews-plan.md

insert into public.marker_tags (key, group_key)
values ('feedback', 'admin')
on conflict (key) do update
set group_key = excluded.group_key;
