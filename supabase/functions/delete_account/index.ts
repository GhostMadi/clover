/// POST /functions/v1/delete_account
/// Auth: Bearer user JWT.
/// Soft-hide like hibernate (no auth.admin.deleteUser / no cascade wipe).
/// Prefer client RPC `soft_delete_account`; this Edge remains for older callers.
/// <reference path="../deno.d.ts" />
import { corsHeaders, handleCors } from "../_shared/cors.ts";
import { requireSupabaseUser } from "../_shared/supabase.ts";

function jsonOk(data: unknown) {
  return new Response(JSON.stringify(data), {
    status: 200,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

function jsonError(message: string, status: number) {
  return new Response(JSON.stringify({ error: message }), {
    status,
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

    const { error } = await authCtx.supabase.rpc("soft_delete_account");
    if (error) {
      return jsonError(error.message || "soft_delete_failed", 400);
    }

    return jsonOk({ ok: true, mode: "soft" });
  } catch (e) {
    return jsonError(String(e), 500);
  }
});
