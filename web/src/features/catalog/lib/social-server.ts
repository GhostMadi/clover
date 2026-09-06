import { createClient } from "@/lib/supabase/server";

/** Серверный check подписки — для guest profile page. */
export async function getIsFollowingUser(targetUserId: string): Promise<boolean> {
  const id = targetUserId.trim();
  if (!id) return false;
  const supabase = await createClient();
  const { data, error } = await supabase.rpc("is_following_user", { p_target: id });
  if (error) return false;
  return data === true;
}
