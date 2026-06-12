-- Повторяем idempotent: на проекте без REPLICA IDENTITY FULL обновления read-курсора
-- в WAL не содержат conversation_id в "new" → Realtime с server-фильтром не доставлял события.
-- Клиент теперь подписывается на chat_participants без filter, но FULL по-прежнему полезен для полноты old/new.

alter table public.chat_participants replica identity full;
