-- Клиентский GET /chat_participants (peerLastReadCursors) без GRANT даёт 403 от PostgREST:
-- в схеме чата для authenticated стоит revoke all; RLS сама по себе права не даёт.
-- Разрешаем только SELECT; видимость строк по-прежнему только через RLS.

grant select on table public.chat_participants to authenticated;
