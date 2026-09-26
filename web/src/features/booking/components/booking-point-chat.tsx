"use client";

import { useEffect, useState } from "react";
import { BookingListShimmer } from "@/features/booking/components/booking-shimmers";
import { ChatThreadView } from "@/features/chat/components/chat-thread-view";
import { listConversationsPage, listMessagesPage } from "@/features/chat/lib/chat-api";
import {
  MESSAGES_PAGE_SIZE,
  type ChatConversation,
  type ChatMessage,
} from "@/features/chat/lib/chat-model";
import { getSessionUserId } from "@/lib/run-service-swr";

function pointConversation(id: string, title: string): ChatConversation {
  return {
    id,
    type: "group",
    title,
    isGroup: true,
    peer: null,
    lastMessageText: "",
    lastMessageAt: new Date().toISOString(),
    isLastMessageMine: false,
    isRead: true,
    unreadCount: 0,
    avatarUrl: null,
  };
}

/** Чат команды точки внутри рабочего стола записи. */
export function BookingPointChat({
  conversationId,
  onClose,
}: {
  conversationId: string;
  onClose: () => void;
}) {
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [messages, setMessages] = useState<ChatMessage[]>([]);
  const [hasMore, setHasMore] = useState(false);
  const [conversation, setConversation] = useState<ChatConversation | null>(null);
  const [userId, setUserId] = useState<string | null>(null);

  useEffect(() => {
    let cancelled = false;
    void (async () => {
      try {
        const uid = await getSessionUserId();
        if (!uid) throw new Error("Войдите в аккаунт");
        const [page, convs] = await Promise.all([
          listMessagesPage(conversationId),
          listConversationsPage(),
        ]);
        if (cancelled) return;
        const found = convs.find((c) => c.id === conversationId) ?? null;
        setUserId(uid);
        setMessages(page);
        setHasMore(page.length >= MESSAGES_PAGE_SIZE);
        setConversation(found ?? pointConversation(conversationId, "Команда точки"));
      } catch (e: unknown) {
        if (!cancelled) {
          setError(e instanceof Error ? e.message : "Не удалось открыть чат");
        }
      } finally {
        if (!cancelled) setLoading(false);
      }
    })();
    return () => {
      cancelled = true;
    };
  }, [conversationId]);

  if (loading || !userId || !conversation) {
    return (
      <div className="flex h-[calc(100dvh-10.5rem)] min-h-[420px] flex-col justify-center md:h-[calc(100dvh-7.5rem)]">
        {error ? (
          <p className="px-4 text-center text-[13px] text-destructive">{error}</p>
        ) : (
          <BookingListShimmer rows={6} />
        )}
      </div>
    );
  }

  return (
    <div className="flex h-[calc(100dvh-10.5rem)] min-h-[420px] flex-col overflow-hidden rounded-[16px] border border-line md:h-[calc(100dvh-7.5rem)]">
      <ChatThreadView
        conversationId={conversationId}
        initialMessages={messages}
        initialHasMore={hasMore}
        conversation={conversation}
        currentUserId={userId}
        embedded
        onClose={onClose}
      />
    </div>
  );
}
