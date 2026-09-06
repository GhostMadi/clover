"use client";

import {
  ArrowLeft,
  Check,
  CheckCheck,
  Clock,
  FileText,
  Image as ImageIcon,
  Paperclip,
  Plus,
  RotateCcw,
  Search,
  SendHorizontal,
  User,
  X,
} from "lucide-react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import {
  useCallback,
  useEffect,
  useMemo,
  useRef,
  useState,
} from "react";
import {
  getMessageEnriched,
  listMessagesPage,
  markConversationRead,
  searchMessages,
  sendAttachments,
  sendTextMessage,
  type MessageSearchHit,
} from "@/features/chat/lib/chat-api";
import {
  attachErrorMessage,
  CHAT_DOCUMENT_ACCEPT,
  CHAT_MAX_FILES_PER_MESSAGE,
  CHAT_PHOTO_ACCEPT,
  formatFileSize,
  isImageMime,
  prepareUploads,
  validateChatFiles,
  type PendingChatFile,
} from "@/features/chat/lib/chat-attachment-limits";
import {
  formatMessageDayLabel,
  formatMessageTime,
  MESSAGES_PAGE_SIZE,
  parseMessageRow,
  type ChatConversation,
  type ChatMessage,
} from "@/features/chat/lib/chat-model";
import { createClient } from "@/lib/supabase/client";

type ChatThreadViewProps = {
  conversationId: string;
  initialMessages: ChatMessage[];
  initialHasMore: boolean;
  conversation: ChatConversation | null;
  currentUserId: string;
};

function dayKey(iso: string): string {
  const d = new Date(iso);
  if (Number.isNaN(d.getTime())) return iso;
  return `${d.getFullYear()}-${d.getMonth()}-${d.getDate()}`;
}

function asMap(value: unknown): Record<string, unknown> | null {
  if (!value || typeof value !== "object") return null;
  return value as Record<string, unknown>;
}

function mergeMessage(list: ChatMessage[], next: ChatMessage): ChatMessage[] {
  const byClient = next.clientMessageId
    ? list.findIndex((m) => m.clientMessageId === next.clientMessageId)
    : -1;
  if (byClient >= 0) {
    const copy = [...list];
    copy[byClient] = { ...next, isPending: false };
    return copy;
  }
  if (list.some((m) => m.id === next.id)) {
    return list.map((m) => (m.id === next.id ? { ...m, ...next, isPending: false } : m));
  }
  return [...list, next];
}

function StatusTicks({ message }: { message: ChatMessage }) {
  if (!message.isMine) return null;
  if (message.sendFailed) {
    return <RotateCcw className="h-3.5 w-3.5" strokeWidth={2.25} />;
  }
  if (message.isPending) {
    return <Clock className="h-3.5 w-3.5 opacity-80" strokeWidth={2.25} />;
  }
  if (message.isRead) {
    return <CheckCheck className="h-3.5 w-3.5" strokeWidth={2.25} />;
  }
  return <Check className="h-3.5 w-3.5" strokeWidth={2.25} />;
}

function MessageBubble({
  message,
  onRetry,
}: {
  message: ChatMessage;
  onRetry?: (message: ChatMessage) => void;
}) {
  const mine = message.isMine;
  const time = formatMessageTime(message.sentAt);
  const failed = Boolean(message.sendFailed);

  if (message.postRef) {
    return (
      <div className={`flex ${mine ? "justify-end" : "justify-start"}`}>
        <div
          className={`max-w-[78%] overflow-hidden rounded-[20px] border border-line ${
            mine ? "rounded-br-lg bg-brand text-on-brand" : "rounded-bl-lg bg-surface text-ink"
          } ${failed ? "ring-2 ring-destructive/40" : ""}`}
        >
          <Link href={`/app/posts/${message.postRef.postId}`} className="block">
            {message.postRef.coverUrl ? (
              // eslint-disable-next-line @next/next/no-img-element
              <img
                src={message.postRef.coverUrl}
                alt=""
                className="aspect-[4/3] w-full object-cover"
              />
            ) : (
              <div className={`flex h-28 items-center justify-center ${mine ? "bg-black/10" : "bg-mint"}`}>
                <ImageIcon className={`h-7 w-7 ${mine ? "text-on-brand/80" : "text-muted"}`} />
              </div>
            )}
            <div className="px-3 py-2">
              <p className={`text-[12px] font-bold ${mine ? "text-on-brand/90" : "text-brand"}`}>
                Пост
              </p>
              <p className="mt-0.5 line-clamp-2 text-[13px]">
                {message.postRef.caption || message.postRef.title || message.text || "Открыть"}
              </p>
            </div>
          </Link>
          <div
            className={`flex items-center justify-end gap-1 px-3 pb-2 text-[11px] ${
              mine ? "text-on-brand/80" : "text-muted"
            }`}
          >
            <span>{time}</span>
            <StatusTicks message={message} />
          </div>
        </div>
      </div>
    );
  }

  const images = message.attachments.filter((a) => isImageMime(a.mime ?? ""));
  const files = message.attachments.filter((a) => !isImageMime(a.mime ?? ""));

  return (
    <div className={`flex flex-col gap-1 ${mine ? "items-end" : "items-start"}`}>
      <div
        className={`max-w-[78%] rounded-[20px] px-3.5 py-2.5 shadow-sm ${
          mine
            ? "rounded-br-lg bg-brand text-on-brand"
            : "rounded-bl-lg border border-line bg-surface text-ink"
        } ${failed ? "ring-2 ring-destructive/40" : ""}`}
      >
        {images.length === 1 && images[0]?.url ? (
          // eslint-disable-next-line @next/next/no-img-element
          <img
            src={images[0].url}
            alt=""
            className="mb-2 max-h-64 w-full rounded-xl object-cover"
          />
        ) : null}
        {images.length > 1 ? (
          <div className="mb-2 grid grid-cols-2 gap-1">
            {images.slice(0, 4).map((a) =>
              a.url ? (
                // eslint-disable-next-line @next/next/no-img-element
                <img
                  key={a.id || a.path}
                  src={a.url}
                  alt=""
                  className="aspect-square w-full rounded-lg object-cover"
                />
              ) : null,
            )}
          </div>
        ) : null}
        {files.length > 0 ? (
          <ul className="mb-2 space-y-1.5">
            {files.map((a) => {
              const name = a.path.split("/").pop() || "Файл";
              return (
                <li key={a.id || a.path}>
                  {a.url ? (
                    <a
                      href={a.url}
                      target="_blank"
                      rel="noreferrer"
                      className={`flex items-center gap-2 rounded-xl px-2 py-1.5 ${
                        mine ? "bg-black/10" : "bg-bg"
                      }`}
                    >
                      <FileText className="h-4 w-4 shrink-0" strokeWidth={2} />
                      <span className="min-w-0 flex-1 truncate text-[13px] font-semibold">
                        {name}
                      </span>
                      {a.sizeBytes ? (
                        <span className={`text-[11px] ${mine ? "text-on-brand/75" : "text-muted"}`}>
                          {formatFileSize(a.sizeBytes)}
                        </span>
                      ) : null}
                    </a>
                  ) : (
                    <span className="text-[13px] font-semibold">Вложение</span>
                  )}
                </li>
              );
            })}
          </ul>
        ) : null}
        {message.text ? (
          <p className="whitespace-pre-wrap break-words text-[15px] leading-snug">
            {message.text}
          </p>
        ) : null}
        <div
          className={`mt-1 flex items-center justify-end gap-1 text-[11px] ${
            mine ? "text-on-brand/80" : "text-muted"
          }`}
        >
          {message.editedAt ? <span>изм.</span> : null}
          <span>{time}</span>
          <StatusTicks message={message} />
        </div>
      </div>
      {failed && onRetry ? (
        <button
          type="button"
          onClick={() => onRetry(message)}
          className="flex items-center gap-1 rounded-full bg-surface px-2.5 py-1 text-[11px] font-semibold text-destructive shadow-sm"
        >
          <RotateCcw className="h-3 w-3" strokeWidth={2.5} />
          Повторить
        </button>
      ) : null}
    </div>
  );
}

/** Экран переписки: история, отправка, realtime. */
export function ChatThreadView({
  conversationId,
  initialMessages,
  initialHasMore,
  conversation,
  currentUserId,
}: ChatThreadViewProps) {
  const router = useRouter();
  const [messages, setMessages] = useState(initialMessages);
  const [hasMore, setHasMore] = useState(initialHasMore);
  const [loadingOlder, setLoadingOlder] = useState(false);
  const [text, setText] = useState("");
  const [pending, setPending] = useState<PendingChatFile[]>([]);
  const [attachMenu, setAttachMenu] = useState(false);
  const [toast, setToast] = useState<string | null>(null);
  const [threadSearchOpen, setThreadSearchOpen] = useState(false);
  const [threadQuery, setThreadQuery] = useState("");
  const [threadHits, setThreadHits] = useState<MessageSearchHit[]>([]);
  const bottomRef = useRef<HTMLDivElement>(null);
  const scrollerRef = useRef<HTMLDivElement>(null);
  const loadLock = useRef(false);
  const stickToBottom = useRef(true);
  const pendingFilesByClient = useRef<Map<string, PendingChatFile[]>>(new Map());
  const photoInputRef = useRef<HTMLInputElement>(null);
  const docInputRef = useRef<HTMLInputElement>(null);
  const attachMenuRef = useRef<HTMLDivElement>(null);

  const newClientId = () =>
    typeof crypto !== "undefined" && "randomUUID" in crypto
      ? crypto.randomUUID()
      : `tmp-${Date.now()}-${Math.random().toString(16).slice(2)}`;

  const scrollToBottomNow = useCallback(() => {
    requestAnimationFrame(() => {
      bottomRef.current?.scrollIntoView({ behavior: "auto", block: "end" });
    });
  }, []);

  const title = conversation
    ? conversation.isGroup
      ? conversation.title
      : `@${conversation.title}`
    : "Чат";
  const peerHref = conversation?.peer?.id
    ? `/app/u/${conversation.peer.id}`
    : null;

  useEffect(() => {
    if (!threadSearchOpen) return;
    const q = threadQuery.trim();
    if (q.length < 2) {
      setThreadHits([]);
      return;
    }
    const t = window.setTimeout(() => {
      void searchMessages({ query: q, conversationId, limit: 30 })
        .then(setThreadHits)
        .catch(() => setThreadHits([]));
    }, 280);
    return () => window.clearTimeout(t);
  }, [conversationId, threadQuery, threadSearchOpen]);

  useEffect(() => {
    setMessages(initialMessages);
    setHasMore(initialHasMore);
  }, [initialMessages, initialHasMore, conversationId]);

  useEffect(() => {
    const last = messages[messages.length - 1];
    if (!last || last.isPending) return;
    void markConversationRead(conversationId, last.id);
    // eslint-disable-next-line react-hooks/exhaustive-deps -- только хвост ленты
  }, [conversationId, messages[messages.length - 1]?.id]);

  useEffect(() => {
    if (!stickToBottom.current) return;
    scrollToBottomNow();
  }, [messages.length, scrollToBottomNow]);

  useEffect(() => {
    const supabase = createClient();
    const channel = supabase
      .channel(`chat_thread_${conversationId}`)
      .on("broadcast", { event: "message_enriched" }, (msg) => {
        const raw = msg.payload as Record<string, unknown> | null;
        if (!raw || typeof raw !== "object") return;
        const data = (asMap(raw.payload) ?? raw) as Record<string, unknown>;
        const parsed = parseMessageRow(data, currentUserId);
        if (!parsed) {
          const mid = String(asMap(data.message)?.id ?? "").trim();
          if (!mid) return;
          void getMessageEnriched(mid).then((m) => {
            if (!m) return;
            stickToBottom.current = true;
            setMessages((prev) => mergeMessage(prev, m));
          });
          return;
        }
        stickToBottom.current = true;
        setMessages((prev) => mergeMessage(prev, parsed));
      })
      .on("broadcast", { event: "peer_read" }, (msg) => {
        const raw = msg.payload as Record<string, unknown> | null;
        if (!raw) return;
        const data = (asMap(raw.payload) ?? raw) as Record<string, unknown>;
        const peerUserId = String(data.user_id ?? "").trim();
        if (!peerUserId || peerUserId === currentUserId) return;
        if (String(data.conversation_id ?? "") !== conversationId) return;
        const cursorId = String(data.last_read_message_id ?? "").trim();
        if (!cursorId) return;
        setMessages((prev) => {
          const idx = prev.findIndex((m) => m.id === cursorId);
          if (idx < 0) return prev;
          return prev.map((m, i) =>
            m.isMine && i <= idx ? { ...m, isRead: true } : m,
          );
        });
      })
      .subscribe();

    return () => {
      void supabase.removeChannel(channel);
    };
  }, [conversationId, currentUserId]);

  const loadOlder = useCallback(() => {
    if (loadLock.current || loadingOlder || !hasMore || messages.length === 0) return;
    loadLock.current = true;
    setLoadingOlder(true);
    stickToBottom.current = false;
    const oldest = messages[0];
    const el = scrollerRef.current;
    const prevHeight = el?.scrollHeight ?? 0;
    void (async () => {
      try {
        const older = await listMessagesPage(conversationId, {
          before: oldest.sentAt,
        });
        setMessages((prev) => {
          const ids = new Set(prev.map((m) => m.id));
          const next = older.filter((m) => !ids.has(m.id));
          return next.length ? [...next, ...prev] : prev;
        });
        setHasMore(older.length >= MESSAGES_PAGE_SIZE);
        requestAnimationFrame(() => {
          if (el) {
            el.scrollTop = el.scrollHeight - prevHeight;
          }
        });
      } catch {
        // retry later
      } finally {
        setLoadingOlder(false);
        loadLock.current = false;
      }
    })();
  }, [conversationId, hasMore, loadingOlder, messages]);

  const onScroll = () => {
    const el = scrollerRef.current;
    if (!el) return;
    stickToBottom.current = el.scrollHeight - el.scrollTop - el.clientHeight < 80;
    if (el.scrollTop < 80) loadOlder();
  };

  useEffect(() => {
    if (!attachMenu) return;
    const onPointer = (e: PointerEvent) => {
      const root = attachMenuRef.current;
      if (root && e.target instanceof Node && root.contains(e.target)) return;
      setAttachMenu(false);
    };
    document.addEventListener("pointerdown", onPointer);
    return () => document.removeEventListener("pointerdown", onPointer);
  }, [attachMenu]);

  const showToast = useCallback((msg: string) => {
    setToast(msg);
    window.setTimeout(() => setToast(null), 2800);
  }, []);

  useEffect(() => {
    return () => {
      for (const p of pending) {
        if (p.previewUrl) URL.revokeObjectURL(p.previewUrl);
      }
    };
    // только на unmount
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const onPickFiles = (list: FileList | null) => {
    if (!list || list.length === 0) return;
    const { ok, errors } = validateChatFiles(Array.from(list), pending.length);
    if (errors.length > 0) {
      showToast(attachErrorMessage(errors[0]!.reason));
    }
    if (ok.length > 0) {
      setPending((prev) => [...prev, ...ok].slice(0, CHAT_MAX_FILES_PER_MESSAGE));
    }
    setAttachMenu(false);
  };

  const removePending = (id: string) => {
    setPending((prev) => {
      const item = prev.find((p) => p.id === id);
      if (item?.previewUrl) URL.revokeObjectURL(item.previewUrl);
      return prev.filter((p) => p.id !== id);
    });
  };

  const confirmSent = useCallback(
    (clientMessageId: string, serverId: string, confirmed?: ChatMessage | null) => {
      setMessages((prev) => {
        if (confirmed) {
          return mergeMessage(prev, {
            ...confirmed,
            clientMessageId,
            isPending: false,
            sendFailed: false,
          });
        }
        return prev.map((m) =>
          m.clientMessageId === clientMessageId
            ? { ...m, id: serverId, isPending: false, sendFailed: false }
            : m,
        );
      });
      void markConversationRead(conversationId, serverId);
    },
    [conversationId],
  );

  const markFailed = useCallback((clientMessageId: string) => {
    setMessages((prev) =>
      prev.map((m) =>
        m.clientMessageId === clientMessageId
          ? { ...m, isPending: false, sendFailed: true }
          : m,
      ),
    );
  }, []);

  const deliverText = useCallback(
    (clientMessageId: string, body: string) => {
      void (async () => {
        try {
          const serverId = await sendTextMessage({
            conversationId,
            text: body,
            clientMessageId,
          });
          confirmSent(clientMessageId, serverId);
        } catch {
          markFailed(clientMessageId);
          showToast("Не доставлено — можно повторить");
        }
      })();
    },
    [confirmSent, conversationId, markFailed, showToast],
  );

  const deliverAttachments = useCallback(
    (clientMessageId: string, body: string, filesPending: PendingChatFile[]) => {
      void (async () => {
        try {
          const files = await prepareUploads(filesPending);
          const serverId = await sendAttachments({
            conversationId,
            files,
            caption: body || undefined,
            clientMessageId,
          });
          const confirmed = await getMessageEnriched(serverId);
          confirmSent(clientMessageId, serverId, confirmed);
          pendingFilesByClient.current.delete(clientMessageId);
        } catch {
          markFailed(clientMessageId);
          showToast("Не доставлено — можно повторить");
        }
      })();
    },
    [confirmSent, conversationId, markFailed, showToast],
  );

  const send = () => {
    const body = text.trim();
    if (!body && pending.length === 0) return;

    const clientMessageId = newClientId();
    const pendingSnapshot = pending;
    stickToBottom.current = true;

    if (pendingSnapshot.length > 0) {
      const allImages = pendingSnapshot.every((p) => isImageMime(p.mime));
      pendingFilesByClient.current.set(clientMessageId, pendingSnapshot);
      const optimistic: ChatMessage = {
        id: clientMessageId,
        clientMessageId,
        conversationId,
        kind: allImages ? "media" : "file",
        text: body,
        sentAt: new Date().toISOString(),
        isMine: true,
        isRead: false,
        isPending: true,
        sendFailed: false,
        postRef: null,
        attachments: pendingSnapshot.map((p) => ({
          id: p.id,
          bucket: "chat_media",
          path: p.filename,
          mime: p.mime,
          sizeBytes: p.sizeBytes,
          url: p.previewUrl,
        })),
        editedAt: null,
      };
      setMessages((prev) => [...prev, optimistic]);
      setText("");
      setPending([]);
      scrollToBottomNow();
      deliverAttachments(clientMessageId, body, pendingSnapshot);
      return;
    }

    const optimistic: ChatMessage = {
      id: clientMessageId,
      clientMessageId,
      conversationId,
      kind: "text",
      text: body,
      sentAt: new Date().toISOString(),
      isMine: true,
      isRead: false,
      isPending: true,
      sendFailed: false,
      postRef: null,
      attachments: [],
      editedAt: null,
    };
    setMessages((prev) => [...prev, optimistic]);
    setText("");
    scrollToBottomNow();
    deliverText(clientMessageId, body);
  };

  const retryFailed = (message: ChatMessage) => {
    const clientId = message.clientMessageId || message.id;
    setMessages((prev) =>
      prev.map((m) =>
        m.clientMessageId === clientId || m.id === message.id
          ? { ...m, isPending: true, sendFailed: false }
          : m,
      ),
    );
    stickToBottom.current = true;
    const files = pendingFilesByClient.current.get(clientId);
    if (files && files.length > 0) {
      deliverAttachments(clientId, message.text, files);
      return;
    }
    if (message.kind === "media" || message.kind === "file") {
      showToast("Файл уже нельзя повторить — выберите снова");
      setMessages((prev) => prev.filter((m) => m.clientMessageId !== clientId && m.id !== message.id));
      return;
    }
    deliverText(clientId, message.text);
  };

  const grouped = useMemo(() => {
    const out: { day: string; items: ChatMessage[] }[] = [];
    for (const m of messages) {
      const key = dayKey(m.sentAt);
      const last = out[out.length - 1];
      if (!last || last.day !== key) out.push({ day: key, items: [m] });
      else last.items.push(m);
    }
    return out;
  }, [messages]);

  return (
    <div className="flex h-[calc(100dvh-3rem-4.25rem)] flex-col bg-bg md:h-dvh">
      <header className="flex h-12 shrink-0 items-center gap-2 border-b border-line bg-surface/95 px-2 backdrop-blur-md">
        <button
          type="button"
          onClick={() => router.push("/app/chat")}
          className="flex h-10 w-10 items-center justify-center rounded-full text-ink hover:bg-bg"
          aria-label="Назад"
        >
          <ArrowLeft className="h-5 w-5" strokeWidth={2} />
        </button>
        {peerHref ? (
          <Link href={peerHref} className="flex min-w-0 flex-1 items-center gap-2.5">
            <div className="h-8 w-8 shrink-0 overflow-hidden rounded-full border border-line bg-mint">
              {conversation?.avatarUrl ? (
                // eslint-disable-next-line @next/next/no-img-element
                <img src={conversation.avatarUrl} alt="" className="h-full w-full object-cover" />
              ) : (
                <span className="flex h-full w-full items-center justify-center">
                  <User className="h-4 w-4 text-muted" />
                </span>
              )}
            </div>
            <span className="truncate text-[15px] font-bold text-ink">{title}</span>
          </Link>
        ) : (
          <span className="min-w-0 flex-1 truncate text-[15px] font-bold text-ink">{title}</span>
        )}
        <button
          type="button"
          onClick={() => setThreadSearchOpen((v) => !v)}
          className="flex h-10 w-10 items-center justify-center rounded-full text-ink hover:bg-bg"
          aria-label="Поиск"
        >
          <Search className="h-5 w-5" strokeWidth={2} />
        </button>
      </header>

      {threadSearchOpen ? (
        <div className="border-b border-line bg-surface px-3 py-2">
          <input
            value={threadQuery}
            onChange={(e) => setThreadQuery(e.target.value)}
            placeholder="Поиск в переписке…"
            className="h-10 w-full rounded-[12px] border border-line bg-bg px-3 text-[14px] text-ink outline-none focus:border-brand"
          />
          {threadHits.length > 0 ? (
            <ul className="mt-2 max-h-40 space-y-1 overflow-y-auto">
              {threadHits.map((h) => (
                <li key={h.messageId} className="rounded-[10px] bg-bg px-2.5 py-1.5 text-[13px] text-ink">
                  {h.text}
                </li>
              ))}
            </ul>
          ) : threadQuery.trim().length >= 2 ? (
            <p className="mt-2 text-center text-[12px] text-muted">Нет совпадений</p>
          ) : null}
        </div>
      ) : null}

      <div
        ref={scrollerRef}
        onScroll={onScroll}
        className="min-h-0 flex-1 overflow-y-auto px-3 py-3"
      >
        <div className="mx-auto flex w-full max-w-[640px] flex-col gap-3">
          {loadingOlder ? (
            <p className="py-2 text-center text-xs text-muted">Загрузка…</p>
          ) : null}
          {messages.length === 0 ? (
            <div className="py-16 text-center">
              <p className="text-sm font-semibold text-ink">Напишите первое сообщение</p>
              <p className="mt-1 text-sm text-muted">Диалог сохранится здесь</p>
            </div>
          ) : null}
          {grouped.map((g) => (
            <div key={g.day} className="flex flex-col gap-2.5">
              <div className="flex justify-center py-1">
                <span className="rounded-full bg-surface/90 px-3 py-1 text-[11px] font-semibold text-muted shadow-sm">
                  {formatMessageDayLabel(g.items[0]?.sentAt ?? "")}
                </span>
              </div>
              {g.items.map((m) => (
                <MessageBubble
                  key={m.clientMessageId || m.id}
                  message={m}
                  onRetry={m.sendFailed ? retryFailed : undefined}
                />
              ))}
            </div>
          ))}
          <div ref={bottomRef} />
        </div>
      </div>

      <div className="shrink-0 border-t border-line bg-surface px-3 py-2 pb-[max(0.5rem,env(safe-area-inset-bottom))]">
        {toast ? (
          <p className="mx-auto mb-2 max-w-[640px] rounded-[12px] bg-mint px-3 py-2 text-center text-[12px] font-semibold text-brand">
            {toast}
          </p>
        ) : null}
        {pending.length > 0 ? (
          <div className="mx-auto mb-2 flex w-full max-w-[640px] flex-col gap-2">
            <div className="flex gap-2 overflow-x-auto pb-1">
              {pending.map((p) => (
                <div
                  key={p.id}
                  className="relative h-16 w-16 shrink-0 overflow-hidden rounded-[12px] border border-line bg-bg"
                >
                  {p.previewUrl ? (
                    // eslint-disable-next-line @next/next/no-img-element
                    <img src={p.previewUrl} alt="" className="h-full w-full object-cover" />
                  ) : (
                    <div className="flex h-full w-full flex-col items-center justify-center gap-0.5 px-1">
                      <FileText className="h-5 w-5 text-muted" strokeWidth={1.75} />
                      <span className="w-full truncate text-center text-[9px] text-muted">
                        {p.filename}
                      </span>
                    </div>
                  )}
                  <button
                    type="button"
                    onClick={() => removePending(p.id)}
                    className="absolute right-0.5 top-0.5 flex h-5 w-5 items-center justify-center rounded-full bg-ink/70 text-on-media"
                    aria-label="Убрать"
                  >
                    <X className="h-3 w-3" strokeWidth={2.5} />
                  </button>
                </div>
              ))}
            </div>
            <button
              type="button"
              onClick={send}
              disabled={pending.length === 0}
              className="h-10 w-full rounded-[14px] bg-brand text-[14px] font-bold text-on-brand transition hover:opacity-90 disabled:opacity-50"
            >
              {`Отправить файл${pending.length > 1 ? `ы (${pending.length})` : ""}`}
            </button>
          </div>
        ) : null}
        <div className="relative mx-auto flex w-full max-w-[640px] items-end gap-2">
          <input
            ref={photoInputRef}
            type="file"
            accept={CHAT_PHOTO_ACCEPT}
            multiple
            className="hidden"
            onChange={(e) => {
              onPickFiles(e.target.files);
              e.target.value = "";
            }}
          />
          <input
            ref={docInputRef}
            type="file"
            accept={CHAT_DOCUMENT_ACCEPT}
            multiple
            className="hidden"
            onChange={(e) => {
              onPickFiles(e.target.files);
              e.target.value = "";
            }}
          />

          <div ref={attachMenuRef} className="relative shrink-0">
            <button
              type="button"
              onClick={(e) => {
                e.stopPropagation();
                setAttachMenu((v) => !v);
              }}
              disabled={pending.length >= CHAT_MAX_FILES_PER_MESSAGE}
              title="Прикрепить файл"
              className="flex h-11 w-11 items-center justify-center rounded-full bg-mint text-brand transition hover:bg-brand-soft disabled:opacity-40"
              aria-label="Прикрепить файл"
              aria-expanded={attachMenu}
            >
              <Plus className="h-6 w-6" strokeWidth={2.5} />
            </button>
            {attachMenu ? (
              <div
                className="absolute bottom-[3.25rem] left-0 z-30 min-w-[12.5rem] overflow-hidden rounded-[16px] border border-line bg-surface py-1 shadow-elevate-lg"
                role="menu"
              >
                <button
                  type="button"
                  role="menuitem"
                  className="flex w-full items-center gap-3 px-3.5 py-3 text-left text-[14px] font-semibold text-ink hover:bg-mint"
                  onClick={(e) => {
                    e.stopPropagation();
                    setAttachMenu(false);
                    photoInputRef.current?.click();
                  }}
                >
                  <span className="flex h-9 w-9 items-center justify-center rounded-full bg-mint text-brand">
                    <ImageIcon className="h-4 w-4" strokeWidth={2.25} />
                  </span>
                  Фото
                </button>
                <button
                  type="button"
                  role="menuitem"
                  className="flex w-full items-center gap-3 px-3.5 py-3 text-left text-[14px] font-semibold text-ink hover:bg-mint"
                  onClick={(e) => {
                    e.stopPropagation();
                    setAttachMenu(false);
                    docInputRef.current?.click();
                  }}
                >
                  <span className="flex h-9 w-9 items-center justify-center rounded-full bg-mint text-brand">
                    <Paperclip className="h-4 w-4" strokeWidth={2.25} />
                  </span>
                  Документ
                </button>
              </div>
            ) : null}
          </div>

          <textarea
            value={text}
            onChange={(e) => setText(e.target.value)}
            onKeyDown={(e) => {
              if (e.key === "Enter" && !e.shiftKey) {
                e.preventDefault();
                send();
              }
            }}
            rows={1}
            placeholder={pending.length > 0 ? "Подпись к файлу…" : "Сообщение"}
            className="max-h-32 min-h-11 flex-1 resize-none rounded-[18px] border border-line bg-bg px-4 py-2.5 text-[15px] text-ink outline-none placeholder:text-muted focus:border-brand"
          />
          <button
            type="button"
            onClick={send}
            disabled={!text.trim() && pending.length === 0}
            className="flex h-11 w-11 shrink-0 items-center justify-center rounded-full bg-brand text-on-brand transition hover:opacity-90 disabled:opacity-40"
            aria-label={pending.length > 0 ? "Отправить файл" : "Отправить"}
            title={pending.length > 0 ? "Отправить файл" : "Отправить"}
          >
            <SendHorizontal className="h-5 w-5" strokeWidth={2.25} />
          </button>
        </div>
      </div>
    </div>
  );
}
