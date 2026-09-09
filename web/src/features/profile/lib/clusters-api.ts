"use client";

import { createClient } from "@/lib/supabase/client";
import { exportCroppedJpeg } from "@/features/post-create/lib/image-crop";
import type { ImageEditSettings } from "@/features/post-create/lib/image-edit-matrix";
import { toWebMediaSrc } from "@/lib/media-url";
import { deleteFromR2, uploadToR2 } from "@/lib/r2-storage";

export const CLUSTER_TITLE_MAX = 120;
export const CLUSTER_SUBTITLE_MAX = 500;
export const CLUSTER_COVER_MAX_PHOTOS = 1;

export type ClusterCoverDraft = {
  file: File;
  zoom: number;
  offsetX: number;
  offsetY: number;
  edit: ImageEditSettings;
};

export type ClusterItem = {
  id: string;
  title: string;
  subtitle: string | null;
  coverUrl: string | null;
  postsCount: number;
};

function mapCluster(row: Record<string, unknown>): ClusterItem {
  return {
    id: String(row.id),
    title: String(row.title ?? "").trim() || "Кластер",
    subtitle: (row.subtitle as string | null)?.trim() || null,
    coverUrl: toWebMediaSrc((row.cover_url as string | null)?.trim() || null) || null,
    postsCount: Number(row.posts_count ?? 0) || 0,
  };
}

export async function listUserClusters(ownerId: string): Promise<ClusterItem[]> {
  const supabase = createClient();
  const { data, error } = await supabase
    .from("clusters")
    .select("id, title, subtitle, cover_url, posts_count")
    .eq("owner_id", ownerId)
    .eq("is_archived", false)
    .order("sort_order", { ascending: true });
  if (error) throw error;
  return (data ?? []).map((r) => mapCluster(r as Record<string, unknown>));
}

export async function listArchivedClusters(): Promise<ClusterItem[]> {
  const supabase = createClient();
  const {
    data: { session },
  } = await supabase.auth.getSession();
  const uid = session?.user.id;
  if (!uid) throw new Error("Нет сессии");

  const { data, error } = await supabase
    .from("clusters")
    .select("id, title, subtitle, cover_url, posts_count")
    .eq("owner_id", uid)
    .eq("is_archived", true)
    .order("updated_at", { ascending: false });
  if (error) throw error;
  return (data ?? []).map((r) => mapCluster(r as Record<string, unknown>));
}

async function nextSortOrder(uid: string): Promise<number> {
  const supabase = createClient();
  const { data } = await supabase
    .from("clusters")
    .select("sort_order")
    .eq("owner_id", uid)
    .order("sort_order", { ascending: false })
    .limit(1)
    .maybeSingle();
  const max = data ? Number((data as { sort_order?: number }).sort_order ?? -1) : -1;
  return max + 1;
}

async function uploadCover(
  _uid: string,
  clusterId: string,
  cover: ClusterCoverDraft,
): Promise<string> {
  const jpeg = await exportCroppedJpeg({
    file: cover.file,
    aspect: "1x1",
    zoom: cover.zoom,
    offsetX: cover.offsetX,
    offsetY: cover.offsetY,
    edit: cover.edit,
  });
  const uploaded = await uploadToR2({
    file: jpeg,
    fileName: "cover.jpg",
    folder: `cluster_covers/${clusterId}`,
    contentType: "image/jpeg",
  });
  return uploaded.publicUrl;
}

export async function createCluster(opts: {
  title: string;
  subtitle?: string | null;
  cover: ClusterCoverDraft;
}): Promise<ClusterItem> {
  const supabase = createClient();
  const {
    data: { session },
  } = await supabase.auth.getSession();
  const uid = session?.user.id;
  if (!uid) throw new Error("Нет сессии");

  const title = opts.title.trim();
  if (!title) throw new Error("Введите название");
  if (title.length > CLUSTER_TITLE_MAX) throw new Error(`Макс ${CLUSTER_TITLE_MAX} символов`);
  const subtitle = opts.subtitle?.trim() || null;
  if (subtitle && subtitle.length > CLUSTER_SUBTITLE_MAX) {
    throw new Error(`Описание: макс ${CLUSTER_SUBTITLE_MAX}`);
  }

  const sortOrder = await nextSortOrder(uid);
  const insert: Record<string, unknown> = {
    owner_id: uid,
    title,
    sort_order: sortOrder,
  };
  if (subtitle) insert.subtitle = subtitle;

  const { data, error } = await supabase
    .from("clusters")
    .insert(insert)
    .select("id, title, subtitle, cover_url, posts_count")
    .single();
  if (error) throw error;
  const row = data as Record<string, unknown>;
  const id = String(row.id);

  try {
    const coverUrl = await uploadCover(uid, id, opts.cover);
    const { data: updated, error: uErr } = await supabase
      .from("clusters")
      .update({ cover_url: coverUrl })
      .eq("id", id)
      .select("id, title, subtitle, cover_url, posts_count")
      .single();
    if (uErr) throw uErr;
    return mapCluster(updated as Record<string, unknown>);
  } catch (e) {
    try {
      await supabase.from("clusters").delete().eq("id", id);
    } catch {
      /* ignore */
    }
    throw e;
  }
}

export async function archiveCluster(clusterId: string): Promise<void> {
  const supabase = createClient();
  const { error } = await supabase
    .from("clusters")
    .update({ is_archived: true })
    .eq("id", clusterId);
  if (error) throw error;
}

export async function unarchiveCluster(clusterId: string): Promise<void> {
  const supabase = createClient();
  const { error } = await supabase
    .from("clusters")
    .update({ is_archived: false })
    .eq("id", clusterId);
  if (error) throw error;
}

export async function deleteCluster(clusterId: string): Promise<void> {
  const supabase = createClient();
  const {
    data: { session },
  } = await supabase.auth.getSession();
  if (!session?.user.id) throw new Error("Нет сессии");

  const { data: row } = await supabase
    .from("clusters")
    .select("cover_url")
    .eq("id", clusterId)
    .maybeSingle();
  const coverUrl = String((row as { cover_url?: string } | null)?.cover_url ?? "").trim();
  if (coverUrl) {
    await deleteFromR2({ urls: [coverUrl] });
  }
  const { error } = await supabase.from("clusters").delete().eq("id", clusterId);
  if (error) throw error;
}

export async function setPostCluster(
  postId: string,
  clusterId: string | null,
): Promise<void> {
  const supabase = createClient();
  const { error } = await supabase
    .from("posts")
    .update({ cluster_id: clusterId })
    .eq("id", postId);
  if (error) throw error;
}

export async function getPostClusterId(postId: string): Promise<string | null> {
  const supabase = createClient();
  const { data, error } = await supabase
    .from("posts")
    .select("cluster_id")
    .eq("id", postId)
    .maybeSingle();
  if (error) throw error;
  const id = (data as { cluster_id?: string | null } | null)?.cluster_id;
  return id?.trim() || null;
}
