import { cityLabel } from "@/features/catalog/lib/locations";
import { COUNTRY_OPTIONS } from "@/features/catalog/lib/locations";
import { tagLabelRu } from "@/features/catalog/lib/marker-tags";
import { toWebMediaSrc } from "@/lib/media-url";

export type FeedTag = { id: string; key: string; label: string };

export type FeedMarker = {
  id: string;
  textEmoji: string;
  addressPrimary: string | null;
  addressCyrillic: string | null;
  countryCode: string | null;
  cityCode: string | null;
  eventTime: string | null;
  endTime: string | null;
  tags: FeedTag[];
};

export type FeedBookingService = {
  id: string;
  title: string;
  emojiText: string;
  price: number;
  durationMinutes: number;
  isActive: boolean;
};

export type FeedProfileFilter = {
  categoryId: string;
  categoryName: string;
  label: string;
};

export type FeedPostMedia = {
  id: string;
  url: string;
  sortOrder: number;
};

export type FeedPost = {
  id: string;
  userId: string;
  markerId: string | null;
  bookingServiceId: string | null;
  title: string | null;
  description: string | null;
  textEmoji: string | null;
  createdAt: string;
  media: FeedPostMedia[];
  coverUrl: string | null;
  isEvent: boolean;
  authorUsername: string | null;
  authorAvatarUrl: string | null;
  likesCount: number;
  dislikesCount: number;
  commentsCount: number;
  sendsCount: number;
  myReaction: "like" | "dislike" | null;
  mySaved: boolean;
  /** Подписан ли текущий пользователь на автора (`my_following_author`). */
  myFollowingAuthor: boolean;
  marker: FeedMarker | null;
  bookingService: FeedBookingService | null;
  profileFilters: FeedProfileFilter[];
  tags: FeedTag[];
  addressPrimary: string | null;
  addressCyrillic: string | null;
  countryCode: string | null;
  cityCode: string | null;
};

type RpcRow = {
  post?: Record<string, unknown> | null;
  author?: Record<string, unknown> | null;
  my_reaction?: string | null;
  my_saved?: boolean | string | null;
  my_following_author?: boolean | string | null;
};

export function parseMedia(raw: unknown): FeedPostMedia[] {
  if (!Array.isArray(raw)) return [];
  const out: FeedPostMedia[] = [];
  for (const item of raw) {
    if (!item || typeof item !== "object") continue;
    const m = item as Record<string, unknown>;
    const type = typeof m.type === "string" ? m.type.toLowerCase() : "image";
    if (type === "video") continue;
    if (type !== "image" && m.type != null) continue;
    const url = toWebMediaSrc(String(m.url ?? "").trim());
    if (!url) continue;
    out.push({
      id: String(m.id ?? `${url}-${out.length}`),
      url,
      sortOrder: Number(m.sort_order ?? 0),
    });
  }
  return out.sort((a, b) => a.sortOrder - b.sortOrder);
}

function parseReaction(raw: unknown): "like" | "dislike" | null {
  if (typeof raw !== "string") return null;
  const t = raw.trim();
  if (t === "like" || t === "dislike") return t;
  return null;
}

function parseSaved(raw: unknown): boolean {
  if (typeof raw === "boolean") return raw;
  if (typeof raw === "string") return raw === "true" || raw === "t";
  return false;
}

function parseFollowing(raw: unknown): boolean {
  if (typeof raw === "boolean") return raw;
  if (typeof raw === "string") return raw === "true" || raw === "t";
  return false;
}

function parseTags(raw: unknown): FeedTag[] {
  if (!Array.isArray(raw)) return [];
  const out: FeedTag[] = [];
  for (const item of raw) {
    if (!item || typeof item !== "object") continue;
    const t = item as Record<string, unknown>;
    const key = String(t.key ?? "").trim();
    if (!key) continue;
    out.push({
      id: String(t.id ?? key),
      key,
      label: tagLabelRu(key),
    });
  }
  return out;
}

function parseMarker(raw: unknown): FeedMarker | null {
  if (!raw || typeof raw !== "object") return null;
  const m = raw as Record<string, unknown>;
  const id = String(m.id ?? "").trim();
  if (!id) return null;
  return {
    id,
    textEmoji: String(m.text_emoji ?? "").trim(),
    addressPrimary: (m.address_primary as string | null)?.trim() || null,
    addressCyrillic: (m.address_cyrillic as string | null)?.trim() || null,
    countryCode: (m.country_code as string | null)?.trim()?.toLowerCase() || null,
    cityCode: (m.city_code as string | null)?.trim() || null,
    eventTime: m.event_time ? String(m.event_time) : null,
    endTime: m.end_time ? String(m.end_time) : null,
    tags: parseTags(m.tags),
  };
}

function parseProfileFilters(raw: unknown): FeedProfileFilter[] {
  if (!Array.isArray(raw)) return [];
  const out: FeedProfileFilter[] = [];
  for (const item of raw) {
    if (!item || typeof item !== "object") continue;
    const f = item as Record<string, unknown>;
    const label = String(f.label ?? "").trim();
    if (!label) continue;
    out.push({
      categoryId: String(f.category_id ?? ""),
      categoryName: String(f.category_name ?? ""),
      label,
    });
  }
  return out;
}

export function parseBookingService(raw: unknown): FeedBookingService | null {
  if (!raw || typeof raw !== "object") return null;
  const s = raw as Record<string, unknown>;
  const id = String(s.id ?? "").trim();
  if (!id) return null;
  const priceRaw = s.price;
  const price =
    typeof priceRaw === "number"
      ? priceRaw
      : typeof priceRaw === "string"
        ? Number(priceRaw) || 0
        : 0;
  return {
    id,
    title: String(s.title ?? ""),
    emojiText: String(s.emoji_text ?? "💈"),
    price,
    durationMinutes: Number(s.duration_minutes ?? 30),
    isActive: s.is_active !== false,
  };
}

export function regionLine(countryCode?: string | null, cityCode?: string | null): string | null {
  const city = cityLabel(countryCode, cityCode);
  const country = COUNTRY_OPTIONS.find((c) => c.code === countryCode?.trim().toLowerCase())?.label;
  if (city && country) return `${city} · ${country}`;
  return city ?? country ?? null;
}

export function mapPostRow(
  row: Record<string, unknown>,
  author?: Record<string, unknown> | null,
  extras?: { myReaction?: unknown; mySaved?: unknown; myFollowingAuthor?: unknown },
): FeedPost | null {
  const id = String(row.id ?? "").trim();
  const userId = String(row.user_id ?? "").trim();
  if (!id || !userId) return null;
  if (row.deleted_at) return null;
  if (row.is_archived === true) return null;

  const media = parseMedia(row.post_media);
  const markerId = (row.marker_id as string | null | undefined)?.trim() || null;
  const bookingServiceId = (row.booking_service_id as string | null | undefined)?.trim() || null;
  const marker = parseMarker(row.marker);
  const emojiFromMarker = marker?.textEmoji || null;

  let authorUsername: string | null = null;
  let authorAvatarUrl: string | null = null;
  if (author && typeof author === "object") {
    const u = (author.username as string | null | undefined)?.trim();
    const a = (author.avatar_url as string | null | undefined)?.trim();
    authorUsername = u || null;
    authorAvatarUrl = a ? toWebMediaSrc(a) : null;
  }

  const bookingFromJson = parseBookingService(row.booking_service);

  return {
    id,
    userId,
    markerId,
    bookingServiceId,
    title: (row.title as string | null | undefined)?.trim() || null,
    description: (row.description as string | null | undefined)?.trim() || null,
    textEmoji: (row.text_emoji as string | null | undefined)?.trim() || emojiFromMarker,
    createdAt: String(row.created_at ?? ""),
    media,
    coverUrl: media[0]?.url ?? null,
    isEvent: Boolean(markerId),
    authorUsername,
    authorAvatarUrl,
    likesCount: Number(row.likes_count ?? 0),
    dislikesCount: Number(row.dislikes_count ?? 0),
    commentsCount: Number(row.comments_count ?? 0),
    sendsCount: Number(row.sends_count ?? 0),
    myReaction: parseReaction(extras?.myReaction),
    mySaved: parseSaved(extras?.mySaved),
    myFollowingAuthor: parseFollowing(extras?.myFollowingAuthor),
    marker,
    bookingService: bookingFromJson,
    profileFilters: parseProfileFilters(row.profile_filters),
    tags: parseTags(row.tags),
    addressPrimary: (row.address_primary as string | null)?.trim() || null,
    addressCyrillic: (row.address_cyrillic as string | null)?.trim() || null,
    countryCode: (row.country_code as string | null)?.trim()?.toLowerCase() || null,
    cityCode: (row.city_code as string | null)?.trim() || null,
  };
}

export function mapFeedRpcRows(res: unknown): FeedPost[] {
  if (!Array.isArray(res)) return [];
  const items: FeedPost[] = [];
  for (const row of res) {
    if (!row || typeof row !== "object") continue;
    const r = row as RpcRow;
    const postRaw = r.post;
    if (!postRaw || typeof postRaw !== "object") continue;
    const post = mapPostRow(postRaw as Record<string, unknown>, r.author, {
      myReaction: r.my_reaction,
      mySaved: r.my_saved,
      myFollowingAuthor: r.my_following_author,
    });
    if (post) items.push(post);
  }
  return items;
}
