/// POST /functions/v1/send_chat_attachments
/// Content-Type: multipart/form-data
/// Поля: conversation_id (обязательно), caption, reply_to (опционально).
/// Файлы: несколько частей с именем поля `files`.
///
/// Загрузка в bucket `chat_media` + один RPC `send_message_with_attachments`.
/// Ограничения по типам/размеру/количеству — на клиенте; здесь только безопасность + лимит RPC.
/// <reference path="../deno.d.ts" />
import { corsHeaders, handleCors } from "../_shared/cors.ts";
import { requireSupabaseUser } from "../_shared/supabase.ts";

const RPC_MAX_ATTACHMENTS = 100;

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

function mimeFromFilename(name: string): string | null {
  const i = name.lastIndexOf(".");
  if (i <= 0 || i >= name.length - 1) return null;
  const ext = name.slice(i + 1).toLowerCase();
  switch (ext) {
    case "jpg":
    case "jpeg":
      return "image/jpeg";
    case "png":
      return "image/png";
    case "webp":
      return "image/webp";
    case "gif":
      return "image/gif";
    case "heic":
      return "image/heic";
    case "pdf":
      return "application/pdf";
    case "mp4":
      return "video/mp4";
    case "mov":
      return "video/quicktime";
    default:
      return null;
  }
}

function resolveMime(file: File): string {
  const raw = (file.type ?? "").trim().toLowerCase();
  if (raw.length > 0) return raw;
  return mimeFromFilename(file.name) ?? "application/octet-stream";
}

function pickExt(mime: string, filename: string): string {
  const dot = filename.lastIndexOf(".");
  if (dot > 0 && dot < filename.length - 1) {
    return filename.slice(dot).toLowerCase().slice(0, 11);
  }
  switch (mime) {
    case "image/jpeg":
      return ".jpg";
    case "image/png":
      return ".png";
    case "image/webp":
      return ".webp";
    case "image/gif":
      return ".gif";
    case "image/heic":
      return ".heic";
    case "application/pdf":
      return ".pdf";
    case "video/mp4":
      return ".mp4";
    case "video/quicktime":
      return ".mov";
    default:
      return ".bin";
  }
}

function isImageMime(m: string): boolean {
  return m.startsWith("image/");
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

    const ct = req.headers.get("content-type") ?? "";
    if (!ct.toLowerCase().includes("multipart/form-data")) {
      return badRequest("Expected multipart/form-data");
    }

    const form = await req.formData();
    const conversationId = form.get("conversation_id")?.toString()?.trim() ?? "";
    if (!conversationId) return badRequest("conversation_id required");

    const captionRaw = form.get("caption");
    const caption =
      captionRaw === null || captionRaw === ""
        ? null
        : typeof captionRaw === "string"
          ? captionRaw.trim() || null
          : null;

    const replyRaw = form.get("reply_to");
    const replyTo =
      replyRaw === null || replyRaw === ""
        ? null
        : typeof replyRaw === "string"
          ? replyRaw.trim() || null
          : null;

    const rawFiles = form.getAll("files").filter((x): x is File => x instanceof File);
    if (rawFiles.length === 0) return badRequest("files required");
    if (rawFiles.length > RPC_MAX_ATTACHMENTS) {
      return badRequest(`max ${RPC_MAX_ATTACHMENTS} files`);
    }

    const uid = user.id;
    const attachments: Record<string, unknown>[] = [];

    for (const file of rawFiles) {
      const mime = resolveMime(file);
      const buf = new Uint8Array(await file.arrayBuffer());
      const ext = pickExt(mime, file.name);
      const stamp = Date.now();
      const rnd = crypto.randomUUID();
      const path = `${uid}/${conversationId}/${stamp}_${rnd}${ext}`;

      const { error: upErr } = await supabase.storage.from("chat_media").upload(path, buf, {
        upsert: true,
        contentType: mime,
      });
      if (upErr) {
        return new Response(JSON.stringify({ error: "storage_upload_failed", detail: upErr.message }), {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }

      attachments.push({
        bucket: "chat_media",
        path,
        mime,
        size_bytes: buf.byteLength,
      });
    }

    const allImages = attachments.every((a) => typeof a.mime === "string" && isImageMime(a.mime as string));
    const kind = allImages ? "media" : "file";

    const { data: mid, error: rpcErr } = await supabase.rpc("send_message_with_attachments", {
      p_conversation_id: conversationId,
      p_kind: kind,
      p_text: caption,
      p_reply_to: replyTo,
      p_attachments: attachments,
    });

    if (rpcErr || mid === null || mid === undefined) {
      return new Response(JSON.stringify({ error: "rpc_failed", detail: rpcErr?.message ?? String(mid) }), {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    return jsonOk({ message_id: mid });
  } catch (e) {
    return new Response(JSON.stringify({ error: "internal", detail: `${e}` }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
