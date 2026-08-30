/// Meta WhatsApp Cloud API Webhook (inbound)
/// Independent from send_sms_hook (Auth OTP outbound).
///
/// Subscribe in Meta to webhook field `messages`.
/// Within that field, payloads may include `value.messages` and/or `value.statuses`.
/// Confirm actual delivery of status events in Logs after Meta Verify.
///
/// Docs:
/// - https://developers.facebook.com/docs/whatsapp/cloud-api/guides/set-up-webhooks/
/// - https://developers.facebook.com/docs/graph-api/webhooks/getting-started
/// <reference path="../deno.d.ts" />

type JsonRecord = Record<string, unknown>;

function isRecord(value: unknown): value is JsonRecord {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function asString(value: unknown): string | null {
  return typeof value === "string" && value.length > 0 ? value : null;
}

function timingSafeEqualHex(a: string, b: string): boolean {
  if (a.length !== b.length) return false;
  let mismatch = 0;
  for (let i = 0; i < a.length; i++) {
    mismatch |= a.charCodeAt(i) ^ b.charCodeAt(i);
  }
  return mismatch === 0;
}

async function verifyMetaSignature(
  rawBody: string,
  signatureHeader: string | null,
  appSecret: string,
): Promise<boolean> {
  if (!signatureHeader?.startsWith("sha256=")) return false;
  const provided = signatureHeader.slice("sha256=".length).toLowerCase();

  const key = await crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(appSecret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const mac = await crypto.subtle.sign(
    "HMAC",
    key,
    new TextEncoder().encode(rawBody),
  );
  const expected = [...new Uint8Array(mac)]
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");

  return timingSafeEqualHex(expected, provided);
}

function processPayload(payload: JsonRecord): void {
  if (payload.object !== "whatsapp_business_account") {
    console.log("whatsapp_webhook ignored_object", {
      object: payload.object ?? null,
    });
    return;
  }

  const entries = Array.isArray(payload.entry) ? payload.entry : [];
  for (const entry of entries) {
    if (!isRecord(entry)) continue;
    const changes = Array.isArray(entry.changes) ? entry.changes : [];

    for (const change of changes) {
      if (!isRecord(change)) continue;
      const field = asString(change.field);
      if (field !== "messages") {
        console.log("whatsapp_webhook ignored_field", { field });
        continue;
      }

      const value = isRecord(change.value) ? change.value : {};
      const metadata = isRecord(value.metadata) ? value.metadata : {};
      const phoneNumberId = asString(metadata.phone_number_id);

      const messages = Array.isArray(value.messages) ? value.messages : [];
      for (const message of messages) {
        if (!isRecord(message)) continue;
        // Future idempotency key: message.id
        console.log("whatsapp_webhook message", {
          event: "message",
          message_id: asString(message.id),
          from: asString(message.from),
          timestamp: asString(message.timestamp),
          type: asString(message.type),
          phone_number_id: phoneNumberId,
          has_text: isRecord(message.text) && !!asString(message.text.body),
        });
      }

      const statuses = Array.isArray(value.statuses) ? value.statuses : [];
      for (const status of statuses) {
        if (!isRecord(status)) continue;
        const errors = Array.isArray(status.errors) ? status.errors : [];
        // Future idempotency key: `${status.id}:${status.status}`
        console.log("whatsapp_webhook status", {
          event: "status",
          message_id: asString(status.id),
          status: asString(status.status),
          timestamp: asString(status.timestamp),
          recipient_id: asString(status.recipient_id),
          phone_number_id: phoneNumberId,
          error_count: errors.length,
        });
      }
    }
  }
}

function handleGetVerification(req: Request): Response {
  const url = new URL(req.url);
  const mode = url.searchParams.get("hub.mode");
  const token = url.searchParams.get("hub.verify_token");
  const challenge = url.searchParams.get("hub.challenge");
  const verifyToken = Deno.env.get("META_WA_VERIFY_TOKEN");

  if (!verifyToken) {
    console.error("whatsapp_webhook missing_verify_token_secret");
    return new Response("Forbidden", { status: 403 });
  }
  if (!mode || !token || !challenge) {
    return new Response("Bad Request", { status: 400 });
  }
  if (mode !== "subscribe" || token !== verifyToken) {
    return new Response("Forbidden", { status: 403 });
  }

  return new Response(challenge, {
    status: 200,
    headers: { "Content-Type": "text/plain" },
  });
}

async function handlePostWebhook(req: Request): Promise<Response> {
  const appSecret = Deno.env.get("META_WA_APP_SECRET");
  if (!appSecret) {
    console.error("whatsapp_webhook missing_app_secret");
    return new Response("Forbidden", { status: 403 });
  }

  const rawBody = await req.text();
  const signature = req.headers.get("X-Hub-Signature-256");
  const ok = await verifyMetaSignature(rawBody, signature, appSecret);
  if (!ok) {
    console.error("whatsapp_webhook invalid_signature");
    return new Response("Forbidden", { status: 403 });
  }

  let payload: unknown;
  try {
    payload = JSON.parse(rawBody);
  } catch {
    return new Response("Bad Request", { status: 400 });
  }

  try {
    if (isRecord(payload)) processPayload(payload);
  } catch (err) {
    console.error("whatsapp_webhook process_error", {
      name: err instanceof Error ? err.name : "unknown",
    });
  }

  return new Response(JSON.stringify({}), {
    status: 200,
    headers: { "Content-Type": "application/json" },
  });
}

Deno.serve(async (req) => {
  if (req.method === "GET") return handleGetVerification(req);
  if (req.method === "POST") return await handlePostWebhook(req);
  return new Response("Method not allowed", { status: 405 });
});
