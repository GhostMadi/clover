import { createClient } from "@/lib/supabase/server";
import {
  emptyProfile,
  mapProfileRow,
  type Profile,
} from "@/features/profile/lib/profile-model";

export type { Profile } from "@/features/profile/lib/profile-model";
export { formatStat, usernamePolicy } from "@/features/profile/lib/profile-model";

const COLUMNS = `
id,
email,
full_name,
username,
city_code,
country_code,
avatar_url,
background_url,
bio,
followers_count,
following_count,
cluster_count,
post_count,
tag_link_id,
username_change_count,
username_next_change_allowed_at,
has_filters
`.trim();

async function resolveTagKeys(
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  supabase: any,
  tagLinkId: string | null,
): Promise<string[]> {
  if (!tagLinkId) return [];
  const { data: link } = await supabase
    .from("profile_tag_links")
    .select("tag_ids")
    .eq("id", tagLinkId)
    .maybeSingle();
  const ids = Array.isArray(link?.tag_ids) ? (link.tag_ids as string[]) : [];
  if (ids.length === 0) return [];
  const { data: tags } = await supabase.from("marker_tags").select("key").in("id", ids);
  if (!Array.isArray(tags)) return [];
  return tags
    .map((t: { key?: string }) => String(t.key ?? "").trim())
    .filter(Boolean);
}

/** Профиль по id из `public.profiles`. */
export async function getProfileById(userId: string, emailFallback?: string | null): Promise<Profile> {
  const supabase = await createClient();
  const { data, error } = await supabase.from("profiles").select(COLUMNS).eq("id", userId).maybeSingle();
  if (error) throw error;
  if (!data) return emptyProfile(userId, emailFallback);
  const row = data as unknown as Record<string, unknown>;
  const tagKeys = await resolveTagKeys(
    supabase,
    (row.tag_link_id as string | null) ?? null,
  );
  return mapProfileRow(row, emailFallback, tagKeys);
}

/** Профиль текущего пользователя из `public.profiles`. */
export async function getCurrentProfile(): Promise<Profile | null> {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return null;
  return getProfileById(user.id, user.email);
}
