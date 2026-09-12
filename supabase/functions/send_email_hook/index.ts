/// Auth Hook: Send Email → Resend HTTP + hourly OTP rate limit (max 3 / email).
/// Docs: https://supabase.com/docs/guides/auth/auth-hooks/send-email-hook
/// Spec: docs/supabase/SPEC_EMAIL_AUTH.md
/// <reference path="../deno.d.ts" />

import { Webhook } from "https://esm.sh/standardwebhooks@1.0.0";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";

type SendEmailPayload = {
  user?: { email?: string | null };
  email_data?: {
    token?: string | null;
    token_hash?: string | null;
    redirect_to?: string | null;
    email_action_type?: string | null;
    site_url?: string | null;
  };
};

const OTP_MAX_PER_HOUR = 3;

function jsonError(httpCode: number, message: string, status = 200) {
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

function normalizeEmail(raw: string): string {
  return raw.trim().toLowerCase();
}

function subjectFor(action: string): string {
  switch (action) {
    case "recovery":
      return "Код для сброса пароля Clover";
    case "signup":
    case "invite":
    case "magiclink":
    case "email_change":
    default:
      return "Код подтверждения Clover";
  }
}

function htmlBody(otp: string, action: string): string {
  const lead =
    action === "recovery"
      ? "Код для сброса пароля:"
      : "Ваш код подтверждения:";
  return `<!DOCTYPE html>
<html><body style="font-family:system-ui,sans-serif;background:#f7faf5;padding:32px;color:#14210f">
  <div style="max-width:420px;margin:0 auto;background:#fff;border-radius:16px;padding:28px;border:1px solid #e3eadc">
    <p style="margin:0 0 8px;font-size:13px;font-weight:600;color:#8bc34a">Clover</p>
    <p style="margin:0 0 16px;font-size:16px;line-height:1.45">${lead}</p>
    <p style="margin:0;font-size:32px;letter-spacing:0.28em;font-weight:700">${otp}</p>
    <p style="margin:20px 0 0;font-size:13px;color:#6b7566">Код действует короткое время. Если это не вы — проигнорируйте письмо.</p>
  </div>
</body></html>`;
}

Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return new Response("Method not allowed", { status: 405 });
  }

  const hookSecret = Deno.env.get("SEND_EMAIL_HOOK_SECRET");
  const resendKey = Deno.env.get("RESEND_API_KEY");
  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  const fromEmail = Deno.env.get("CLOVER_OTP_FROM_EMAIL") ?? "welcome@clover.com.kz";
  const fromName = Deno.env.get("CLOVER_OTP_FROM_NAME") ?? "Clover";

  if (!hookSecret || !resendKey || !supabaseUrl || !serviceKey) {
    return jsonError(500, "Missing secrets for send_email_hook", 500);
  }

  const payload = await req.text();
  const headers = Object.fromEntries(req.headers);
  let data: SendEmailPayload;
  try {
    const base64Secret = hookSecret.replace("v1,whsec_", "");
    const wh = new Webhook(base64Secret);
    data = wh.verify(payload, headers) as SendEmailPayload;
  } catch {
    return jsonError(401, "Invalid webhook signature", 401);
  }

  const email = normalizeEmail(String(data.user?.email ?? ""));
  const otp = String(data.email_data?.token ?? "").trim();
  const action = String(data.email_data?.email_action_type ?? "signup");

  if (!email.includes("@") || !otp) {
    return jsonError(400, "Missing email or otp in hook payload", 400);
  }

  const admin = createClient(supabaseUrl, serviceKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  const { data: waitRaw, error: claimError } = await admin.rpc(
    "auth_claim_email_otp_send",
    { p_email: email, p_max_per_hour: OTP_MAX_PER_HOUR },
  );
  if (claimError) {
    console.error("send_email_hook claim_error", claimError.message);
    return jsonError(500, "OTP rate limit check failed", 500);
  }
  const wait = typeof waitRaw === "number" ? waitRaw : Number(waitRaw) || 0;
  if (wait > 0) {
    return jsonError(
      429,
      `Too many OTP emails. Retry in ${wait} seconds.`,
      200,
    );
  }

  const resendRes = await fetch("https://api.resend.com/emails", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${resendKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      from: `${fromName} <${fromEmail}>`,
      to: [email],
      subject: subjectFor(action),
      html: htmlBody(otp, action),
    }),
  });

  if (!resendRes.ok) {
    const detail = await resendRes.text().catch(() => "");
    console.error("send_email_hook resend_error", resendRes.status, detail.slice(0, 200));
    await admin.rpc("auth_release_last_email_otp_send", { p_email: email }).catch((e) => {
      console.error("send_email_hook release_error", String(e));
    });
    return jsonError(500, "Failed to send OTP email", 500);
  }

  return new Response(JSON.stringify({}), {
    status: 200,
    headers: { "Content-Type": "application/json" },
  });
});
