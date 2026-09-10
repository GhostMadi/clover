import { createServerClient } from "@supabase/ssr";
import { NextResponse, type NextRequest } from "next/server";
import {
  ensureValidSession,
  userFromSession,
} from "@/lib/supabase/auth-session";
import { supabaseCookieOptions } from "@/lib/supabase/cookie-options";

/**
 * Гейт кабинета без сетевого `getUser()` на каждый клик.
 * Сессия из cookie; refresh только если JWT почти истёк (как мобилка).
 */
export async function updateSession(request: NextRequest) {
  let supabaseResponse = NextResponse.next({ request });

  const supabase = createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookieOptions: supabaseCookieOptions,
      cookies: {
        getAll() {
          return request.cookies.getAll();
        },
        setAll(cookiesToSet) {
          cookiesToSet.forEach(({ name, value }) => {
            request.cookies.set(name, value);
          });
          supabaseResponse = NextResponse.next({ request });
          cookiesToSet.forEach(({ name, value, options }) => {
            supabaseResponse.cookies.set(name, value, {
              ...supabaseCookieOptions,
              ...options,
            });
          });
        },
      },
    },
  );

  const session = await ensureValidSession(supabase);
  const user = userFromSession(session);

  const path = request.nextUrl.pathname;
  const isAuthArea = path.startsWith("/auth");
  const isAppArea = path.startsWith("/app");

  if (!user && isAppArea) {
    const url = request.nextUrl.clone();
    url.pathname = "/auth";
    url.searchParams.set("next", path);
    return NextResponse.redirect(url);
  }

  if (user && isAuthArea && !path.startsWith("/auth/callback")) {
    const url = request.nextUrl.clone();
    url.pathname = "/app";
    return NextResponse.redirect(url);
  }

  return supabaseResponse;
}
