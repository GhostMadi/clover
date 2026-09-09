/// POST /functions/v1/delete-r2-objects
/// Body: { urls?: string[], fileKeys?: string[] }
/// Deletes objects from Cloudflare R2. Keys must contain `/{auth.uid()}/` (owner prefix).
///
/// <reference path="../deno.d.ts" />
import { corsHeaders, handleCors } from "../_shared/cors.ts";
import { deleteR2Keys, fileKeyFromPublicUrl, requireR2Env } from "../_shared/r2.ts";
import { requireSupabaseUser } from "../_shared/supabase.ts";

function badRequest(message: string) {
  return new Response(JSON.stringify({ error: message }), {
    status: 400,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

function jsonOk(data: unknown) {
  return new Response(JSON.stringify(data), {
    status: 200,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

function keyOwnedByUser(fileKey: string, userId: string): boolean {
  const needle = `/${userId}/`;
  return fileKey.includes(needle) || fileKey.startsWith(`${userId}/`);
}

Deno.serve(async (req) => {
  const cors = handleCors(req);
  if (cors) return cors;

  try {
    if (req.method !== "POST") {
      return new Response("Method not allowed", { status: 405, headers: corsHeaders });
    }

    const authCtx = await requireSupabaseUser(req);
    if (!authCtx.ok) {
      return new Response(authCtx.body, {
        status: authCtx.status,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }
    const { user } = authCtx;

    const body = await req.json().catch(() => null);
    if (!body || typeof body !== "object") return badRequest("Invalid JSON body");

    const urlsRaw = (body as { urls?: unknown }).urls;
    const keysRaw = (body as { fileKeys?: unknown }).fileKeys;

    const urls = Array.isArray(urlsRaw)
      ? urlsRaw.filter((u): u is string => typeof u === "string").map((u) => u.trim())
      : [];
    const keysIn = Array.isArray(keysRaw)
      ? keysRaw.filter((k): k is string => typeof k === "string").map((k) => k.trim())
      : [];

    const env = requireR2Env();
    const keys = new Set<string>();
    for (const k of keysIn) {
      if (k) keys.add(k);
    }
    for (const u of urls) {
      const fromUrl = fileKeyFromPublicUrl(u, env);
      if (fromUrl) keys.add(fromUrl);
    }

    const owned = [...keys].filter((k) => keyOwnedByUser(k, user.id));
    if (owned.length === 0) {
      return jsonOk({ ok: true, deleted: 0, skipped: keys.size });
    }

    const deleted = await deleteR2Keys(owned, env);
    return jsonOk({ ok: true, deleted, skipped: keys.size - owned.length });
  } catch (e) {
    return new Response(JSON.stringify({ error: String(e) }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
