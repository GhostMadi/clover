import type { Session, SupabaseClient, User } from "@supabase/supabase-js";

/** Как в мобилке: сеть только если JWT почти истёк (не на каждый заход). */
export const SESSION_REFRESH_SKEW_SECONDS = 120;

export function needsSessionRefresh(session: Session | null | undefined): boolean {
  if (!session?.expires_at) return false;
  const now = Math.floor(Date.now() / 1000);
  return session.expires_at - now <= SESSION_REFRESH_SKEW_SECONDS;
}

/**
 * Локальная сессия из cookie; `refreshSession` только у порога expiry.
 * Вызывать из middleware (там можно писать cookie) или browser client.
 */
export async function ensureValidSession(
  supabase: SupabaseClient,
): Promise<Session | null> {
  const {
    data: { session },
  } = await supabase.auth.getSession();
  if (!session) return null;

  if (!needsSessionRefresh(session)) return session;

  const { data, error } = await supabase.auth.refreshSession();
  if (!error && data.session) return data.session;

  const now = Math.floor(Date.now() / 1000);
  if (session.expires_at && session.expires_at > now) return session;
  return null;
}

export function userFromSession(session: Session | null | undefined): User | null {
  return session?.user ?? null;
}
