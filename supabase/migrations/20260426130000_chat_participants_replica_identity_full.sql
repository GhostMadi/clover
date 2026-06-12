-- Filtered postgres_changes по UPDATE для Realtime надёжнее видит строку при наличии REPLICA IDENTITY FULL.
-- Иначе событие по chat_participants (mark_conversation_read у собеседника) может не матчиться фильтром conversation_id.

alter table public.chat_participants replica identity full;
