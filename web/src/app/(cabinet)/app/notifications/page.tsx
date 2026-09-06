import { NotificationsView } from "@/features/notifications/components/notifications-view";
import {
  NOTIFICATIONS_PAGE_SIZE,
  parseNotificationRow,
  type AppNotification,
} from "@/features/notifications/lib/notifications-model";
import { createClient } from "@/lib/supabase/server";

export default async function NotificationsPage() {
  const supabase = await createClient();
  const {
    data: { session },
  } = await supabase.auth.getSession();

  if (!session) {
    return <NotificationsView initialItems={[]} initialHasMore={false} />;
  }

  const { data } = await supabase.rpc("list_notifications_enriched_cursor", {
    p_limit: NOTIFICATIONS_PAGE_SIZE,
  });
  const rows = Array.isArray(data) ? data : [];
  const items: AppNotification[] = [];
  for (const row of rows) {
    if (!row || typeof row !== "object") continue;
    const item = parseNotificationRow(row as Record<string, unknown>);
    if (item) items.push(item);
  }

  return (
    <NotificationsView
      initialItems={items}
      initialHasMore={items.length >= NOTIFICATIONS_PAGE_SIZE}
    />
  );
}
