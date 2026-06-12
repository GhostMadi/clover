/// POST /functions/v1/upload_post_media_poster
/// Загрузка JPEG обложки в Storage. В БД не пишем — колонки poster_url нет.
///
/// Body: { post_id: uuid, media_id: uuid, poster_base64: string }
/// — [media_id] тот же UUID имени файла ролика (см. ответ create_post.media[].media_id).
///
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

const uuidRe =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

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

    const postId = typeof (body as any).post_id === "string" ? String((body as any).post_id).trim() : "";
    const mediaId =
      typeof (body as any).media_id === "string" ? String((body as any).media_id).trim() : "";
    const posterBase64 =
      typeof (body as any).poster_base64 === "string" ? String((body as any).poster_base64).trim() : "";

    if (!postId) return badRequest("post_id required");
    if (!mediaId || !uuidRe.test(mediaId)) return badRequest("media_id required (uuid)");
    if (!posterBase64) return badRequest("poster_base64 required");

    const { data: postRow, error: postErr } = await supabase
      .from("posts")
      .select("user_id")
      .eq("id", postId)
      .maybeSingle();

    if (postErr || !postRow) return badRequest(postErr?.message ?? "Post not found");
    if (postRow.user_id !== user.id) return badRequest("Forbidden");

    const posterPath = `posts/${postId}/${mediaId}__poster.jpg`;
    const pBytes = toBytes(posterBase64);

    const { error: upErr } = await supabase.storage
      .from("post_media")
      .upload(posterPath, pBytes, { contentType: "image/jpeg", upsert: true });

    if (upErr) return badRequest(`poster upload failed: ${upErr.message}`);

    return jsonOk({ ok: true });
  } catch (e) {
    return new Response(JSON.stringify({ error: String(e) }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
