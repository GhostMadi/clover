/// POST /functions/v1/refresh_hot_posts_24h
///
/// Calls SQL function public.refresh_hot_posts_24h() using service_role.
/// Use this if pg_cron is not available in your Supabase project.
/// <reference path="../deno.d.ts" />
import { corsHeaders, handleCors } from "../_shared/cors.ts";
import { supabaseClientServiceRole } from "../_shared/supabase.ts";

Deno.serve(async (req) => {
  const cors = handleCors(req);
  if (cors) return cors;

  try {
    if (req.method !== "POST") {
      return new Response("Method not allowed", { status: 405, headers: corsHeaders });
    }

    const supabase = supabaseClientServiceRole();
    const { error } = await supabase.rpc("refresh_hot_posts_24h");
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

