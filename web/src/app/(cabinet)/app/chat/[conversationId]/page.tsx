import { notFound } from "next/navigation";
import { ChatThreadView } from "@/features/chat/components/chat-thread-view";
import { loadThreadServer } from "@/features/chat/lib/chat-server";
import type { ChatConversation } from "@/features/chat/lib/chat-model";

type PageProps = {
  params: Promise<{ conversationId: string }>;
  searchParams: Promise<{ u?: string; a?: string; peer?: string }>;
};

export default async function ChatThreadPage({ params, searchParams }: PageProps) {
  const { conversationId } = await params;
  const sp = await searchParams;
  const id = conversationId?.trim();
  if (!id) notFound();

  const { messages, hasMore, conversation, currentUserId } =
    await loadThreadServer(id);

  if (!currentUserId) notFound();

  const fallbackTitle = sp.u?.trim() || null;
  const fallbackAvatar = sp.a?.trim() || null;
  const fallbackPeer = sp.peer?.trim() || null;

  const resolved: ChatConversation | null =
    conversation ??
    (fallbackTitle
      ? {
          id,
          type: "dm",
          title: fallbackTitle.replace(/^@/, ""),
          isGroup: false,
          peer: fallbackPeer
            ? {
                id: fallbackPeer,
                username: fallbackTitle.replace(/^@/, ""),
                avatarUrl: fallbackAvatar,
              }
            : null,
          lastMessageText: "",
          lastMessageAt: new Date().toISOString(),
          isLastMessageMine: false,
          isRead: true,
          unreadCount: 0,
          avatarUrl: fallbackAvatar,
        }
      : null);

  return (
    <ChatThreadView
      conversationId={id}
      initialMessages={messages}
      initialHasMore={hasMore}
      conversation={resolved}
      currentUserId={currentUserId}
    />
  );
}
