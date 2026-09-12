"use client";

import { createClient } from "@/lib/supabase/client";

const TOKEN_KEY = "clover-honest-quiz-token";

export function getOrCreateClientToken(): string {
  if (typeof window === "undefined") return "";
  let t = localStorage.getItem(TOKEN_KEY);
  if (!t || t.length < 8) {
    t =
      typeof crypto !== "undefined" && "randomUUID" in crypto
        ? crypto.randomUUID()
        : `hq-${Date.now()}-${Math.random().toString(36).slice(2)}`;
    localStorage.setItem(TOKEN_KEY, t);
  }
  return t;
}

export type HonestAnswers = {
  q1?: "yes";
  q2?: "yes";
  q3?: "send";
  q1_no_attempts?: number;
  q2_no_attempts?: number;
  q3_no_attempts?: number;
};

export async function upsertHonestQuiz(opts: {
  answers: HonestAnswers;
  finished?: boolean;
  photoDataUrl?: string | null;
}): Promise<string | null> {
  const supabase = createClient();
  const token = getOrCreateClientToken();
  const { data, error } = await supabase.rpc("honest_quiz_upsert", {
    p_client_token: token,
    p_answers: opts.answers,
    p_finished: opts.finished ?? false,
    p_user_agent: typeof navigator !== "undefined" ? navigator.userAgent : null,
    p_photo_data_url: opts.photoDataUrl ?? null,
  });
  if (error) {
    console.error("honest_quiz_upsert", error.message);
    return null;
  }
  return typeof data === "string" ? data : data ? String(data) : null;
}

export type HonestRunSummary = {
  id: string;
  createdAt: string;
  updatedAt: string;
  finished: boolean;
  answers: HonestAnswers;
  hasPhoto: boolean;
  userAgent: string | null;
};

export type HonestRunDetail = HonestRunSummary & {
  photoDataUrl: string | null;
};

export async function adminListRuns(): Promise<HonestRunSummary[]> {
  const supabase = createClient();
  const { data, error } = await supabase.rpc("honest_quiz_admin_list");
  if (error) throw new Error(error.message);
  const rows = Array.isArray(data) ? data : [];
  return rows.map((raw) => {
    const r = raw as Record<string, unknown>;
    return {
      id: String(r.id ?? ""),
      createdAt: String(r.created_at ?? ""),
      updatedAt: String(r.updated_at ?? ""),
      finished: r.finished === true,
      answers: (r.answers as HonestAnswers) ?? {},
      hasPhoto: r.has_photo === true,
      userAgent: (r.user_agent as string | null) ?? null,
    };
  }).filter((x) => x.id);
}

export async function adminGetRun(id: string): Promise<HonestRunDetail | null> {
  const supabase = createClient();
  const { data, error } = await supabase.rpc("honest_quiz_admin_get", {
    p_id: id,
  });
  if (error) throw new Error(error.message);
  if (!data || typeof data !== "object") return null;
  const r = data as Record<string, unknown>;
  return {
    id: String(r.id ?? ""),
    createdAt: String(r.created_at ?? ""),
    updatedAt: String(r.updated_at ?? ""),
    finished: r.finished === true,
    answers: (r.answers as HonestAnswers) ?? {},
    hasPhoto: !!r.photo_data_url,
    photoDataUrl: (r.photo_data_url as string | null) ?? null,
    userAgent: (r.user_agent as string | null) ?? null,
  };
}

/** Compress image for temporary DB storage (~max edge 960, jpeg). */
export async function fileToCompressedDataUrl(file: File): Promise<string> {
  const bitmap = await createImageBitmap(file);
  const maxEdge = 960;
  const scale = Math.min(1, maxEdge / Math.max(bitmap.width, bitmap.height));
  const w = Math.max(1, Math.round(bitmap.width * scale));
  const h = Math.max(1, Math.round(bitmap.height * scale));
  const canvas = document.createElement("canvas");
  canvas.width = w;
  canvas.height = h;
  const ctx = canvas.getContext("2d");
  if (!ctx) throw new Error("canvas");
  ctx.drawImage(bitmap, 0, 0, w, h);
  bitmap.close();
  let quality = 0.72;
  let dataUrl = canvas.toDataURL("image/jpeg", quality);
  while (dataUrl.length > 700_000 && quality > 0.35) {
    quality -= 0.1;
    dataUrl = canvas.toDataURL("image/jpeg", quality);
  }
  if (dataUrl.length > 900_000) {
    throw new Error("Фото слишком большое — попробуй другое");
  }
  return dataUrl;
}
