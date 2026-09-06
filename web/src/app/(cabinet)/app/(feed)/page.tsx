import { EventsFeedView } from "@/features/feed/components/events-feed-view";
import { listEventsFeed, parseEventsFilter } from "@/features/feed/lib/events-feed";
import { createClient } from "@/lib/supabase/server";

type PageProps = {
  searchParams: Promise<{
    kind?: string;
    country?: string;
    city?: string;
    emoji?: string;
    from?: string;
    to?: string;
    tags?: string;
  }>;
};

export default async function AppHomePage({ searchParams }: PageProps) {
  const sp = await searchParams;
  const filter = parseEventsFilter(sp);
  const supabase = await createClient();
  const [{ data: sessionData }, page] = await Promise.all([
    supabase.auth.getSession(),
    listEventsFeed(filter),
  ]);
  const currentUserId = sessionData.session?.user.id ?? null;

  return (
    <EventsFeedView
      posts={page.posts}
      hasMore={page.hasMore}
      filter={filter}
      currentUserId={currentUserId}
    />
  );
}
