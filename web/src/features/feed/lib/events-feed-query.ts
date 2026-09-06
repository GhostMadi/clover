import {
  mapFeedRpcRows,
  parseBookingService,
  type FeedPost,
} from "@/features/post/lib/parse-feed";
import type { EventsFeedFilter } from "@/features/feed/lib/events-feed-filter";
import type { SupabaseClient } from "@supabase/supabase-js";

export type EventsFeedPage = {
  posts: FeedPost[];
  hasMore: boolean;
};

export type EventsFeedCursor = {
  createdAt: string;
  eventTime: string | null;
  id: string;
};

export const EVENTS_FEED_PAGE_SIZE = 24;

export function buildEventsFeedArgs(
  filter: EventsFeedFilter,
  limit: number,
  cursor?: EventsFeedCursor | null,
): Record<string, unknown> {
  const p_args: Record<string, unknown> = {
    p_limit: limit,
    p_content_kind: filter.contentKind,
    p_country_code: filter.countryCode,
    p_city_code: filter.cityCode,
    p_at_time: new Date().toISOString(),
  };

  if (filter.contentKind === "events_only") {
    if (filter.emoji) p_args.p_emoji = filter.emoji;
    if (filter.dateFrom) p_args.p_date_from = filter.dateFrom;
    if (filter.dateTo) p_args.p_date_to = filter.dateTo;
    if (filter.tagKeys.length > 0) p_args.p_tag_keys = filter.tagKeys;
  }

  if (cursor) {
    if (filter.contentKind === "all") {
      p_args.p_cursor_created_at = cursor.createdAt;
    } else {
      p_args.p_cursor_event_time = cursor.eventTime ?? cursor.createdAt;
    }
    p_args.p_cursor_id = cursor.id;
  }

  return p_args;
}

export function cursorFromPost(post: FeedPost): EventsFeedCursor {
  return {
    createdAt: post.createdAt,
    eventTime: post.marker?.eventTime ?? null,
    id: post.id,
  };
}

export async function attachBookingServicesWithClient(
  supabase: SupabaseClient,
  posts: FeedPost[],
): Promise<FeedPost[]> {
  const needIds = [
    ...new Set(
      posts
        .filter((p) => p.bookingServiceId && !p.bookingService)
        .map((p) => p.bookingServiceId as string),
    ),
  ];
  if (needIds.length === 0) return posts;

  const { data, error } = await supabase
    .from("booking_services")
    .select("id, title, emoji_text, price, duration_minutes, is_active")
    .in("id", needIds);
  if (error || !data) return posts;

  const byId = new Map(
    data.map((row) => [String(row.id), parseBookingService(row)] as const),
  );

  return posts.map((p) => {
    if (p.bookingService || !p.bookingServiceId) return p;
    const service = byId.get(p.bookingServiceId) ?? null;
    return service ? { ...p, bookingService: service } : p;
  });
}

export async function fetchEventsFeedPage(
  supabase: SupabaseClient,
  filter: EventsFeedFilter,
  opts?: { limit?: number; cursor?: EventsFeedCursor | null },
): Promise<EventsFeedPage> {
  const limit = opts?.limit ?? EVENTS_FEED_PAGE_SIZE;
  const p_args = buildEventsFeedArgs(filter, limit, opts?.cursor);
  const { data, error } = await supabase.rpc("list_events_feed_enriched_cursor", {
    p_args,
  });
  if (error) throw error;
  const posts = await attachBookingServicesWithClient(supabase, mapFeedRpcRows(data));
  return { posts, hasMore: posts.length >= limit };
}
