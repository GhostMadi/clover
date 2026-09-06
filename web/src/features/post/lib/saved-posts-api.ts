"use client";

import { createClient } from "@/lib/supabase/client";
import { mapPostRow, type FeedPost } from "@/features/post/lib/parse-feed";

export async function listMySavedPosts(limit = 24, offset = 0): Promise<FeedPost[]> {
  const supabase = createClient();
  const { data, error } = await supabase.rpc("list_my_saved_posts", {
    p_limit: Math.min(100, Math.max(1, limit)),
    p_offset: Math.max(0, offset),
  });
  if (error) throw error;
  if (!Array.isArray(data)) return [];
  return data
    .map((row) => {
      const r = row as Record<string, unknown>;
      const post = r.post;
      if (!post || typeof post !== "object") return null;
      const p = post as Record<string, unknown>;
      const author =
        p.profiles && typeof p.profiles === "object"
          ? (p.profiles as Record<string, unknown>)
          : p.author && typeof p.author === "object"
            ? (p.author as Record<string, unknown>)
            : null;
      return mapPostRow(p, author, {
        myReaction: p.my_reaction,
        mySaved: true,
        myFollowingAuthor: p.my_following_author,
      });
    })
    .filter((p): p is FeedPost => Boolean(p));
}
