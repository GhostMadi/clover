/// POST /functions/v1/delete_post
/// Body: { post_id: string }
///
/// Deletes R2 media (best-effort) then `public.delete_owned_post` (legacy Storage + DB).
/// <reference path="../deno.d.ts" />
import { corsHeaders, handleCors } from "../_shared/cors.ts";
import { deleteR2Keys, fileKeyFromPublicUrl, requireR2Env } from "../_shared/r2.ts";
import { requireSupabaseUser } from "../_shared/supabase.ts";

function badRequest(message: string, status = 400) {
  return new Response(JSON.stringify({ error: message }), {
    status,
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
  return fileKey.includes(`/${userId}/`) || fileKey.startsWith(`${userId}/`);
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
    const { supabase, user } = authCtx;

    const body = await req.json().catch(() => null);
    if (!body || typeof body !== "object") return badRequest("Invalid JSON body");
    const post_id = typeof (body as { post_id?: unknown }).post_id === "string"
      ? String((body as { post_id: string }).post_id).trim()
      : "";
    if (!post_id) return badRequest("post_id is required");

    // Collect media URLs while the post still exists.
    const { data: mediaRows } = await supabase
      .from("post_media")
      .select("url")
      .eq("post_id", post_id);

    try {
      const env = requireR2Env();
      const keys = new Set<string>();
      for (const row of Array.isArray(mediaRows) ? mediaRows : []) {
        const url = String((row as { url?: string })?.url ?? "").trim();
        const key = fileKeyFromPublicUrl(url, env);
        if (key && keyOwnedByUser(key, user.id)) keys.add(key);
      }
      if (keys.size > 0) await deleteR2Keys([...keys], env);
    } catch {
      // best-effort R2 cleanup
    }

    const { error } = await supabase.rpc("delete_owned_post", { p_post_id: post_id });
    if (error) return badRequest(error.message);

    return jsonOk({ ok: true });
  } catch (e) {
    return new Response(JSON.stringify({ error: String(e) }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
