/// <reference path="../deno.d.ts" />
import { createClient, type SupabaseClient, type User } from "https://esm.sh/@supabase/supabase-js@2.49.1";

/** JWT из заголовка (без префикса Bearer). Учитывает и `authorization`, и `Authorization`. */
export function parseBearerJwt(req: Request): string {
  const raw =
    req.headers.get("Authorization")?.trim() ??
    req.headers.get("authorization")?.trim() ??
    "";
  const m = /^Bearer\s+(\S+)/i.exec(raw);
  return m?.[1]?.trim() ?? "";
}

/**
 * Клиент с тем же JWT в global headers (для PostgREST / Storage от имени пользователя).
 * Предпочитайте [requireSupabaseUser]: там вызывается `getUser(jwt)` с явным токеном —
 * в Edge это надёжнее, чем `getUser()` без аргумента.
 */
export function supabaseClientForUser(req: Request): SupabaseClient {
  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
  if (!supabaseUrl || !anonKey) {
    throw new Error("Missing SUPABASE_URL / SUPABASE_ANON_KEY");
  }
  const jwt = parseBearerJwt(req);
  const authorization = jwt ? `Bearer ${jwt}` : "";
  return createClient(supabaseUrl, anonKey, {
    global: { headers: { Authorization: authorization } },
    auth: { persistSession: false, autoRefreshToken: false },
  });
}

export type RequireUserOk = { ok: true; supabase: SupabaseClient; user: User };
export type RequireUserErr = { ok: false; status: number; body: string };

/** Валидирует JWT и возвращает клиент + пользователя для Edge Functions. */
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

export function supabaseClientServiceRole() {
  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!supabaseUrl || !serviceKey) {
    throw new Error("Missing SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY");
  }
  return createClient(supabaseUrl, serviceKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
}
