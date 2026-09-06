import {
  CHATS_PAGE_SIZE,
  parseConversationRow,
  parseMessageRow,
  MESSAGES_PAGE_SIZE,
  type ChatConversation,
  type ChatMessage,
} from "@/features/chat/lib/chat-model";
import { createClient } from "@/lib/supabase/server";

export async function listConversationsServer(): Promise<{
  items: ChatConversation[];
  currentUserId: string | null;
}> {
  const supabase = await createClient();
  const {
    data: { session },
  } = await supabase.auth.getSession();
  const uid = session?.user.id ?? null;
  if (!uid) return { items: [], currentUserId: null };

  const { data } = await supabase.rpc("list_conversations_enriched", {
    p_limit: CHATS_PAGE_SIZE,
    p_offset: 0,
  });
  const rows = Array.isArray(data) ? data : [];
  const items: ChatConversation[] = [];
  for (const row of rows) {
    if (!row || typeof row !== "object") continue;
    const item = parseConversationRow(row as Record<string, unknown>, uid);
    if (item) items.push(item);
  }
  return { items, currentUserId: uid };
}

export async function loadThreadServer(conversationId: string): Promise<{
  messages: ChatMessage[];
  hasMore: boolean;
  conversation: ChatConversation | null;
  currentUserId: string | null;
}> {
  const supabase = await createClient();
  const {
    data: { session },
  } = await supabase.auth.getSession();
  const uid = session?.user.id ?? null;
  if (!uid) {
    return { messages: [], hasMore: false, conversation: null, currentUserId: null };
  }

  const [{ data: msgData }, { data: convData }] = await Promise.all([
    supabase.rpc("list_messages_enriched", {
      p_conversation_id: conversationId,
      p_limit: MESSAGES_PAGE_SIZE,
    }),
    supabase.rpc("list_conversations_enriched", {
      p_limit: 200,
      p_offset: 0,
    }),
  ]);

  const msgRows = Array.isArray(msgData) ? msgData : [];
  const messages: ChatMessage[] = [];
  for (const row of msgRows) {
    if (!row || typeof row !== "object") continue;
    const item = parseMessageRow(row as Record<string, unknown>, uid);
    if (item) messages.push(item);
  }

  const convRows = Array.isArray(convData) ? convData : [];
  let conversation: ChatConversation | null = null;
  for (const row of convRows) {
    if (!row || typeof row !== "object") continue;
    const item = parseConversationRow(row as Record<string, unknown>, uid);
    if (item?.id === conversationId) {
      conversation = item;
      break;
    }
  }

  return {
    messages,
    hasMore: messages.length >= MESSAGES_PAGE_SIZE,
    conversation,
    currentUserId: uid,
  };
}
