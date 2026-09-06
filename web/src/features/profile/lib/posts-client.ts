"use client";

import { createClient } from "@/lib/supabase/client";
import { mapFeedRpcRows, mapPostRow, type FeedPost } from "@/features/post/lib/parse-feed";

/** Клиентский список постов профиля с фильтром по кластеру / витрине. */
export async function listProfilePostsClient(
  userId: string,
  opts?: {
    clusterId?: string | null;
    filterSelectionKeys?: string[];
    limit?: number;
  },
): Promise<FeedPost[]> {
  const uid = userId.trim();
  if (!uid) return [];
  const limit = opts?.limit ?? 48;
  const clusterId = opts?.clusterId?.trim() || null;
  const filterKeys = (opts?.filterSelectionKeys ?? [])
    .map((k) => k.trim())
    .filter(Boolean);
  const supabase = createClient();

  try {
    const { data, error } = await supabase.rpc("list_user_feed_enriched_cursor", {
      p_args: {
        p_user_id: uid,
        p_limit: limit,
        p_cursor_created_at: null,
        p_cursor_id: null,
        p_cluster_id: clusterId,
        p_only_without_cluster: false,
        p_exclude_with_marker: false,
        p_only_with_marker: false,
        p_filter_selection_keys: filterKeys.length ? filterKeys : null,
      },
    });
    if (error) throw error;
    return mapFeedRpcRows(data);
  } catch {
    let q = supabase
      .from("posts")
      .select("*, post_media(*)")
      .eq("user_id", uid)
      .eq("is_archived", false)
      .is("deleted_at", null)
      .order("created_at", { ascending: false })
      .limit(limit);
    if (clusterId) q = q.eq("cluster_id", clusterId);
    const { data, error } = await q;
    if (error) throw error;
    const items: FeedPost[] = [];
    for (const row of data ?? []) {
      const post = mapPostRow(row as Record<string, unknown>);
      if (post) items.push(post);
    }
    return items;
  }
}
