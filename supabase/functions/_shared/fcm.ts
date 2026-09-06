/// FCM HTTP v1 helpers (Google service account → OAuth → messages:send).
/// Secrets: FCM_PROJECT_ID + FCM_CLIENT_EMAIL + FCM_PRIVATE_KEY
///   or single FIREBASE_SERVICE_ACCOUNT_JSON.
/// <reference path="../deno.d.ts" />

export type FcmServiceAccount = {
  project_id: string;
  client_email: string;
  private_key: string;
};

type CachedToken = { accessToken: string; expiresAtMs: number };

let cached: CachedToken | null = null;

export function loadFcmServiceAccount(): FcmServiceAccount {
  const rawJson = Deno.env.get("FIREBASE_SERVICE_ACCOUNT_JSON")?.trim();
  if (rawJson) {
    const parsed = JSON.parse(rawJson) as Record<string, unknown>;
    const projectId = String(parsed.project_id ?? "").trim();
    const clientEmail = String(parsed.client_email ?? "").trim();
    const privateKey = String(parsed.private_key ?? "").replace(/\\n/g, "\n").trim();
    if (!projectId || !clientEmail || !privateKey) {
      throw new Error("FIREBASE_SERVICE_ACCOUNT_JSON missing project_id/client_email/private_key");
    }
    return { project_id: projectId, client_email: clientEmail, private_key: privateKey };
  }

  const projectId = Deno.env.get("FCM_PROJECT_ID")?.trim() ?? "";
  const clientEmail = Deno.env.get("FCM_CLIENT_EMAIL")?.trim() ?? "";
  const privateKey = (Deno.env.get("FCM_PRIVATE_KEY") ?? "").replace(/\\n/g, "\n").trim();
  if (!projectId || !clientEmail || !privateKey) {
    throw new Error(
      "Missing FCM secrets: set FIREBASE_SERVICE_ACCOUNT_JSON or FCM_PROJECT_ID + FCM_CLIENT_EMAIL + FCM_PRIVATE_KEY",
    );
  }
  return { project_id: projectId, client_email: clientEmail, private_key: privateKey };
}

function b64url(data: Uint8Array | string): string {
  const bytes = typeof data === "string" ? new TextEncoder().encode(data) : data;
  let bin = "";
  for (const b of bytes) bin += String.fromCharCode(b);
  return btoa(bin).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/g, "");
}

async function importPrivateKey(pem: string): Promise<CryptoKey> {
  const cleaned = pem
    .replace(/-----BEGIN PRIVATE KEY-----/g, "")
    .replace(/-----END PRIVATE KEY-----/g, "")
    .replace(/\s+/g, "");
  const raw = Uint8Array.from(atob(cleaned), (c) => c.charCodeAt(0));
  return crypto.subtle.importKey(
    "pkcs8",
    raw,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
}

export async function getFcmAccessToken(sa: FcmServiceAccount): Promise<string> {
  const now = Date.now();
  if (cached && cached.expiresAtMs > now + 60_000) {
    return cached.accessToken;
  }

  const iat = Math.floor(now / 1000);
  const header = b64url(JSON.stringify({ alg: "RS256", typ: "JWT" }));
  const claim = b64url(
    JSON.stringify({
      iss: sa.client_email,
      scope: "https://www.googleapis.com/auth/firebase.messaging",
      aud: "https://oauth2.googleapis.com/token",
      iat,
      exp: iat + 3600,
    }),
  );
  const unsigned = `${header}.${claim}`;
  const key = await importPrivateKey(sa.private_key);
  const sig = new Uint8Array(
    await crypto.subtle.sign("RSASSA-PKCS1-v1_5", key, new TextEncoder().encode(unsigned)),
  );
  const jwt = `${unsigned}.${b64url(sig)}`;

  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  });
  const body = await res.json() as { access_token?: string; expires_in?: number; error?: string };
  if (!res.ok || !body.access_token) {
    throw new Error(`FCM OAuth failed: ${body.error ?? res.status}`);
  }

  const expiresIn = typeof body.expires_in === "number" ? body.expires_in : 3600;
  cached = {
    accessToken: body.access_token,
    expiresAtMs: now + expiresIn * 1000,
  };
  return body.accessToken;
}

export type FcmSendResult =
  | { ok: true; messageId?: string }
  | { ok: false; status: number; error: string; invalidToken: boolean };

function flattenData(payload: Record<string, unknown>, kind: string): Record<string, string> {
  const data: Record<string, string> = { kind };
  for (const [k, v] of Object.entries(payload)) {
    if (v == null) continue;
    data[k] = typeof v === "string" ? v : JSON.stringify(v);
  }
  return data;
}

export async function sendFcmMessage(params: {
  sa: FcmServiceAccount;
  accessToken: string;
  token: string;
  title: string;
  body: string;
  kind: string;
  payload: Record<string, unknown>;
}): Promise<FcmSendResult> {
  const url = `https://fcm.googleapis.com/v1/projects/${params.sa.project_id}/messages:send`;
  const res = await fetch(url, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${params.accessToken}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      message: {
        token: params.token,
        notification: {
          title: params.title,
          body: params.body,
        },
        data: flattenData(params.payload, params.kind),
        android: {
          priority: "HIGH",
        },
        apns: {
          payload: {
            aps: {
              sound: "default",
              "content-available": 1,
            },
          },
        },
      },
    }),
  });

  const text = await res.text();
  let json: { name?: string; error?: { status?: string; message?: string; details?: unknown[] } } = {};
  try {
    json = text ? JSON.parse(text) : {};
  } catch {
    json = {};
  }

  if (res.ok) {
    return { ok: true, messageId: json.name };
  }

  const status = json.error?.status ?? "";
  const message = json.error?.message ?? text.slice(0, 500) ?? `HTTP ${res.status}`;
  const invalidToken =
    status === "NOT_FOUND" ||
    status === "UNREGISTERED" ||
    /not a valid fcm registration token/i.test(message) ||
    /requested entity was not found/i.test(message);

  return { ok: false, status: res.status, error: `${status || res.status}: ${message}`, invalidToken };
}
