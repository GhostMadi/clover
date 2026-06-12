/// <reference path="../../deno.d.ts" />
import { createClient, type SupabaseClient, type User } from "https://esm.sh/@supabase/supabase-js@2.49.1";

export function parseBearerJwt(req: Request): string {
  const raw =
    req.headers.get("Authorization")?.trim() ??
    req.headers.get("authorization")?.trim() ??
    "";
  const m = /^Bearer\s+(\S+)/i.exec(raw);
  return m?.[1]?.trim() ?? "";
}

export type RequireUserOk = { ok: true; supabase: SupabaseClient; user: User };
export type RequireUserErr = { ok: false; status: number; body: string };

export async function requireSupabaseUser(req: Request): Promise<RequireUserOk | RequireUserErr> {
  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
  if (!supabaseUrl || !anonKey) {
    return {
      ok: false,
      status: 500,
      body: JSON.stringify({ error: "Server misconfiguration" }),
    };
  }
  const jwt = parseBearerJwt(req);
  if (!jwt) {
    return {
      ok: false,
      status: 401,
      body: JSON.stringify({ error: "Unauthorized", detail: "Missing bearer token" }),
    };
  }
  const supabase = createClient(supabaseUrl, anonKey, {
    global: { headers: { Authorization: `Bearer ${jwt}` } },
    auth: { persistSession: false, autoRefreshToken: false },
  });
  const { data, error } = await supabase.auth.getUser(jwt);
  if (error || !data.user) {
    return {
      ok: false,
      status: 401,
      body: JSON.stringify({
        error: "Unauthorized",
        detail: error?.message ?? "Invalid or expired session",
      }),
    };
  }
  return { ok: true, supabase, user: data.user };
}

