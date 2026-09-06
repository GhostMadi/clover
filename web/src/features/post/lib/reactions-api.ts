"use client";

import { createClient } from "@/lib/supabase/client";

export async function setPostReaction(postId: string, kind: "like" | "dislike" | null) {
  const supabase = createClient();
  const { error } = await supabase.rpc("set_post_reaction", {
    p_post_id: postId,
    p_kind: kind,
  });
  if (error) throw error;
}

export async function setPostSaved(postId: string, saved: boolean) {
  const supabase = createClient();
  const { error } = await supabase.rpc(saved ? "save_post" : "unsave_post", {
    p_post_id: postId,
  });
  if (error) throw error;
}
