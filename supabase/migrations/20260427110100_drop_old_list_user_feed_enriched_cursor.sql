-- Старая сигнатура без p_exclude_with_marker — убрать, оставить одну функцию.
drop function if exists public.list_user_feed_enriched_cursor(uuid, int, timestamptz, uuid, uuid, boolean);
