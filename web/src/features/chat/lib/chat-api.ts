"use client";

import {
  CHATS_PAGE_SIZE,
  MESSAGES_PAGE_SIZE,
  parseConversationRow,
  parseMessageRow,
  type ChatConversation,
  type ChatMessage,
} from "@/features/chat/lib/chat-model";
import { notifyChatUnreadChanged } from "@/features/chat/lib/chat-unread";
import { createClient } from "@/lib/supabase/client";

export async function listConversationsPage(opts?: {
  limit?: number;
  offset?: number;
}): Promise<ChatConversation[]> {
  const supabase = createClient();
  const {
    data: { session },
  } = await supabase.auth.getSession();
  const uid = session?.user.id;
  if (!uid) return [];

  const { data, error } = await supabase.rpc("list_conversations_enriched", {
    p_limit: opts?.limit ?? CHATS_PAGE_SIZE,
    p_offset: opts?.offset ?? 0,
  });
  if (error) throw error;
  const rows = Array.isArray(data) ? data : [];
  const items: ChatConversation[] = [];
  for (const row of rows) {
    if (!row || typeof row !== "object") continue;
    const item = parseConversationRow(row as Record<string, unknown>, uid);
    if (item) items.push(item);
  }
  return items;
}

export async function listMessagesPage(
  conversationId: string,
  opts?: { limit?: number; before?: string | null },
): Promise<ChatMessage[]> {
  const supabase = createClient();
  const {
    data: { session },
  } = await supabase.auth.getSession();
  const uid = session?.user.id;
  if (!uid) return [];

  const params: Record<string, unknown> = {
    p_conversation_id: conversationId,
    p_limit: opts?.limit ?? MESSAGES_PAGE_SIZE,
  };
  if (opts?.before) params.p_before = opts.before;

  const { data, error } = await supabase.rpc("list_messages_enriched", params);
  if (error) throw error;
  const rows = Array.isArray(data) ? data : [];
  const items: ChatMessage[] = [];
  for (const row of rows) {
    if (!row || typeof row !== "object") continue;
    const item = parseMessageRow(row as Record<string, unknown>, uid);
    if (item) items.push(item);
  }
  return items;
}

export async function getMessageEnriched(messageId: string): Promise<ChatMessage | null> {
  const supabase = createClient();
  const {
    data: { session },
  } = await supabase.auth.getSession();
  const uid = session?.user.id;
  if (!uid) return null;
  const { data, error } = await supabase.rpc("get_message_enriched", {
    p_message_id: messageId,
  });
  if (error) throw error;
  const rows = Array.isArray(data) ? data : [];
  const row = rows[0];
  if (!row || typeof row !== "object") return null;
  return parseMessageRow(row as Record<string, unknown>, uid);
}

export async function sendTextMessage(opts: {
  conversationId: string;
  text: string;
  clientMessageId?: string;
}): Promise<string> {
  const body = opts.text.trim();
  if (!body) throw new Error("Пустое сообщение");
  const supabase = createClient();
  const params: Record<string, unknown> = {
    p_conversation_id: opts.conversationId,
    p_kind: "text",
    p_text: body,
  };
  if (opts.clientMessageId) params.p_client_message_id = opts.clientMessageId;
  const { data, error } = await supabase.rpc("send_message", params);
  if (error) throw error;
  const id = String(data ?? "").trim();
  if (!id) throw new Error("Не удалось отправить");
  return id;
}

export async function markConversationRead(
  conversationId: string,
  lastMessageId?: string | null,
): Promise<void> {
  const supabase = createClient();
  const params: Record<string, unknown> = {
    p_conversation_id: conversationId,
  };
  if (lastMessageId) params.p_last_message_id = lastMessageId;
  const { error } = await supabase.rpc("mark_conversation_read", params);
  if (error) throw error;
  notifyChatUnreadChanged();
}

export async function createDm(otherUserId: string): Promise<string> {
  const supabase = createClient();
  const { data, error } = await supabase.rpc("create_dm", {
    p_other_user_id: otherUserId,
  });
  if (error) throw error;
  const id = String(data ?? "").trim();
  if (!id) throw new Error("Не удалось открыть чат");
  return id;
}

export async function createGroupChat(opts: {
  title: string;
  userIds: string[];
}): Promise<string> {
  const title = opts.title.trim();
  if (!title) throw new Error("Введите название");
  const supabase = createClient();
  const { data, error } = await supabase.rpc("create_group", {
    p_title: title,
    p_user_ids: opts.userIds,
  });
  if (error) throw error;
  const id = String(data ?? "").trim();
  if (!id) throw new Error("Не удалось создать группу");
  return id;
}

export type MessageSearchHit = {
  conversationId: string;
  messageId: string;
  text: string;
  sentAt: string;
  senderName: string | null;
};

export async function searchMessages(opts: {
  query: string;
  conversationId?: string | null;
  limit?: number;
}): Promise<MessageSearchHit[]> {
  const q = opts.query.trim();
  if (!q) return [];
  const supabase = createClient();
  const params: Record<string, unknown> = {
    p_query: q,
    p_limit: opts.limit ?? 50,
  };
  if (opts.conversationId) params.p_conversation_id = opts.conversationId;
  const { data, error } = await supabase.rpc("search_messages", params);
  if (error) throw error;
  if (!Array.isArray(data)) return [];
  return data
    .map((row) => {
      if (!row || typeof row !== "object") return null;
      const r = row as Record<string, unknown>;
      const message =
        r.message && typeof r.message === "object"
          ? (r.message as Record<string, unknown>)
          : null;
      const sender =
        r.sender && typeof r.sender === "object"
          ? (r.sender as Record<string, unknown>)
          : null;
      const messageId = String(message?.id ?? "").trim();
      const conversationId = String(r.conversation_id ?? "").trim();
      if (!messageId || !conversationId) return null;
      return {
        conversationId,
        messageId,
        text: String(message?.text ?? "").trim(),
        sentAt: String(message?.created_at ?? message?.sent_at ?? ""),
        senderName: (sender?.username as string | null)?.trim() || null,
      };
    })
    .filter((h): h is MessageSearchHit => Boolean(h));
}

export async function sendAttachments(opts: {
  conversationId: string;
  files: File[];
  caption?: string;
  clientMessageId?: string;
}): Promise<string> {
  if (opts.files.length === 0) throw new Error("Нет файлов");
  const supabase = createClient();
  const {
    data: { session },
  } = await supabase.auth.getSession();
  const token = session?.access_token;
  if (!token) throw new Error("Требуется вход");

  const base = process.env.NEXT_PUBLIC_SUPABASE_URL?.replace(/\/$/, "");
  const anon = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;
  if (!base || !anon) throw new Error("Нет конфигурации Supabase");

  const form = new FormData();
  form.set("conversation_id", opts.conversationId);
  const caption = opts.caption?.trim();
  if (caption) form.set("caption", caption);
  if (opts.clientMessageId) form.set("client_message_id", opts.clientMessageId);
  for (const file of opts.files) {
    form.append("files", file, file.name);
  }

  const res = await fetch(`${base}/functions/v1/send_chat_attachments`, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${token}`,
      apikey: anon,
    },
    body: form,
  });

  const json = (await res.json().catch(() => null)) as
    | { message_id?: string; error?: string; detail?: string }
    | null;
  if (!res.ok) {
    throw new Error(json?.detail || json?.error || "Не удалось отправить вложение");
  }
  const id = String(json?.message_id ?? "").trim();
  if (!id) throw new Error("Не удалось отправить вложение");
  return id;
}
