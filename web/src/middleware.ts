import { type NextRequest, NextResponse } from "next/server";
import { updateSession } from "@/lib/supabase/middleware";

/**
 * OAuth / magic-link: Supabase иногда кидает `?code=` на Site URL (главную),
 * а не на `/auth/callback`. Перехватываем и отдаём в callback.
 */
export async function middleware(request: NextRequest) {
  const code = request.nextUrl.searchParams.get("code");
  const path = request.nextUrl.pathname;

  if (code && !path.startsWith("/auth/callback")) {
    const url = request.nextUrl.clone();
    url.pathname = "/auth/callback";
    url.search = "";
    url.searchParams.set("code", code);
    url.searchParams.set("next", "/app");
    return NextResponse.redirect(url);
  }

  if (path.startsWith("/auth") || path.startsWith("/app")) {
    return updateSession(request);
  }

  return NextResponse.next();
}

export const config = {
  matcher: ["/", "/auth/:path*", "/app/:path*"],
};
