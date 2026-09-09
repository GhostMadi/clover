import { locationLine } from "@/features/profile/lib/location";
import { toWebMediaSrc } from "@/lib/media-url";

export type Profile = {
  id: string;
  email: string | null;
  fullName: string | null;
  username: string | null;
  cityCode: string | null;
  countryCode: string | null;
  avatarUrl: string | null;
  backgroundUrl: string | null;
  bio: string | null;
  followersCount: number;
  followingCount: number;
  postCount: number;
  clusterCount: number;
  location: string;
  tagLinkId: string | null;
  tagKeys: string[];
  usernameChangeCount: number;
  usernameNextChangeAllowedAt: string | null;
  hasFilters: boolean;
};

export function formatStat(n: number): string {
  if (n >= 1_000_000) {
    const v = (n / 1_000_000).toFixed(1);
    return v.endsWith(".0") ? `${v.slice(0, -2)}M` : `${v}M`;
  }
  if (n >= 1000) {
    const v = (n / 1000).toFixed(1);
    return v.endsWith(".0") ? `${v.slice(0, -2)}k` : `${v}k`;
  }
  return String(n);
}

export function mapProfileRow(
  row: Record<string, unknown>,
  emailFallback?: string | null,
  tagKeys: string[] = [],
): Profile {
  const countryCode = (row.country_code as string | null) ?? null;
  const cityCode = (row.city_code as string | null) ?? null;
  const cluster =
    row.cluster_count != null ? Number(row.cluster_count) : Number(row.collection_count ?? 0);
  return {
    id: String(row.id),
    email: (row.email as string | null) ?? emailFallback ?? null,
    fullName: (row.full_name as string | null) ?? null,
    username: (row.username as string | null) ?? null,
    cityCode,
    countryCode,
    avatarUrl: toWebMediaSrc((row.avatar_url as string | null) ?? null) || null,
    backgroundUrl: toWebMediaSrc((row.background_url as string | null) ?? null) || null,
    bio: (row.bio as string | null) ?? null,
    followersCount: Number(row.followers_count ?? 0),
    followingCount: Number(row.following_count ?? 0),
    postCount: Number(row.post_count ?? 0),
    clusterCount: cluster,
    location: locationLine(countryCode, cityCode),
    tagLinkId: (row.tag_link_id as string | null | undefined)?.trim() || null,
    tagKeys,
    usernameChangeCount: Number(row.username_change_count ?? 0),
    usernameNextChangeAllowedAt:
      (row.username_next_change_allowed_at as string | null | undefined) ?? null,
    hasFilters: row.has_filters === true,
  };
}

export function emptyProfile(userId: string, emailFallback?: string | null): Profile {
  return {
    id: userId,
    email: emailFallback ?? null,
    fullName: null,
    username: null,
    cityCode: null,
    countryCode: null,
    avatarUrl: null,
    backgroundUrl: null,
    bio: null,
    followersCount: 0,
    followingCount: 0,
    postCount: 0,
    clusterCount: 0,
    location: "",
    tagLinkId: null,
    tagKeys: [],
    usernameChangeCount: 0,
    usernameNextChangeAllowedAt: null,
    hasFilters: false,
  };
}

/** Лимит смен ника — как EditProfileUsernamePolicy на мобилке. */
export function usernamePolicy(profile: Profile): {
  canChange: boolean;
  hint: string;
  remaining: number;
} {
  const max = 4;
  const cooldownRaw = profile.usernameNextChangeAllowedAt;
  const cooldown = cooldownRaw ? new Date(cooldownRaw) : null;
  const now = Date.now();
  if (cooldown && !Number.isNaN(cooldown.getTime()) && now < cooldown.getTime()) {
    const date = cooldown.toLocaleString("ru-RU", {
      day: "2-digit",
      month: "2-digit",
      year: "numeric",
      hour: "2-digit",
      minute: "2-digit",
    });
    return {
      canChange: false,
      remaining: 0,
      hint: `Смена никнейма будет доступна после ${date}`,
    };
  }
  const count =
    cooldown && !Number.isNaN(cooldown.getTime()) && now >= cooldown.getTime()
      ? 0
      : profile.usernameChangeCount;
  const remaining = Math.max(0, max - count);
  if (remaining <= 0) {
    return { canChange: false, remaining: 0, hint: "Лимит смен никнейма исчерпан" };
  }
  if (remaining < max) {
    return {
      canChange: true,
      remaining,
      hint: `Осталось смен: ${remaining} из ${max}`,
    };
  }
  return {
    canChange: true,
    remaining,
    hint: `Латиница, цифры, «_» и «.». Не более ${max} смен за 7 дней`,
  };
}
