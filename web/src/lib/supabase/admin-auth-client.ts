import { createClient, type SupabaseClient } from "@supabase/supabase-js";

/**
 * Чистый Auth-клиент без cookie браузера.
 * Нужен для /api/admin/*: иначе битый refresh token из SSR cookie ломает signIn/signUp.
 */
export function createAdminAuthClient(): SupabaseClient {
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL?.trim();
  const anon = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY?.trim();
  if (!url || !anon) {
    throw new Error("Missing NEXT_PUBLIC_SUPABASE_URL / ANON_KEY");
  }
  return createClient(url, anon, {
    auth: {
      persistSession: false,
      autoRefreshToken: false,
      detectSessionInUrl: false,
    },
  });
}
