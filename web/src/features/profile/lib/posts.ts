import { mapFeedRpcRows, mapPostRow } from "@/features/post/lib/parse-feed";
import type { FeedPost } from "@/features/post/lib/parse-feed";
import { createClient } from "@/lib/supabase/server";

export type ProfilePost = FeedPost;

/** Лента постов профиля — `list_user_feed_enriched_cursor` (+ fallback). */
export async function listProfilePosts(userId: string, limit = 48): Promise<ProfilePost[]> {
  const uid = userId.trim();
  if (!uid) return [];

  const supabase = await createClient();

  try {
    const { data, error } = await supabase.rpc("list_user_feed_enriched_cursor", {
      p_args: {
        p_user_id: uid,
        p_limit: limit,
        p_cursor_created_at: null,
        p_cursor_id: null,
        p_cluster_id: null,
        p_only_without_cluster: false,
        p_exclude_with_marker: false,
        p_only_with_marker: false,
      },
    });
    if (error) throw error;
    return mapFeedRpcRows(data);
  } catch {
    return listFallback(uid, limit);
  }
}

async function listFallback(userId: string, limit: number): Promise<ProfilePost[]> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .from("posts")
    .select("*, post_media(*)")
    .eq("user_id", userId)
    .eq("is_archived", false)
    .is("deleted_at", null)
    .order("created_at", { ascending: false })
    .limit(limit);

  if (error) throw error;
  const items: ProfilePost[] = [];
  for (const row of data ?? []) {
    const post = mapPostRow(row as Record<string, unknown>);
    if (post) items.push(post);
  }
  return items;
}
