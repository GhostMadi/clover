/// POST /functions/v1/drain_push_outbox
///
/// Drains `public.push_outbox` (sent_at is null) via FCM HTTP v1.
/// Auth: Authorization Bearer = SUPABASE_SERVICE_ROLE_KEY
///    or header x-push-worker-secret = PUSH_WORKER_SECRET
/// Secrets: FIREBASE_SERVICE_ACCOUNT_JSON (or FCM_PROJECT_ID + FCM_CLIENT_EMAIL + FCM_PRIVATE_KEY)
/// <reference path="../deno.d.ts" />
import { corsHeaders, handleCors } from "../_shared/cors.ts";
import { getFcmAccessToken, loadFcmServiceAccount, sendFcmMessage } from "../_shared/fcm.ts";
import { parseBearerJwt, supabaseClientServiceRole } from "../_shared/supabase.ts";

type OutboxRow = {
  id: string;
  user_id: string;
  kind: string;
  title: string;
  body: string;
  payload: Record<string, unknown> | null;
  attempts: number;
};

function unauthorized(detail: string): Response {
  return new Response(JSON.stringify({ error: "Unauthorized", detail }), {
    status: 401,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

function authorize(req: Request): boolean {
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")?.trim() ?? "";
  const jwt = parseBearerJwt(req);
  if (serviceKey && jwt && jwt === serviceKey) return true;

  const workerSecret = Deno.env.get("PUSH_WORKER_SECRET")?.trim() ?? "";
  const headerSecret = req.headers.get("x-push-worker-secret")?.trim() ?? "";
  if (workerSecret && headerSecret && headerSecret === workerSecret) return true;

  return false;
}

Deno.serve(async (req) => {
  const cors = handleCors(req);
  if (cors) return cors;

  try {
    if (req.method !== "POST") {
      return new Response("Method not allowed", { status: 405, headers: corsHeaders });
    }
    if (!authorize(req)) {
      return unauthorized("Need service_role bearer or x-push-worker-secret");
    }

    const sa = loadFcmServiceAccount();
    const accessToken = await getFcmAccessToken(sa);
    const supabase = supabaseClientServiceRole();

    let limit = 40;
    try {
      const body = await req.json() as { limit?: unknown };
      if (typeof body.limit === "number" && Number.isFinite(body.limit)) {
        limit = Math.min(Math.max(Math.floor(body.limit), 1), 100);
      }
    } catch {
      // empty body ok
    }

    const { data: rows, error: claimError } = await supabase.rpc("push_outbox_claim_batch", {
      p_limit: limit,
    });
    if (claimError) {
      return new Response(JSON.stringify({ error: claimError.message }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const batch = (rows ?? []) as OutboxRow[];
    let sent = 0;
    let failed = 0;
    let skippedNoToken = 0;
    let tokensDeleted = 0;

    for (const row of batch) {
      const { data: tokens, error: tokenError } = await supabase
        .from("push_device_tokens")
        .select("token")
        .eq("user_id", row.user_id);

      if (tokenError) {
        await supabase.rpc("push_outbox_mark_failed", {
          p_id: row.id,
          p_error: tokenError.message,
        });
        failed += 1;
        continue;
      }

      const tokenList = (tokens ?? [])
        .map((t: { token?: string }) => t.token?.trim() ?? "")
        .filter((t: string) => t.length > 0);

      if (tokenList.length === 0) {
        // No device — mark sent so we don't retry forever (in-app already delivered).
        await supabase.rpc("push_outbox_mark_sent", { p_id: row.id });
        skippedNoToken += 1;
        continue;
      }

      const payload = (row.payload && typeof row.payload === "object")
        ? row.payload
        : {};

      let anyOk = false;
      const errors: string[] = [];

      for (const token of tokenList) {
        const result = await sendFcmMessage({
          sa,
          accessToken,
          token,
          title: row.title,
          body: row.body,
          kind: row.kind,
          payload,
        });

        if (result.ok) {
          anyOk = true;
          continue;
        }

        errors.push(result.error);
        if (result.invalidToken) {
          await supabase.rpc("push_device_tokens_delete_token", { p_token: token });
          tokensDeleted += 1;
        }
      }

      if (anyOk || (tokenList.length > 0 && errors.every((e) => /UNREGISTERED|NOT_FOUND/i.test(e)))) {
        // All tokens gone → treat as drained (nothing left to notify on device).
        await supabase.rpc("push_outbox_mark_sent", { p_id: row.id });
        if (anyOk) sent += 1;
        else skippedNoToken += 1;
      } else {
        await supabase.rpc("push_outbox_mark_failed", {
          p_id: row.id,
          p_error: errors.slice(0, 3).join(" | "),
        });
        failed += 1;
      }
    }

    return new Response(
      JSON.stringify({
        ok: true,
        claimed: batch.length,
        sent,
        failed,
        skipped_no_token: skippedNoToken,
        tokens_deleted: tokensDeleted,
      }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  } catch (e) {
    return new Response(JSON.stringify({ error: String(e) }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
