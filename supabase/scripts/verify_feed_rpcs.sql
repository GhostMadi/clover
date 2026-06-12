-- Ручная проверка после `supabase db push` / применения миграций.
-- Подставьте реальный uuid профиля, у которого есть посты.

-- 1) Профильная лента (offset, первый экран)
-- select * from public.list_user_feed_enriched('00000000-0000-0000-0000-000000000000'::uuid, 10, 0);

-- 2) Профильная лента (keyset): первая страница — без курсора
-- select * from public.list_user_feed_enriched_cursor('00000000-0000-0000-0000-000000000000'::uuid, 10, null, null);

-- 3) Hot 24h
-- select * from public.list_hot_feed_enriched(10, 0);
