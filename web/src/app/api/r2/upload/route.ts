import { NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";

export const runtime = "nodejs";

/** Max body for proxied R2 upload — Vercel serverless request limit ~4.5MB. */
const MAX_BYTES = 4 * 1024 * 1024;

/**
 * Browser → same-origin → server PUT to R2.
 * Avoids R2 bucket CORS (browser cannot PUT to *.r2.cloudflarestorage.com without it).
 */
export async function POST(request: Request) {
  try {
    const supabase = await createClient();
    const {
      data: { session },
    } = await supabase.auth.getSession();
    const token = session?.access_token?.trim();
    if (!token) {
      return NextResponse.json({ error: "Требуется вход" }, { status: 401 });
    }

    const form = await request.formData();
    const file = form.get("file");
    const fileNameRaw = String(form.get("fileName") ?? "").trim();
    const folder = String(form.get("folder") ?? "media").trim() || "media";
    const contentTypeRaw = String(form.get("contentType") ?? "").trim();

    if (!(file instanceof Blob) || file.size === 0) {
      return NextResponse.json({ error: "Нет файла" }, { status: 400 });
    }
    if (file.size > MAX_BYTES) {
      return NextResponse.json(
        { error: `Файл слишком большой (макс ${MAX_BYTES} байт)` },
        { status: 413 },
      );
    }

    const fileName = fileNameRaw || "file";
    const contentType =
      contentTypeRaw ||
      (file.type?.trim() ? file.type.trim() : "application/octet-stream");

    const base = process.env.NEXT_PUBLIC_SUPABASE_URL?.replace(/\/$/, "");
    const anon = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;
    if (!base || !anon) {
      return NextResponse.json({ error: "Нет конфигурации Supabase" }, { status: 500 });
    }

    const signedRes = await fetch(`${base}/functions/v1/get-upload-url`, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${token}`,
        apikey: anon,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ fileName, fileType: contentType, folder }),
    });
    const signed = (await signedRes.json().catch(() => null)) as {
      uploadUrl?: string;
      publicUrl?: string;
      fileKey?: string;
      error?: string;
      detail?: string;
    } | null;
    if (!signedRes.ok || !signed) {
      return NextResponse.json(
        {
          error:
            signed?.detail || signed?.error || `get-upload-url HTTP ${signedRes.status}`,
        },
        { status: 502 },
      );
    }

    const uploadUrl = String(signed.uploadUrl ?? "").trim();
    const publicUrl = String(signed.publicUrl ?? "").trim();
    const fileKey = String(signed.fileKey ?? "").trim();
    if (!uploadUrl || !publicUrl || !fileKey) {
      return NextResponse.json(
        { error: "get-upload-url не вернул uploadUrl/publicUrl/fileKey" },
        { status: 502 },
      );
    }

    const bytes = Buffer.from(await file.arrayBuffer());
    const put = await fetch(uploadUrl, {
      method: "PUT",
      headers: { "Content-Type": contentType },
      body: bytes,
    });
    if (!put.ok) {
      const detail = await put.text().catch(() => "");
      return NextResponse.json(
        {
          error: `R2 upload failed: HTTP ${put.status}`,
          detail: detail.slice(0, 300),
        },
        { status: 502 },
      );
    }

    return NextResponse.json({
      fileKey,
      publicUrl,
      stablePublicUrl: publicUrl,
    });
  } catch (e) {
    return NextResponse.json(
      { error: e instanceof Error ? e.message : String(e) },
      { status: 500 },
    );
  }
}
