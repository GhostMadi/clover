"use client";

import {
  cursorFromPost,
  fetchEventsFeedPage,
  type EventsFeedPage,
  EVENTS_FEED_PAGE_SIZE,
} from "@/features/feed/lib/events-feed-query";
import type { EventsFeedFilter } from "@/features/feed/lib/events-feed-filter";
import type { FeedPost } from "@/features/post/lib/parse-feed";
import { createClient } from "@/lib/supabase/client";

/** Догрузка ленты на клиенте (пагинация скролла). */
export async function listEventsFeedMore(
  filter: EventsFeedFilter,
  cursorPost: FeedPost,
  limit = EVENTS_FEED_PAGE_SIZE,
): Promise<EventsFeedPage> {
  const supabase = createClient();
  return fetchEventsFeedPage(supabase, filter, {
    limit,
    cursor: cursorFromPost(cursorPost),
  });
}
