import { createClient } from "@/lib/supabase/server";
import type { ClusterItem } from "@/features/profile/lib/clusters-api";

export async function listUserClustersServer(ownerId: string): Promise<ClusterItem[]> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .from("clusters")
    .select("id, title, subtitle, cover_url, posts_count")
    .eq("owner_id", ownerId)
    .eq("is_archived", false)
    .order("sort_order", { ascending: true });
  if (error) throw error;
  return (data ?? []).map((r) => {
    const row = r as Record<string, unknown>;
    return {
      id: String(row.id),
      title: String(row.title ?? "").trim() || "Кластер",
      subtitle: (row.subtitle as string | null)?.trim() || null,
      coverUrl: (row.cover_url as string | null)?.trim() || null,
      postsCount: Number(row.posts_count ?? 0) || 0,
    };
  });
}
