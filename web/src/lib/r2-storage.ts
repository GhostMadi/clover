"use client";

/**
 * Single client entry for Cloudflare R2 uploads/deletes via Edge Functions.
 * Do not call Supabase Storage for new media — use this module.
 *
 * Web uploads go through same-origin `/api/r2/upload` (server PUT → R2)
 * so the browser does not need R2 bucket CORS.
 */

import { createClient } from "@/lib/supabase/client";

export type R2UploadResult = {
  fileKey: string;
  /** With cache-bust query */
  publicUrl: string;
  /** Without query — for DB / delete */
  stablePublicUrl: string;
};

function functionsBase(): { base: string; anon: string } {
  const base = process.env.NEXT_PUBLIC_SUPABASE_URL?.replace(/\/$/, "");
  const anon = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;
  if (!base || !anon) throw new Error("Нет конфигурации Supabase");
  return { base, anon };
}

async function requireAccessToken(): Promise<string> {
  const supabase = createClient();
  const {
    data: { session },
  } = await supabase.auth.getSession();
  const token = session?.access_token?.trim();
  if (!token) throw new Error("Требуется вход");
  return token;
}

async function invokeJson<T>(
  functionName: string,
  body: Record<string, unknown>,
): Promise<T> {
  const { base, anon } = functionsBase();
  const token = await requireAccessToken();
  const res = await fetch(`${base}/functions/v1/${functionName}`, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${token}`,
      apikey: anon,
      "Content-Type": "application/json",
    },
    body: JSON.stringify(body),
  });
  const json = (await res.json().catch(() => null)) as T & { error?: string; detail?: string };
  if (!res.ok) {
    throw new Error(
      (json && "detail" in json && json.detail) ||
        (json && "error" in json && json.error) ||
        `Edge ${functionName} failed`,
    );
  }
  return json as T;
}

function guessContentType(fileName: string, fallback?: string): string {
  if (fallback?.trim()) return fallback.trim();
  const ext = fileName.includes(".")
    ? fileName.slice(fileName.lastIndexOf(".")).toLowerCase()
    : "";
  switch (ext) {
    case ".jpg":
    case ".jpeg":
      return "image/jpeg";
    case ".png":
      return "image/png";
    case ".webp":
      return "image/webp";
    case ".gif":
      return "image/gif";
    case ".mp4":
      return "video/mp4";
    case ".mov":
      return "video/quicktime";
    case ".pdf":
      return "application/pdf";
    default:
      return "application/octet-stream";
  }
}

/** Upload bytes/File to R2 via same-origin proxy (no browser→R2 CORS). */
export async function uploadToR2(opts: {
  file: Blob | File;
  fileName: string;
  folder?: string;
  contentType?: string;
}): Promise<R2UploadResult> {
  const fileName = opts.fileName.trim() || "file";
  const folder = (opts.folder ?? "media").trim() || "media";
  const contentType = guessContentType(
    fileName,
    opts.contentType || (opts.file instanceof File ? opts.file.type : undefined),
  );

  const form = new FormData();
  form.set("file", opts.file, fileName);
  form.set("fileName", fileName);
  form.set("folder", folder);
  form.set("contentType", contentType);

  const res = await fetch("/api/r2/upload", {
    method: "POST",
    body: form,
  });
  const json = (await res.json().catch(() => null)) as {
    fileKey?: string;
    publicUrl?: string;
    stablePublicUrl?: string;
    error?: string;
    detail?: string;
  } | null;

  if (!res.ok || !json) {
    throw new Error(json?.detail || json?.error || `R2 upload failed: HTTP ${res.status}`);
  }

  const publicUrl = String(json.publicUrl ?? json.stablePublicUrl ?? "").trim();
  const fileKey = String(json.fileKey ?? "").trim();
  const stablePublicUrl = String(json.stablePublicUrl ?? publicUrl).trim();
  if (!publicUrl || !fileKey) {
    throw new Error("upload не вернул publicUrl/fileKey");
  }

  const sep = publicUrl.includes("?") ? "&" : "?";
  return {
    fileKey,
    publicUrl: `${publicUrl}${sep}v=${Date.now()}`,
    stablePublicUrl,
  };
}

/** Best-effort delete of owned R2 objects. */
export async function deleteFromR2(opts: {
  urls?: string[];
  fileKeys?: string[];
}): Promise<void> {
  const urls = (opts.urls ?? [])
    .map((u) => u.trim().split("?")[0] ?? "")
    .filter(Boolean);
  const fileKeys = (opts.fileKeys ?? []).map((k) => k.trim()).filter(Boolean);
  if (urls.length === 0 && fileKeys.length === 0) return;
  try {
    await invokeJson("delete-r2-objects", {
      ...(urls.length ? { urls } : {}),
      ...(fileKeys.length ? { fileKeys } : {}),
    });
  } catch {
    /* best effort */
  }
}
