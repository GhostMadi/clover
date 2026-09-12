"use client";

import type { RealtimeChannel, SupabaseClient } from "@supabase/supabase-js";
import { createClient } from "@/lib/supabase/client";

/** Shell + list listen; mark-read / inbox realtime dispatch. */
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

type InboxBind = {
  channel: RealtimeChannel;
  supabase: SupabaseClient;
  uid: string;
  debounce: ReturnType<typeof setTimeout> | null;
};

let inboxBind: InboxBind | null = null;

function scheduleInboxNotify(): void {
  if (!inboxBind) return;
  if (inboxBind.debounce) clearTimeout(inboxBind.debounce);
  inboxBind.debounce = setTimeout(() => {
    notifyChatUnreadChanged();
  }, 350);
}

/**
 * Один Realtime-канал `chat_inbox_<uid>` на вкладку (как Flutter ChatUnreadCubit).
 * Вызывать из cabinet-shell; повторный вызов с тем же uid — no-op.
 */
export function bindChatInboxRealtime(): () => void {
  if (typeof window === "undefined") return () => undefined;

  const supabase = createClient();
  let cancelled = false;
  let authSub: { unsubscribe: () => void } | null = null;

  const bind = (userId: string) => {
    if (cancelled) return;
    if (inboxBind?.uid === userId) return;

    unbindChatInboxRealtime();

    const channel = supabase
      .channel(`chat_inbox_${userId}`)
      .on("broadcast", { event: "inbox_changed" }, () => {
        scheduleInboxNotify();
      })
      .subscribe();

    inboxBind = {
      channel,
      supabase,
      uid: userId,
      debounce: null,
    };
  };

  void supabase.auth.getSession().then(({ data }) => {
    const id = data.session?.user.id?.trim();
    if (id) bind(id);
  });

  const { data } = supabase.auth.onAuthStateChange((event, session) => {
    if (event === "SIGNED_OUT") {
      unbindChatInboxRealtime();
      return;
    }
    const id = session?.user.id?.trim();
    if (
      id &&
      (event === "SIGNED_IN" || event === "TOKEN_REFRESHED" || event === "INITIAL_SESSION")
    ) {
      bind(id);
    }
  });
  authSub = data.subscription;

  return () => {
    cancelled = true;
    authSub?.unsubscribe();
    unbindChatInboxRealtime();
  };
}

export function unbindChatInboxRealtime(): void {
  if (!inboxBind) return;
  if (inboxBind.debounce) clearTimeout(inboxBind.debounce);
  void inboxBind.supabase.removeChannel(inboxBind.channel);
  inboxBind = null;
}
