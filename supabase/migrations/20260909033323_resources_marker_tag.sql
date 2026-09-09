-- Admin power tag for Resources (locations + profile filters).
-- Product: docs/business/tag-powers.md · docs/business/settings.md

insert into public.marker_tags (key, group_key)
values ('resources', 'admin')
on conflict (key) do update
set group_key = excluded.group_key;
