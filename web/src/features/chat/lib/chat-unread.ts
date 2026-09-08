"use client";

import { createClient } from "@/lib/supabase/client";

/** Shell + list listen; mark-read / new message paths dispatch. */
export const CHAT_UNREAD_CHANGED = "clover:chat-unread-changed";

export function notifyChatUnreadChanged(): void {
  if (typeof window === "undefined") return;
  window.dispatchEvent(new Event(CHAT_UNREAD_CHANGED));
}

export async function countUnreadChatMessages(): Promise<number> {
  const supabase = createClient();
  const { data, error } = await supabase.rpc("count_unread_chat_messages");
  if (error) return 0;
  if (typeof data === "number") return data;
  return Number(data) || 0;
}
