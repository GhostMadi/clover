"use client";

import { createClient } from "@/lib/supabase/client";

export type ProfileFilterCategory = {
  id: string;
  name: string;
  values: string[];
};

/** Ключ выбора на посте / в чипах: `categoryId:label`. */
export function filterSelectionKey(categoryId: string, label: string): string {
  return `${categoryId.trim()}:${label.trim()}`;
}

export function parseFilterSelectionKey(key: string): { categoryId: string; label: string } | null {
  const i = key.indexOf(":");
  if (i <= 0) return null;
  const categoryId = key.slice(0, i).trim();
  const label = key.slice(i + 1).trim();
  if (!categoryId || !label) return null;
  return { categoryId, label };
}

function mapCategory(raw: unknown): ProfileFilterCategory | null {
  if (!raw || typeof raw !== "object") return null;
  const row = raw as Record<string, unknown>;
  const id = String(row.id ?? "").trim();
  const name = String(row.name ?? "").trim();
  if (!id || !name) return null;
  const valuesRaw = row.values;
  const values: string[] = [];
  if (Array.isArray(valuesRaw)) {
    for (const v of valuesRaw) {
      const s = String(v ?? "").trim();
      if (s) values.push(s);
    }
  }
  return { id, name, values };
}

export async function listProfileFilterCategories(
  profileId: string,
): Promise<ProfileFilterCategory[]> {
  const supabase = createClient();
  const { data, error } = await supabase.rpc("list_profile_filter_categories", {
    p_profile_id: profileId,
  });
  if (error) throw error;
  const list = Array.isArray(data) ? data : [];
  const out: ProfileFilterCategory[] = [];
  for (const raw of list) {
    const c = mapCategory(raw);
    if (c) out.push(c);
  }
  return out;
}

export async function upsertProfileFilterCategory(opts: {
  name: string;
  values: string[];
  categoryId?: string | null;
}): Promise<ProfileFilterCategory> {
  const name = opts.name.trim();
  if (!name) throw new Error("Укажите название категории");
  const values = opts.values.map((v) => v.trim()).filter(Boolean);
  if (!values.length) throw new Error("Добавьте хотя бы одно значение");

  const supabase = createClient();
  const params: Record<string, unknown> = {
    p_name: name,
    p_values: values,
  };
  if (opts.categoryId?.trim()) params.p_category_id = opts.categoryId.trim();

  const { data, error } = await supabase.rpc("upsert_profile_filter_category", params);
  if (error) {
    const msg = error.message || "";
    if (msg.includes("category_name_taken")) throw new Error("Категория с таким названием уже есть");
    throw new Error(msg || "Не удалось сохранить");
  }
  const mapped = mapCategory(data);
  if (!mapped) throw new Error("Некорректный ответ сервера");
  return mapped;
}

export async function deleteProfileFilterCategory(categoryId: string): Promise<void> {
  const supabase = createClient();
  const { error } = await supabase.rpc("delete_profile_filter_category", {
    p_category_id: categoryId,
  });
  if (error) throw error;
}

export async function setPostProfileFilters(
  postId: string,
  selectionKeys: string[],
): Promise<void> {
  const keys = selectionKeys.map((k) => k.trim()).filter(Boolean);
  if (!keys.length) return;
  const supabase = createClient();
  const { error } = await supabase.rpc("set_post_profile_filters", {
    p_post_id: postId,
    p_selection_keys: keys,
  });
  if (error) throw error;
}
