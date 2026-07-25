/// POST /functions/v1/delete_post
/// Body: { post_id: string }
///
/// Delegates to `public.delete_owned_post` (storage + DB cascade).
/// <reference path="../deno.d.ts" />
import { corsHeaders, handleCors } from "./_shared/cors.ts";
import { requireSupabaseUser } from "./_shared/supabase.ts";

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
    const { supabase } = authCtx;

    const body = await req.json().catch(() => null);
    if (!body || typeof body !== "object") return badRequest("Invalid JSON body");
    const post_id = typeof (body as any).post_id === "string" ? String((body as any).post_id).trim() : "";
    if (!post_id) return badRequest("post_id is required");

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
