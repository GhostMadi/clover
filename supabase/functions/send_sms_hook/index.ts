/// Auth Hook: Send SMS → Meta WhatsApp Cloud API (AUTHENTICATION / COPY_CODE)
/// Docs:
/// - https://supabase.com/docs/guides/auth/auth-hooks/send-sms-hook
/// - https://developers.facebook.com/docs/whatsapp/business-management-api/authentication-templates/copy-code-button-authentication-templates/
/// <reference path="../deno.d.ts" />

import { Webhook } from "https://esm.sh/standardwebhooks@1.0.0";

type SendSmsPayload = {
  user: { phone?: string | null };
  sms: { otp?: string | null };
};

type MetaErrorBody = {
  error?: {
    message?: string;
    type?: string;
    code?: number;
    error_subcode?: number;
    fbtrace_id?: string;
  };
};

/** HTTP Send SMS Hook budget is ~5s total (incl. retries). Keep Meta call under that. */
const META_FETCH_TIMEOUT_MS = 4_000;

function jsonError(httpCode: number, message: string, status: number) {
  return new Response(
    JSON.stringify({
      error: {
        http_code: httpCode,
        message,
      },
    }),
    {
      status,
      headers: { "Content-Type": "application/json" },
    },
  );
}

function normalizePhoneE164(raw: string): string {
  const trimmed = raw.trim();
  if (trimmed.startsWith("+")) return trimmed;
  return `+${trimmed.replace(/\D/g, "")}`;
}

/** Safe Meta error summary — never echo raw body (may contain sensitive context). */
function metaErrorSummary(status: number, raw: string): string {
  try {
    const parsed = JSON.parse(raw) as MetaErrorBody;
    const err = parsed.error;
    if (!err) return `Meta HTTP ${status}`;
    const parts = [
      `Meta HTTP ${status}`,
      err.code != null ? `code=${err.code}` : null,
      err.error_subcode != null ? `subcode=${err.error_subcode}` : null,
      err.type ? `type=${err.type}` : null,
    ].filter(Boolean);
    return parts.join(" ");
  } catch {
    return `Meta HTTP ${status}`;
  }
}

Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return new Response("Method not allowed", { status: 405 });
  }

  const hookSecret = Deno.env.get("SEND_SMS_HOOK_SECRET");
  const metaToken = Deno.env.get("META_WA_ACCESS_TOKEN");
  const phoneNumberId = Deno.env.get("META_WA_PHONE_NUMBER_ID");
  // Pin via secret; default = current stable Graph (not v21.0).
  const apiVersion = Deno.env.get("META_WA_API_VERSION") ?? "v25.0";
  const templateName = Deno.env.get("META_WA_TEMPLATE_NAME");
  const templateLang = Deno.env.get("META_WA_TEMPLATE_LANG") ?? "en_US";

  if (!hookSecret || !metaToken || !phoneNumberId || !templateName) {
    return jsonError(500, "Missing required secrets for send_sms_hook", 500);
  }

  const payloadText = await req.text();
  const headers = Object.fromEntries(req.headers);

  let payload: SendSmsPayload;
  try {
    // Supabase secret format: v1,whsec_<base64>
    // standardwebhooks expects the raw base64 secret only.
    const base64Secret = hookSecret.replace("v1,whsec_", "");
    const wh = new Webhook(base64Secret);
    payload = wh.verify(payloadText, headers) as SendSmsPayload;
  } catch {
    return jsonError(401, "Invalid webhook signature", 401);
  }

  const phoneRaw = payload.user?.phone ?? "";
  const otp = payload.sms?.otp ?? "";

  if (!phoneRaw || !otp) {
    return jsonError(400, "Missing phone or otp in hook payload", 400);
  }

  // Never log otp / access token.
  const to = normalizePhoneE164(phoneRaw);
  const url =
    `https://graph.facebook.com/${apiVersion}/${phoneNumberId}/messages`;

  // COPY_CODE send payload per Meta: OTP twice (body + url button).
  // Creation uses OTP/COPY_CODE; at send time button is sub_type "url".
  const body = {
    messaging_product: "whatsapp",
    recipient_type: "individual",
    to,
    type: "template",
    template: {
      name: templateName,
      language: { code: templateLang },
      components: [
        {
          type: "body",
          parameters: [{ type: "text", text: otp }],
        },
        {
          type: "button",
          sub_type: "url",
          index: "0",
          parameters: [{ type: "text", text: otp }],
        },
      ],
    },
  };

  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), META_FETCH_TIMEOUT_MS);

  let metaRes: Response;
  try {
    metaRes = await fetch(url, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${metaToken}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(body),
      signal: controller.signal,
    });
  } catch (err) {
    const timedOut = err instanceof DOMException && err.name === "AbortError";
    return jsonError(
      504,
      timedOut
        ? "Meta WhatsApp request timed out"
        : "Meta WhatsApp request failed",
      504,
    );
  } finally {
    clearTimeout(timer);
  }

  if (!metaRes.ok) {
    const metaText = await metaRes.text();
    const summary = metaErrorSummary(metaRes.status, metaText);
    console.error("send_sms_hook meta_error", summary);
    return jsonError(metaRes.status, summary, 502);
  }

  return new Response(JSON.stringify({}), {
    status: 200,
    headers: { "Content-Type": "application/json" },
  });
});
