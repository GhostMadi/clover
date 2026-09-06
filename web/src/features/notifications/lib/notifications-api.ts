"use client";

import {
  NOTIFICATIONS_PAGE_SIZE,
  parseNotificationRow,
  type AppNotification,
} from "@/features/notifications/lib/notifications-model";
import { createClient } from "@/lib/supabase/client";

export type NotificationsPage = {
  items: AppNotification[];
  hasMore: boolean;
};

export async function listNotificationsPage(opts?: {
  limit?: number;
  cursor?: { createdAt: string; id: string } | null;
}): Promise<NotificationsPage> {
  const limit = opts?.limit ?? NOTIFICATIONS_PAGE_SIZE;
  const supabase = createClient();
  const params: Record<string, unknown> = { p_limit: limit };
  if (opts?.cursor) {
    params.p_cursor_created_at = opts.cursor.createdAt;
    params.p_cursor_id = opts.cursor.id;
  }
  const { data, error } = await supabase.rpc("list_notifications_enriched_cursor", params);
  if (error) throw error;
  const rows = Array.isArray(data) ? data : [];
  const items: AppNotification[] = [];
  for (const row of rows) {
    if (!row || typeof row !== "object") continue;
    const item = parseNotificationRow(row as Record<string, unknown>);
    if (item) items.push(item);
  }
  return { items, hasMore: items.length >= limit };
}

export async function countUnreadNotifications(): Promise<number> {
  const supabase = createClient();
  const { data, error } = await supabase.rpc("count_unread_notifications");
  if (error) return 0;
  if (typeof data === "number") return data;
  return Number(data) || 0;
}

export async function markNotificationsRead(ids?: string[]): Promise<void> {
  const supabase = createClient();
  const params: Record<string, unknown> = {};
  if (ids && ids.length > 0) params.p_ids = ids;
  const { error } = await supabase.rpc("mark_notifications_read", params);
  if (error) throw error;
}
