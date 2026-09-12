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

/** EN placeholder keys from Postgres → RU for OS notification tray (app is RU-first). */
function strPayload(payload: Record<string, unknown>, key: string): string {
  const v = payload[key];
  return typeof v === "string" ? v.trim() : v != null ? String(v).trim() : "";
}

function formatStartsAt(payload: Record<string, unknown>): string {
  const raw = strPayload(payload, "starts_at");
  if (!raw) return "";
  const d = new Date(raw);
  if (Number.isNaN(d.getTime())) return raw;
  const dd = String(d.getUTCDate()).padStart(2, "0");
  const mm = String(d.getUTCMonth() + 1).padStart(2, "0");
  const hh = String(d.getUTCHours()).padStart(2, "0");
  const mi = String(d.getUTCMinutes()).padStart(2, "0");
  return `${dd}.${mm} ${hh}:${mi}`;
}

function localizePushTitle(title: string, kind: string): string {
  const key = (title || "").trim().toLowerCase();
  const byKey: Record<string, string> = {
    new_booking: "Новая запись",
    booking_confirmed: "Запись подтверждена",
    booking_cancelled: "Запись отменена",
    visit_completed: "Визит завершён",
    no_show: "Неявка",
    booking_rescheduled: "Запись перенесена",
    new_login: "Новый вход",
    team_invite: "Приглашение в команду",
    company_rules: "Новые правила компании",
    duty: "Дежурство",
    punch_correction: "Исправление отметки",
    photo: "Фото",
    file: "Файл",
    post: "Пост",
    message: "Сообщение",
    system: "Системное",
  };
  if (byKey[key]) return byKey[key];

  const byKind: Record<string, string> = {
    booking_created_host: byKey.new_booking,
    booking_booked_client: byKey.booking_confirmed,
    booking_cancelled_host: byKey.booking_cancelled,
    booking_cancelled_client: byKey.booking_cancelled,
    booking_completed_client: byKey.visit_completed,
    booking_no_show_client: byKey.no_show,
    booking_rescheduled: byKey.booking_rescheduled,
    attendance_invite: byKey.team_invite,
    attendance_rules_ack: byKey.company_rules,
    attendance_duty: byKey.duty,
    attendance_correction: byKey.punch_correction,
    account_login: byKey.new_login,
  };
  if (byKind[kind]) return byKind[kind];

  return (title || "").trim() || "Clover";
}

function localizePushBody(
  body: string,
  kind: string,
  payload: Record<string, unknown>,
): string {
  const raw = (body ?? "").trim();
  const key = String(payload.preview_key ?? raw).trim().toLowerCase();
  const service = strPayload(payload, "service_title") || "услугу";
  const workplace = strPayload(payload, "workplace_name") || "компании";
  const when = formatStartsAt(payload);

  const byKey: Record<string, string> = {
    photo: "Фото",
    file: "Файл",
    post: "Пост",
    message: "Сообщение",
    system: "Системное",
    client_booked: `Клиент записался на «${service}»`,
    you_are_booked: `Вы записаны на «${service}»`,
    client_cancelled: `Клиент отменил «${service}»`,
    host_cancelled: `Хозяин отменил «${service}»`,
    marked_completed: `«${service}» отмечена как оказанная`,
    marked_no_show: "Запись отмечена как «не пришёл»",
    new_time: when ? `Новое время: ${when}` : "Время записи изменено",
    invited_to_workplace: `Вас пригласили в «${workplace}»`,
    accept_rules: `Примите правила «${workplace}»`,
    duty_roster_updated: `Обновлён список дежурных в «${workplace}»`,
    correction_requested: `Работник просит исправить отметку в «${workplace}»`,
    correction_approved: "Запрос на исправление утверждён",
    correction_rejected: "Запрос на исправление отклонён",
    login_from_device: (() => {
      const client = strPayload(payload, "client");
      const platform = strPayload(payload, "platform");
      const device = strPayload(payload, "device_label");
      const where =
        device ||
        (client === "web"
          ? "веб"
          : platform === "ios"
            ? "iOS"
            : platform === "android"
              ? "Android"
              : "устройства");
      return `Вход в аккаунт с ${where}`;
    })(),
  };
  if (byKey[key]) return byKey[key];

  const messageKind = String(payload.message_kind ?? payload.kind ?? kind ?? "").trim();
  if (messageKind === "media") return byKey.photo;
  if (messageKind === "file") return byKey.file;
  if (messageKind === "post_ref") return byKey.post;

  const byKindBody: Record<string, string> = {
    booking_created_host: byKey.client_booked,
    booking_booked_client: byKey.you_are_booked,
    booking_cancelled_host: byKey.client_cancelled,
    booking_cancelled_client: byKey.host_cancelled,
    booking_completed_client: byKey.marked_completed,
    booking_no_show_client: byKey.marked_no_show,
    booking_rescheduled: byKey.new_time,
    attendance_invite: byKey.invited_to_workplace,
    attendance_rules_ack: byKey.accept_rules,
    attendance_duty: byKey.duty_roster_updated,
    attendance_correction: byKey.correction_requested,
    account_login: byKey.login_from_device,
  };
  if (byKindBody[kind] && !/[а-яёА-ЯЁ]/.test(raw)) return byKindBody[kind];

  // Legacy RU rows from before EN-keys migration — pass through.
  return raw || "Сообщение";
}

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
          title: localizePushTitle(row.title, row.kind),
          body: localizePushBody(row.body, row.kind, payload),
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
