-- Клиент слушает postgres_changes по этим таблицам. Без записи в publication supabase_realtime
-- события INSERT не приходят — входящие сообщения не обновляют открытый чат.
-- Идемпотентно: повторный push не падает.

do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'chat_messages'
  ) then
    alter publication supabase_realtime add table public.chat_messages;
  end if;

  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'chat_message_reactions'
  ) then
    alter publication supabase_realtime add table public.chat_message_reactions;
  end if;

  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'chat_message_attachments'
  ) then
    alter publication supabase_realtime add table public.chat_message_attachments;
  end if;

  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'chat_message_post_refs'
  ) then
    alter publication supabase_realtime add table public.chat_message_post_refs;
  end if;

  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'chat_conversations'
  ) then
    alter publication supabase_realtime add table public.chat_conversations;
  end if;

  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'chat_participants'
  ) then
    alter publication supabase_realtime add table public.chat_participants;
  end if;
end $$;
