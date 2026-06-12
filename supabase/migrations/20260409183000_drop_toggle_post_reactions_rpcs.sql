-- Drop legacy toggle RPCs in favor of set_post_reaction().
-- Idempotent: на части окружений функции уже удалены (REVOKE на несуществующую функцию падает).

drop function if exists public.toggle_post_like(uuid);
drop function if exists public.toggle_post_dislike(uuid);
