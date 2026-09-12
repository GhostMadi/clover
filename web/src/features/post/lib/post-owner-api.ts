"use client";

import { createClient } from "@/lib/supabase/client";

/** Архив обычного поста или ивента (marker) — как mobile PostRepository. */
export async function archiveOwnedPost(opts: {
  postId: string;
  markerId?: string | null;
}): Promise<void> {
  const supabase = createClient();
  const mid = opts.markerId?.trim();
  if (mid) {
    const { error } = await supabase.from("markers").update({ is_archived: true }).eq("id", mid);
    if (error) throw error;
    return;
  }
  const { error } = await supabase
    .from("posts")
    .update({ is_archived: true })
    .eq("id", opts.postId.trim());
  if (error) throw error;
}

export async function unarchiveOwnedPost(opts: {
  postId: string;
  markerId?: string | null;
}): Promise<void> {
  const supabase = createClient();
  const mid = opts.markerId?.trim();
  if (mid) {
    const { error } = await supabase.from("markers").update({ is_archived: false }).eq("id", mid);
    if (error) throw error;
    return;
  }
  const { error } = await supabase
    .from("posts")
    .update({ is_archived: false })
    .eq("id", opts.postId.trim());
  if (error) throw error;
}

/** R2 cleanup + DB via Edge `delete_post` (same as mobile). */
export async function deleteOwnedPost(postId: string): Promise<void> {
  const supabase = createClient();
  const {
    data: { session },
  } = await supabase.auth.getSession();
  if (!session?.access_token) throw new Error("Нет сессии");

  const { data, error } = await supabase.functions.invoke("delete_post", {
    body: { post_id: postId.trim() },
  });
  if (error) throw error;
  if (data && typeof data === "object" && "error" in data && data.error) {
    throw new Error(String(data.error));
  }
}
