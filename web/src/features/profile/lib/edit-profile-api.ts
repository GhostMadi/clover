"use client";

import { createClient } from "@/lib/supabase/client";

export type EditProfilePayload = {
  fullName: string;
  bio: string;
  countryCode: string | null;
  cityCode: string | null;
  tagKeys: string[];
  avatarFile?: File | null;
  backgroundFile?: File | null;
};

function nullableTrim(value: string | null | undefined): string | null {
  const t = value?.trim() ?? "";
  return t ? t : null;
}

async function uploadJpeg(
  bucket: "avatars" | "profile_backgrounds",
  path: string,
  file: File,
): Promise<string> {
  const supabase = createClient();
  const { error } = await supabase.storage.from(bucket).upload(path, file, {
    upsert: true,
    contentType: file.type || "image/jpeg",
  });
  if (error) throw error;
  const { data } = supabase.storage.from(bucket).getPublicUrl(path);
  // cache-bust
  return `${data.publicUrl}?t=${Date.now()}`;
}

async function resolveTagIds(keys: string[]): Promise<string[]> {
  const supabase = createClient();
  const normalized = [...new Set(keys.map((k) => k.trim()).filter(Boolean))];
  if (normalized.length === 0) return [];
  const { data, error } = await supabase
    .from("marker_tags")
    .select("id, key")
    .in("key", normalized);
  if (error) throw error;
  const rows = Array.isArray(data) ? data : [];
  return rows
    .map((r) => String((r as { id?: string }).id ?? "").trim())
    .filter(Boolean)
    .sort();
}

async function syncProfileTags(uid: string, tagKeys: string[]): Promise<void> {
  const supabase = createClient();
  const ids = await resolveTagIds(tagKeys);

  const { data: row, error: readErr } = await supabase
    .from("profiles")
    .select("tag_link_id")
    .eq("id", uid)
    .maybeSingle();
  if (readErr) throw readErr;
  const linkId = (row?.tag_link_id as string | null | undefined)?.trim() || null;

  if (ids.length === 0) {
    if (linkId) {
      await supabase.from("profile_tag_links").delete().eq("id", linkId);
    }
    return;
  }

  if (!linkId) {
    const { data: inserted, error } = await supabase
      .from("profile_tag_links")
      .insert({ tag_ids: ids })
      .select("id")
      .single();
    if (error) throw error;
    const newId = String(inserted?.id ?? "").trim();
    if (!newId) throw new Error("Не удалось сохранить теги");
    const { error: upErr } = await supabase
      .from("profiles")
      .update({ tag_link_id: newId })
      .eq("id", uid);
    if (upErr) throw upErr;
    return;
  }

  const { error } = await supabase
    .from("profile_tag_links")
    .update({ tag_ids: ids })
    .eq("id", linkId);
  if (error) throw error;
}

export async function saveProfileEdit(payload: EditProfilePayload): Promise<void> {
  const supabase = createClient();
  const {
    data: { session },
  } = await supabase.auth.getSession();
  const uid = session?.user.id;
  if (!uid) throw new Error("Нет сессии");

  const update: Record<string, unknown> = {
    full_name: nullableTrim(payload.fullName),
    bio: nullableTrim(payload.bio),
    country_code: nullableTrim(payload.countryCode),
    city_code: nullableTrim(payload.cityCode),
  };

  if (payload.avatarFile) {
    update.avatar_url = await uploadJpeg("avatars", `${uid}/avatar.jpg`, payload.avatarFile);
  }
  if (payload.backgroundFile) {
    update.background_url = await uploadJpeg(
      "profile_backgrounds",
      `${uid}/background.jpg`,
      payload.backgroundFile,
    );
  }

  const { error } = await supabase.from("profiles").update(update).eq("id", uid);
  if (error) throw error;
  await syncProfileTags(uid, payload.tagKeys);
}

export async function saveUsername(username: string): Promise<void> {
  const next = username.trim().replace(/^@/, "");
  if (!next) throw new Error("Укажите никнейм");
  if (!/^[a-zA-Z0-9._]+$/.test(next)) {
    throw new Error("Только латиница, цифры, «_» и «.»");
  }
  const supabase = createClient();
  const {
    data: { session },
  } = await supabase.auth.getSession();
  const uid = session?.user.id;
  if (!uid) throw new Error("Нет сессии");
  const { error } = await supabase.from("profiles").update({ username: next }).eq("id", uid);
  if (error) {
    const msg = error.message || "";
    if (msg.includes("username") || error.code === "23505") {
      throw new Error("Этот никнейм уже занят");
    }
    throw new Error(error.message || "Не удалось сменить никнейм");
  }
}
