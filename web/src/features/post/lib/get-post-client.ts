"use client";

import {
  mapFeedRpcRows,
  type FeedPost,
} from "@/features/post/lib/parse-feed";
import { createClient } from "@/lib/supabase/client";

/** Клиентский `get_post_enriched` для модалок карты / деталей. */
export async function getPostEnrichedClient(postId: string): Promise<FeedPost | null> {
  const id = postId.trim();
  if (!id) return null;
  const list = await getPostsEnrichedClient([id]);
  return list[0] ?? null;
}

/** Батч `get_posts_enriched` — стопка маркеров на одной точке. */
export async function getPostsEnrichedClient(
  postIds: string[],
): Promise<FeedPost[]> {
  const ids = [...new Set(postIds.map((x) => x.trim()).filter(Boolean))];
  if (ids.length === 0) return [];

  const supabase = createClient();
  const { data, error } = await supabase.rpc("get_posts_enriched", {
    p_post_ids: ids,
  });
  if (error) throw error;
  const rows = Array.isArray(data) ? data : data ? [data] : [];
  const items = mapFeedRpcRows(rows);
  // Preserve request order.
  const byId = new Map(items.map((p) => [p.id, p]));
  return ids.map((id) => byId.get(id)).filter((p): p is FeedPost => Boolean(p));
}
