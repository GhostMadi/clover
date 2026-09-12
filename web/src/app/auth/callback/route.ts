import { NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";

export async function GET(request: Request) {
  const { searchParams, origin } = new URL(request.url);
  const code = searchParams.get("code");
  const next = searchParams.get("next") ?? "/app";

  if (code) {
    const supabase = await createClient();
    const { error } = await supabase.auth.exchangeCodeForSession(code);
    if (!error) {
      try {
        const {
          data: { session },
        } = await supabase.auth.getSession();
        let sessionId: string | null = null;
        const token = session?.access_token;
        if (token) {
          try {
            const parts = token.split(".");
            if (parts.length >= 2) {
              const json = atob(parts[1].replace(/-/g, "+").replace(/_/g, "/"));
              const map = JSON.parse(json) as { session_id?: string };
              sessionId = map.session_id?.trim() || null;
            }
          } catch {
            sessionId = null;
          }
        }
        await supabase.rpc("report_account_login", {
          p_client: "web",
          p_platform: "web",
          p_device_label: "Browser",
          p_session_id: sessionId,
        });
      } catch {
        // ignore
      }
      return NextResponse.redirect(`${origin}${next}`);
    }
  }

  return NextResponse.redirect(`${origin}/auth?error=oauth`);
}
