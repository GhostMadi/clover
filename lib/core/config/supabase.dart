/// Конфиг клиента Supabase для этого репозитория.
///
/// **Project ref** (`wewrosbaxhkukbefjwzf`) должен совпадать с:
/// - связанным проектом CLI: файл `supabase/.temp/project-ref` после `supabase link`;
/// - полем `ref` внутри JWT [anonKey] (payload на [jwt.io](https://jwt.io)).
///
/// После смены URL или anon key в [Dashboard](https://supabase.com/dashboard) обновите
/// [url] и [anonKey], при необходимости — секреты Edge Functions (`SUPABASE_URL`, `SUPABASE_ANON_KEY`).
///
/// Схема БД и RPC описаны в `supabase/MIGRATIONS_INDEX.md`; чат — `supabase/migrations/_chat/README.md`.
class SupabaseConfig {
  const SupabaseConfig._();

  static const url = 'https://wewrosbaxhkukbefjwzf.supabase.co';

  /// Публичный anon key (ожидаемо в клиенте; не путать с service_role).
  static const anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Indld3Jvc2JheGhrdWtiZWZqd3pmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ1NDE0NDgsImV4cCI6MjA5MDExNzQ0OH0.JooHavhBbhSjk5IRr6j4pC7dd_ToQRj5TTlp5a_HK9A';
}

