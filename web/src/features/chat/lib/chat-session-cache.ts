"use client";

import type { ChatConversation, ChatMessage } from "@/features/chat/lib/chat-model";

const PREFIX = "clover_chat_v1_";

type ThreadCache = {
  messages: ChatMessage[];
  watermarkId: string | null;
  at: number;
};

type ConversationsCache = {
  items: ChatConversation[];
  at: number;
};

function keyConversations(userId: string) {
  return `${PREFIX}conversations_${userId.trim()}`;
}

function keyThread(userId: string, conversationId: string) {
  return `${PREFIX}thread_${userId.trim()}_${conversationId.trim()}`;
}

function keyWallpaper(userId: string, conversationId: string) {
  return `${PREFIX}wallpaper_${userId.trim()}_${conversationId.trim()}`;
}

/** Session memory (sessionStorage) — local-first paint for chat list/thread. */
export function readConversationsCache(userId: string): ChatConversation[] | null {
  if (typeof window === "undefined") return null;
  const uid = userId.trim();
  if (!uid) return null;
  try {
    const raw = sessionStorage.getItem(keyConversations(uid));
    if (!raw) return null;
    const parsed = JSON.parse(raw) as ConversationsCache;
    if (!Array.isArray(parsed?.items)) return null;
    return parsed.items;
  } catch {
    return null;
  }
}

export function writeConversationsCache(
  userId: string,
  items: ChatConversation[],
): void {
  if (typeof window === "undefined") return;
  const uid = userId.trim();
  if (!uid) return;
  try {
    const entry: ConversationsCache = { items, at: Date.now() };
    sessionStorage.setItem(keyConversations(uid), JSON.stringify(entry));
  } catch {
    // quota
  }
}

export function readThreadCache(
  userId: string,
  conversationId: string,
): ThreadCache | null {
  if (typeof window === "undefined") return null;
  const uid = userId.trim();
  const cid = conversationId.trim();
  if (!uid || !cid) return null;
  try {
    const raw = sessionStorage.getItem(keyThread(uid, cid));
    if (!raw) return null;
    const parsed = JSON.parse(raw) as ThreadCache;
    if (!Array.isArray(parsed?.messages)) return null;
    return parsed;
  } catch {
    return null;
  }
}

export function writeThreadCache(
  userId: string,
  conversationId: string,
  messages: ChatMessage[],
): void {
  if (typeof window === "undefined") return;
  const uid = userId.trim();
  const cid = conversationId.trim();
  if (!uid || !cid) return;
  const persisted = messages.filter((m) => !m.isPending && m.id.trim());
  const head = persisted.length ? persisted[persisted.length - 1] : null;
  try {
    const entry: ThreadCache = {
      messages: persisted,
      watermarkId: head?.id ?? null,
      at: Date.now(),
    };
    sessionStorage.setItem(keyThread(uid, cid), JSON.stringify(entry));
  } catch {
    // quota
  }
}

export function upsertThreadMessage(
  userId: string,
  conversationId: string,
  message: ChatMessage,
): void {
  if (message.isPending || !message.id.trim()) return;
  const cached = readThreadCache(userId, conversationId);
  const existing = cached?.messages ?? [];
  const clientId = message.clientMessageId?.trim();
  const index = existing.findIndex(
    (m) =>
      m.id === message.id ||
      (clientId &&
        (m.clientMessageId === clientId || m.id === clientId)),
  );
  const next = [...existing];
  if (index >= 0) next[index] = { ...message, isPending: false };
  else next.push({ ...message, isPending: false });
  next.sort((a, b) => {
    const t = a.sentAt.localeCompare(b.sentAt);
    return t !== 0 ? t : a.id.localeCompare(b.id);
  });
  writeThreadCache(userId, conversationId, next);
}

export function removeThreadMessage(
  userId: string,
  conversationId: string,
  messageId: string,
): void {
  const cached = readThreadCache(userId, conversationId);
  if (!cached) return;
  const next = cached.messages.filter((m) => m.id !== messageId);
  writeThreadCache(userId, conversationId, next);
}

export function readWallpaperCache(
  userId: string,
  conversationId: string,
): string[] | null {
  if (typeof window === "undefined") return null;
  const uid = userId.trim();
  const cid = conversationId.trim();
  if (!uid || !cid) return null;
  try {
    const raw = sessionStorage.getItem(keyWallpaper(uid, cid));
    if (!raw) return null;
    const parsed = JSON.parse(raw);
    return Array.isArray(parsed) ? parsed.map(String) : null;
  } catch {
    return null;
  }
}

export function writeWallpaperCache(
  userId: string,
  conversationId: string,
  emojis: string[],
): void {
  if (typeof window === "undefined") return;
  const uid = userId.trim();
  const cid = conversationId.trim();
  if (!uid || !cid) return;
  try {
    sessionStorage.setItem(keyWallpaper(uid, cid), JSON.stringify(emojis));
  } catch {
    // quota
  }
}

/** True when cached head covers the watermark (or no watermark yet). */
export function shouldPaintThreadCache(
  cache: ThreadCache | null,
  inboxHeadMessageId?: string | null,
): boolean {
  if (!cache || cache.messages.length === 0) return false;
  const wm = cache.watermarkId?.trim();
  if (!wm) return true;
  if (inboxHeadMessageId && inboxHeadMessageId !== wm) {
    // Inbox says there's a newer head than our watermark — don't paint stale.
    const hasHead = cache.messages.some((m) => m.id === inboxHeadMessageId);
    return hasHead;
  }
  return cache.messages.some((m) => m.id === wm);
}

export function clearChatSessionCache(userId?: string): void {
  if (typeof window === "undefined") return;
  try {
    if (userId?.trim()) {
      const uid = userId.trim();
      const remove: string[] = [];
      for (let i = 0; i < sessionStorage.length; i++) {
        const k = sessionStorage.key(i);
        if (
          k?.startsWith(`${PREFIX}conversations_${uid}`) ||
          k?.startsWith(`${PREFIX}thread_${uid}_`) ||
          k?.startsWith(`${PREFIX}wallpaper_${uid}_`)
        ) {
          remove.push(k);
        }
      }
      for (const k of remove) sessionStorage.removeItem(k);
      return;
    }
    const remove: string[] = [];
    for (let i = 0; i < sessionStorage.length; i++) {
      const k = sessionStorage.key(i);
      if (k?.startsWith(PREFIX)) remove.push(k);
    }
    for (const k of remove) sessionStorage.removeItem(k);
  } catch {
    // ignore
  }
}
