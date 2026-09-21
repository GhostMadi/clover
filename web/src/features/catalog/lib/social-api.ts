"use client";

import { createClient } from "@/lib/supabase/client";

export async function followUser(targetUserId: string) {
  const id = targetUserId.trim();
  if (!id) throw new Error("targetUserId");
  const supabase = createClient();
  const { error } = await supabase.rpc("follow_user", { p_target: id });
  if (error) throw error;
}

export async function unfollowUser(targetUserId: string) {
  const id = targetUserId.trim();
  if (!id) throw new Error("targetUserId");
  const supabase = createClient();
  const { error } = await supabase.rpc("unfollow_user", { p_target: id });
  if (error) throw error;
}

export async function isFollowingUser(targetUserId: string): Promise<boolean> {
  const id = targetUserId.trim();
  if (!id) return false;
  const supabase = createClient();
  const { data, error } = await supabase.rpc("is_following_user", { p_target: id });
  if (error) throw error;
  return data === true;
}

/** Batch follow flags. Missing ids → false. */
export async function isFollowingUsers(
  targetUserIds: string[],
): Promise<Record<string, boolean>> {
  const ids = [...new Set(targetUserIds.map((x) => x.trim()).filter(Boolean))];
  const out: Record<string, boolean> = {};
  for (const id of ids) out[id] = false;
  if (ids.length === 0) return out;

  const supabase = createClient();
  const { data, error } = await supabase.rpc("is_following_users", {
    p_targets: ids,
  });
  if (error) throw error;
  if (!Array.isArray(data)) return out;
  for (const row of data) {
    if (!row || typeof row !== "object") continue;
    const r = row as Record<string, unknown>;
    const id = String(r.profile_id ?? "").trim();
    if (!id) continue;
    out[id] = r.is_following === true;
  }
  return out;
}

export async function blockUser(targetUserId: string) {
  const id = targetUserId.trim();
  if (!id) throw new Error("targetUserId");
  const supabase = createClient();
  const { error } = await supabase.rpc("block_user", { p_target: id });
  if (error) throw error;
}

export async function unblockUser(targetUserId: string) {
  const id = targetUserId.trim();
  if (!id) throw new Error("targetUserId");
  const supabase = createClient();
  const { error } = await supabase.rpc("unblock_user", { p_target: id });
  if (error) throw error;
}

export type SocialProfileRow = {
  profileId: string;
  username: string | null;
  avatarUrl: string | null;
  isFollowing?: boolean;
};

function parseSocialRows(data: unknown): SocialProfileRow[] {
  if (!Array.isArray(data)) return [];
  return data
    .map((row) => {
      if (!row || typeof row !== "object") return null;
      const r = row as Record<string, unknown>;
      const profileId = String(r.profile_id ?? "").trim();
      if (!profileId) return null;
      return {
        profileId,
        username: (r.username as string | null)?.trim() || null,
        avatarUrl: (r.avatar_url as string | null)?.trim() || null,
      };
    })
    .filter((r): r is SocialProfileRow => Boolean(r));
}

async function enrichFollowing(rows: SocialProfileRow[]): Promise<SocialProfileRow[]> {
  if (rows.length === 0) return rows;
  try {
    const flags = await isFollowingUsers(rows.map((r) => r.profileId));
    return rows.map((r) => ({ ...r, isFollowing: flags[r.profileId] === true }));
  } catch {
    return rows;
  }
}

export async function listProfileFollowers(
  profileId: string,
  limit = 50,
  offset = 0,
): Promise<SocialProfileRow[]> {
  const supabase = createClient();
  const { data, error } = await supabase.rpc("list_profile_followers", {
    p_profile_id: profileId,
    p_limit: limit,
    p_offset: offset,
  });
  if (error) throw error;
  return enrichFollowing(parseSocialRows(data));
}

export async function listProfileFollowing(
  profileId: string,
  limit = 50,
  offset = 0,
): Promise<SocialProfileRow[]> {
  const supabase = createClient();
  const { data, error } = await supabase.rpc("list_profile_following", {
    p_profile_id: profileId,
    p_limit: limit,
    p_offset: offset,
  });
  if (error) throw error;
  return enrichFollowing(parseSocialRows(data));
}

export async function listMyBlockedUsers(
  limit = 50,
  offset = 0,
): Promise<SocialProfileRow[]> {
  const supabase = createClient();
  const { data, error } = await supabase.rpc("list_my_blocked_users", {
    p_limit: limit,
    p_offset: offset,
  });
  if (error) throw error;
  return parseSocialRows(data);
}
