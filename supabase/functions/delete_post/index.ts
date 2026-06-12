/// POST /functions/v1/delete_post
/// Body: { post_id: string }
///
/// Deletes storage objects under `posts/{post_id}/`, then deletes `public.posts` row.
/// DB has ON DELETE CASCADE to `public.post_media`.
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
    const { supabase, user } = authCtx;

    const body = await req.json().catch(() => null);
    if (!body || typeof body !== "object") return badRequest("Invalid JSON body");
    const post_id = typeof (body as any).post_id === "string" ? String((body as any).post_id).trim() : "";
    if (!post_id) return badRequest("post_id is required");

    // Validate ownership (RLS on posts also enforces this, but we need it before touching storage).
    const { data: postRow, error: postErr } = await supabase
      .from("posts")
      .select("id,user_id")
      .eq("id", post_id)
      .maybeSingle();
    if (postErr) return badRequest(postErr.message);
    if (!postRow) return badRequest("Post not found", 404);
    if (postRow.user_id !== user.id) return badRequest("Forbidden", 403);

    // Remove storage objects under posts/{post_id}/
    const prefix = `posts/${post_id}/`;
    const { data: list, error: listErr } = await supabase.storage
      .from("post_media")
      .list(prefix, { limit: 1000 });
    if (listErr) return badRequest(`storage list failed: ${listErr.message}`);
    const paths = (list ?? []).map((o) => `${prefix}${o.name}`).filter((p) => !p.endsWith("/"));
    if (paths.length > 0) {
      const { error: rmErr } = await supabase.storage.from("post_media").remove(paths);
      if (rmErr) return badRequest(`storage remove failed: ${rmErr.message}`);
    }

    // Delete post row (CASCADE deletes post_media rows).
    const { error: delErr } = await supabase.from("posts").delete().eq("id", post_id);
    if (delErr) return badRequest(delErr.message);

    return jsonOk({ ok: true });
  } catch (e) {
    return new Response(JSON.stringify({ error: String(e) }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});

