/// POST /functions/v1/register_post_view
/// Body: { post_id: string, viewer_hash: string, bucket_date?: string(YYYY-MM-DD) }
///
/// Inserts into public.post_view_events (dedup by unique constraint).
/// <reference path="../deno.d.ts" />
import { corsHeaders, handleCors } from "../_shared/cors.ts";
import { requireSupabaseUser } from "../_shared/supabase.ts";

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

    const body = await req.json().catch(() => ({}));
    const post_id = String(body.post_id ?? "").trim();
    const viewer_hash = String(body.viewer_hash ?? "").trim();
    const bucket_date =
      String(body.bucket_date ?? "").trim() || new Date().toISOString().slice(0, 10);

    if (!post_id || !viewer_hash) {
      return new Response(JSON.stringify({ error: "post_id and viewer_hash are required" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const { error } = await supabase.from("post_view_events").upsert(
      { post_id, viewer_hash, bucket_date },
      { onConflict: "post_id,viewer_hash,bucket_date", ignoreDuplicates: true },
    );

    if (error) {
      return new Response(JSON.stringify({ error: error.message }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    return new Response(JSON.stringify({ ok: true }), {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (e) {
    return new Response(JSON.stringify({ error: String(e) }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});

