/// POST /functions/v1/create_post
///
/// ⚠️ Тяжёлое base64-тело часто упирается в лимиты Edge (WORKER_RESOURCE_LIMIT).
/// Продакшен-клиент должен грузить байты напрямую в Storage + `posts`/`post_media` через REST (см. Flutter `PostCreateRepositoryImpl`).
///
/// Видео и JPEG-обложка — два файла в bucket `post_media`; в БД только строка про ролик:
/// - ролик: `posts/{post_id}/{media_uuid}.{ext}`
/// - постер: `posts/{post_id}/{media_uuid}__poster.jpg` (то же UUID)
/// Клиент строит URL постера из URL видео (без колонки в post_media).
///
/// Body:
/// {
///   title?: string,
///   description?: string,
///   cluster_id?: string | null,
///   aspect?: "9x16"|"1x1"|"3x4"|"16x9",
///   media: Array<{ type: "image"|"video", mime: string, ext: string, base64: string, aspect?: "9x16"|"1x1"|"3x4"|"16x9", poster_base64?: string }>
/// }
/// Для `type: "video"` поле `poster_base64` — JPEG выбранного кадра; без него в БД будет null (старые клиенты).
///
/// Flow:
/// 1) insert public.posts (user_id = auth.uid())
/// 2) upload each media → posts/{post_id}/{media_uuid}.{ext}
/// 3) для video при наличии poster_base64: upload JPEG → posts/{post_id}/{media_uuid}__poster.jpg
/// 4) insert public.post_media: url (видео), type, sort_order
/// Ответ JSON: media[] содержит media_id (UUID файла) — клиент передаёт его в upload_post_media_poster без запросов к post_media.
/// <reference path="../deno.d.ts" />
import { corsHeaders, handleCors } from "../_shared/cors.ts";
import { requireSupabaseUser } from "../_shared/supabase.ts";

function badRequest(message: string) {
  return new Response(JSON.stringify({ error: message }), {
    status: 400,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

function jsonOk(data: unknown) {
  return new Response(JSON.stringify(data), {
    status: 200,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

function toBytes(base64: string): Uint8Array {
  const cleaned = base64.includes(",") ? base64.split(",").pop()! : base64;
  const bin = atob(cleaned);
  const bytes = new Uint8Array(bin.length);
  for (let i = 0; i < bin.length; i++) bytes[i] = bin.charCodeAt(i);
  return bytes;
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

    const title = typeof (body as any).title === "string" ? (body as any).title : null;
    const description =
      typeof (body as any).description === "string" ? (body as any).description : null;
    const event_time =
      typeof (body as any).event_time === "string" && String((body as any).event_time).trim().length > 0
        ? String((body as any).event_time).trim()
        : null;
    const duration_minutes_raw = (body as any).duration_minutes;
    const duration_minutes =
      typeof duration_minutes_raw === "number" && Number.isFinite(duration_minutes_raw)
        ? Math.trunc(duration_minutes_raw)
        : null;
    const cluster_id =
      (body as any).cluster_id === null || typeof (body as any).cluster_id === "string"
        ? (body as any).cluster_id
        : undefined;
    const aspect = typeof (body as any).aspect === "string" ? (body as any).aspect : null;
    if (
      aspect !== null &&
      aspect !== "9x16" &&
      aspect !== "1x1" &&
      aspect !== "3x4" &&
      aspect !== "16x9"
    ) {
      return badRequest("aspect invalid");
    }

    const media = Array.isArray((body as any).media) ? (body as any).media : null;
    if (!media || media.length === 0) return badRequest("media[] is required");
    if (media.length > 10) return badRequest("Too many media items (max 10)");

    // 1) create post row
    const { data: postRow, error: postErr } = await supabase
      .from("posts")
      .insert({
        user_id: user.id,
        title,
        description,
        cluster_id: cluster_id === undefined ? null : cluster_id,
        event_time,
        duration: duration_minutes === null ? null : `${duration_minutes} minutes`,
      })
      .select("id")
      .single();

    if (postErr || !postRow?.id) {
      return badRequest(postErr?.message ?? "Failed to create post");
    }

    const postId = postRow.id as string;
    const uploaded: Array<{
      id: string;
      path: string;
      url: string;
      type: string;
      sort_order: number;
    }> = [];

    // 2) upload media
    for (let i = 0; i < media.length; i++) {
      const m = media[i] ?? {};
      const type = String(m.type ?? "").trim();
      const mime = String(m.mime ?? "").trim();
      const extRaw = String(m.ext ?? "").trim().toLowerCase();
      const ext = extRaw.replace(/[^a-z0-9]/g, "");
      const base64 = String(m.base64 ?? "");
      const itemAspect = typeof m.aspect === "string" ? String(m.aspect).trim() : null;

      if (
        itemAspect !== null &&
        itemAspect !== "" &&
        itemAspect !== "9x16" &&
        itemAspect !== "1x1" &&
        itemAspect !== "3x4" &&
        itemAspect !== "16x9"
      ) {
        return badRequest(`media[${i}].aspect invalid`);
      }

      if (type !== "image" && type !== "video") return badRequest(`media[${i}].type invalid`);
      if (!mime) return badRequest(`media[${i}].mime required`);
      if (!ext) return badRequest(`media[${i}].ext required`);
      if (!base64) return badRequest(`media[${i}].base64 required`);

      const mediaId = crypto.randomUUID();
      const path = `posts/${postId}/${mediaId}.${ext}`;
      const bytes = toBytes(base64);

      const { error: upErr } = await supabase.storage
        .from("post_media")
        .upload(path, bytes, { contentType: mime, upsert: true });

      if (upErr) {
        return badRequest(`upload failed: ${upErr.message}`);
      }

      const { data: pub } = supabase.storage.from("post_media").getPublicUrl(path);

      if (type === "video") {
        const posterRaw = (m as { poster_base64?: unknown }).poster_base64;
        const posterBase64 =
          typeof posterRaw === "string" && posterRaw.trim().length > 0 ? posterRaw.trim() : "";
        if (posterBase64) {
          const pBytes = toBytes(posterBase64);
          const posterPath = `posts/${postId}/${mediaId}__poster.jpg`;
          const { error: pErr } = await supabase.storage
            .from("post_media")
            .upload(posterPath, pBytes, { contentType: "image/jpeg", upsert: true });
          if (pErr) {
            return badRequest(`poster upload failed: ${pErr.message}`);
          }
        }
      }

      uploaded.push({ id: mediaId, path, url: pub.publicUrl, type, sort_order: i });
    }

    // 3) insert post_media rows
    const { error: pmErr } = await supabase.from("post_media").insert(
      uploaded.map((u) => ({
        post_id: postId,
        url: u.url,
        type: u.type,
        sort_order: u.sort_order,
      })),
    );
    if (pmErr) {
      return badRequest(pmErr.message);
    }

    return jsonOk({
      ok: true,
      post_id: postId,
      media: uploaded.map((u) => ({
        url: u.url,
        type: u.type,
        sort_order: u.sort_order,
        media_id: u.id,
      })),
    });
  } catch (e) {
    return new Response(JSON.stringify({ error: String(e) }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});

