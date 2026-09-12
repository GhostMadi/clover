"use client";

import { createClient } from "@/lib/supabase/client";
import { unarchiveOwnedPost } from "@/features/post/lib/post-owner-api";

export type ArchivedPostItem = {
  postId: string;
  markerId: string | null;
  coverUrl: string | null;
  title: string | null;
  textEmoji: string | null;
  isEvent: boolean;
  createdAt: string;
};

function mediaCover(media: unknown): string | null {
  if (!Array.isArray(media) || media.length === 0) return null;
  const sorted = [...media].sort((a, b) => {
    const ao = typeof (a as { sort_order?: number }).sort_order === "number"
      ? (a as { sort_order: number }).sort_order
      : 0;
    const bo = typeof (b as { sort_order?: number }).sort_order === "number"
      ? (b as { sort_order: number }).sort_order
      : 0;
    return ao - bo;
  });
  const url = String((sorted[0] as { url?: string })?.url ?? "").trim();
  return url || null;
}

function pickPrimaryPostFromMarkerLinks(links: unknown): Record<string, unknown> | null {
  if (!Array.isArray(links) || links.length === 0) return null;
  const rows = links
    .filter((x): x is Record<string, unknown> => Boolean(x) && typeof x === "object")
    .slice()
    .sort((a, b) => {
      const ap = a.is_primary === true ? 0 : 1;
      const bp = b.is_primary === true ? 0 : 1;
      if (ap !== bp) return ap - bp;
      return Number(a.sort_order ?? 0) - Number(b.sort_order ?? 0);
    });
  for (const link of rows) {
    const post = link.posts;
    if (post && typeof post === "object" && !Array.isArray(post)) {
      return post as Record<string, unknown>;
    }
  }
  return null;
}

/** Архив публикаций + ивентов (как mobile PostArchiveCubit). */
export async function listArchivedPosts(): Promise<ArchivedPostItem[]> {
  const supabase = createClient();
  const {
    data: { session },
  } = await supabase.auth.getSession();
  const uid = session?.user.id;
  if (!uid) throw new Error("Нет сессии");

  const byId = new Map<string, ArchivedPostItem>();

  const { data: posts, error: postsError } = await supabase
    .from("posts")
    .select("id, title, text_emoji, marker_id, created_at, post_media(url, sort_order)")
    .eq("user_id", uid)
    .eq("is_archived", true)
    .is("deleted_at", null)
    .order("created_at", { ascending: false });
  if (postsError) throw postsError;

  for (const row of posts ?? []) {
    const r = row as Record<string, unknown>;
    const id = String(r.id);
    byId.set(id, {
      postId: id,
      markerId: (r.marker_id as string | null)?.trim() || null,
      coverUrl: mediaCover(r.post_media),
      title: (r.title as string | null)?.trim() || null,
      textEmoji: (r.text_emoji as string | null)?.trim() || null,
      isEvent: Boolean(r.marker_id),
      createdAt: String(r.created_at ?? ""),
    });
  }

  const { data: markers, error: markersError } = await supabase
    .from("markers")
    .select(
      `
      id,
      text_emoji,
      created_at,
      marker_posts(
        is_primary,
        sort_order,
        posts(id, title, text_emoji, created_at, deleted_at, post_media(url, sort_order))
      )
    `,
    )
    .eq("owner_id", uid)
    .eq("is_archived", true)
    .order("created_at", { ascending: false });
  if (markersError) throw markersError;

  for (const m of markers ?? []) {
    const marker = m as Record<string, unknown>;
    const markerId = String(marker.id);
    const post = pickPrimaryPostFromMarkerLinks(marker.marker_posts);
    if (!post) continue;
    if (post.deleted_at) continue;
    const postId = String(post.id);
    if (byId.has(postId)) {
      const prev = byId.get(postId)!;
      byId.set(postId, { ...prev, markerId, isEvent: true });
      continue;
    }
    byId.set(postId, {
      postId,
      markerId,
      coverUrl: mediaCover(post.post_media),
      title: (post.title as string | null)?.trim() || null,
      textEmoji:
        (post.text_emoji as string | null)?.trim() ||
        (marker.text_emoji as string | null)?.trim() ||
        null,
      isEvent: true,
      createdAt: String(post.created_at ?? marker.created_at ?? ""),
    });
  }

  return [...byId.values()].sort((a, b) => b.createdAt.localeCompare(a.createdAt));
}

export async function restoreArchivedPost(item: ArchivedPostItem): Promise<void> {
  await unarchiveOwnedPost({ postId: item.postId, markerId: item.markerId });
}
