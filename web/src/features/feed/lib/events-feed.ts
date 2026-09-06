import {
  fetchEventsFeedPage,
  type EventsFeedCursor,
  type EventsFeedPage,
  EVENTS_FEED_PAGE_SIZE,
} from "@/features/feed/lib/events-feed-query";
import type { EventsFeedFilter } from "@/features/feed/lib/events-feed-filter";
import { createClient } from "@/lib/supabase/server";

export type {
  EventsContentKind,
  EventsFeedFilter,
} from "@/features/feed/lib/events-feed-filter";
export {
  DEFAULT_EVENTS_FILTER,
  eventsFilterHasExtras,
  parseEventsFilter,
} from "@/features/feed/lib/events-feed-filter";
export type { EventsFeedCursor, EventsFeedPage } from "@/features/feed/lib/events-feed-query";
export { cursorFromPost, EVENTS_FEED_PAGE_SIZE } from "@/features/feed/lib/events-feed-query";

/** Городская лента — `list_events_feed_enriched_cursor`, как EventsFeedRepository. */
export async function listEventsFeed(
  filter: EventsFeedFilter,
  opts?: { limit?: number; cursor?: EventsFeedCursor | null },
): Promise<EventsFeedPage> {
  const supabase = await createClient();
  return fetchEventsFeedPage(supabase, filter, {
    limit: opts?.limit ?? EVENTS_FEED_PAGE_SIZE,
    cursor: opts?.cursor,
  });
}

export type { FeedPost } from "@/features/post/lib/parse-feed";
