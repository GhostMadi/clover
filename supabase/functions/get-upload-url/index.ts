/// POST /functions/v1/get-upload-url
/// Presigned PUT URL for Cloudflare R2 (S3-compatible).
///
/// Body: { fileName: string, fileType: string, folder?: string }
/// Secrets: see `_shared/r2.ts`
///
/// <reference path="../deno.d.ts" />
import { corsHeaders, handleCors } from "../_shared/cors.ts";
import { createPresignedPutUrl } from "../_shared/r2.ts";
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

/** folder: letters, digits, `_`, `-`, `/` (no `..`, no leading slash). */
function sanitizeFolder(raw: string): string | null {
  const folder = raw.trim().replace(/^\/+|\/+$/g, "");
  if (!folder) return "media";
  if (folder.includes("..")) return null;
  if (!/^[a-zA-Z0-9/_-]+$/.test(folder)) return null;
  return folder;
}

function sanitizeFileName(raw: string): string {
  const base = raw.trim().split(/[/\\]/).pop() ?? "file";
  const cleaned = base.replace(/[^a-zA-Z0-9._-]/g, "_").replace(/^\.+/, "");
  return cleaned.slice(0, 120) || "file";
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
    const { user } = authCtx;

    const body = await req.json().catch(() => null);
    if (!body || typeof body !== "object") return badRequest("Invalid JSON body");

    const fileNameRaw =
      typeof (body as { fileName?: unknown }).fileName === "string"
        ? String((body as { fileName: string }).fileName)
        : "";
    const fileType =
      typeof (body as { fileType?: unknown }).fileType === "string"
        ? String((body as { fileType: string }).fileType).trim()
        : "";
    const folderRaw =
      typeof (body as { folder?: unknown }).folder === "string"
        ? String((body as { folder: string }).folder)
        : "media";

    if (!fileNameRaw.trim()) return badRequest("fileName required");
    if (!fileType) return badRequest("fileType required");

    const folder = sanitizeFolder(folderRaw);
    if (!folder) return badRequest("Invalid folder");

    const safeName = sanitizeFileName(fileNameRaw);
    const objectId = crypto.randomUUID();
    const fileKey = `${folder}/${user.id}/${objectId}-${safeName}`;

    const result = await createPresignedPutUrl({
      fileKey,
      contentType: fileType,
    });

    return jsonOk(result);
  } catch (e) {
    return new Response(JSON.stringify({ error: String(e) }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
