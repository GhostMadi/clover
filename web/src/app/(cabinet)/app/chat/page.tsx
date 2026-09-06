import { ChatsListView } from "@/features/chat/components/chats-list-view";
import { listConversationsServer } from "@/features/chat/lib/chat-server";

export default async function AppChatPage() {
  const { items } = await listConversationsServer();
  return <ChatsListView initialItems={items} />;
}
