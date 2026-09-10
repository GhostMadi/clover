import { createServerClient } from "@supabase/ssr";
import type { User } from "@supabase/supabase-js";
import { cookies } from "next/headers";
import { supabaseCookieOptions } from "@/lib/supabase/cookie-options";

export async function createClient() {
  const cookieStore = await cookies();

  return createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookieOptions: supabaseCookieOptions,
      cookies: {
        getAll() {
          return cookieStore.getAll();
        },
        setAll(cookiesToSet) {
          try {
            cookiesToSet.forEach(({ name, value, options }) => {
              cookieStore.set(name, value, {
                ...supabaseCookieOptions,
                ...options,
              });
            });
          } catch {
            // Called from a Server Component — middleware will refresh session.
          }
        },
      },
    },
  );
}

/**
 * Текущий пользователь из cookie (без Auth API).
 * Refresh при необходимости делает middleware (`ensureValidSession`).
 */
export async function getAuthUser(): Promise<User | null> {
  const supabase = await createClient();
  const {
    data: { session },
  } = await supabase.auth.getSession();
  return session?.user ?? null;
}
