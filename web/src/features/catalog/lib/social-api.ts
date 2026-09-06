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

export type SocialProfileRow = {
  profileId: string;
  username: string | null;
  avatarUrl: string | null;
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
  return parseSocialRows(data);
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
  return parseSocialRows(data);
}
