"use client";

import {
  mapFeedRpcRows,
  mapPostRow,
  type FeedPost,
} from "@/features/post/lib/parse-feed";
import { createClient } from "@/lib/supabase/client";

/** Клиентский `get_post_enriched` для модалок карты / деталей. */
export async function getPostEnrichedClient(postId: string): Promise<FeedPost | null> {
  const id = postId.trim();
  if (!id) return null;

  const supabase = createClient();

  try {
    const { data, error } = await supabase.rpc("get_post_enriched", {
      p_post_id: id,
    });
    if (error) throw error;
    const rows = Array.isArray(data) ? data : data ? [data] : [];
    const items = mapFeedRpcRows(rows);
    if (items[0]) return items[0];
  } catch {
    // fallback
  }

  const { data, error } = await supabase
    .from("posts")
    .select("*, post_media(*)")
    .eq("id", id)
    .is("deleted_at", null)
    .maybeSingle();
  if (error || !data) return null;

  const row = data as unknown as Record<string, unknown>;
  const authorId = String(row.user_id ?? "").trim();
  let author: Record<string, unknown> | null = null;
  if (authorId) {
    const { data: profile } = await supabase
      .from("profiles")
      .select("id, username, avatar_url")
      .eq("id", authorId)
      .maybeSingle();
    if (profile) author = profile as unknown as Record<string, unknown>;
  }

  return mapPostRow(row, author, {
    myReaction: null,
    mySaved: false,
    myFollowingAuthor: false,
  });
}
