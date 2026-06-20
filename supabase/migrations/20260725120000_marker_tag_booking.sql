-- Тег аккаунта booking: включает кнопку «Записаться» на профиле.

insert into public.marker_tags (key, group_key)
values ('booking', 'account')
on conflict (key) do update
set group_key = excluded.group_key;
