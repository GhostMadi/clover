"use client";

import { Check, CheckCheck, MessagesSquare, Search, User, Users } from "lucide-react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { useCallback, useEffect, useMemo, useState, useTransition } from "react";
import {
  createGroupChat,
  listConversationsPage,
  searchMessages,
  type MessageSearchHit,
} from "@/features/chat/lib/chat-api";
import {
  formatChatListTime,
  type ChatConversation,
} from "@/features/chat/lib/chat-model";
import { CHAT_UNREAD_CHANGED } from "@/features/chat/lib/chat-unread";

type ChatsListViewProps = {
  initialItems: ChatConversation[];
};

/** Список диалогов + FTS поиск + создание группы. */
export function ChatsListView({ initialItems }: ChatsListViewProps) {
  const router = useRouter();
  const [items, setItems] = useState(initialItems);
  const [query, setQuery] = useState("");
  const [scope, setScope] = useState<"chats" | "messages">("chats");
  const [hits, setHits] = useState<MessageSearchHit[]>([]);
  const [searching, setSearching] = useState(false);
  const [groupOpen, setGroupOpen] = useState(false);
  const [groupTitle, setGroupTitle] = useState("");
  const [pickIds, setPickIds] = useState<Set<string>>(new Set());
  const [friends, setFriends] = useState<{ id: string; name: string }[]>([]);
  const [error, setError] = useState<string | null>(null);
  const [, startTransition] = useTransition();

  const refreshList = useCallback(() => {
    void listConversationsPage()
      .then(setItems)
      .catch(() => {
        /* keep current */
      });
  }, []);

  useEffect(() => {
    setItems(initialItems);
  }, [initialItems]);

  useEffect(() => {
    refreshList();
    const onUnread = () => refreshList();
    const onVisible = () => {
      if (document.visibilityState === "visible") refreshList();
    };
    window.addEventListener(CHAT_UNREAD_CHANGED, onUnread);
    document.addEventListener("visibilitychange", onVisible);
    window.addEventListener("focus", onUnread);
    return () => {
      window.removeEventListener(CHAT_UNREAD_CHANGED, onUnread);
      document.removeEventListener("visibilitychange", onVisible);
      window.removeEventListener("focus", onUnread);
    };
  }, [refreshList]);

  const filtered = useMemo(() => {
    const q = query.trim().toLowerCase();
    if (!q || scope !== "chats") return items;
    return items.filter((c) => {
      const name = c.title.toLowerCase();
      const preview = c.lastMessageText.toLowerCase();
      return name.includes(q) || preview.includes(q);
    });
  }, [items, query, scope]);

  useEffect(() => {
    if (scope !== "messages") return;
    const q = query.trim();
    if (q.length < 2) {
      setHits([]);
      return;
    }
    const t = window.setTimeout(() => {
      setSearching(true);
      void searchMessages({ query: q })
        .then(setHits)
        .catch(() => setHits([]))
        .finally(() => setSearching(false));
    }, 280);
    return () => window.clearTimeout(t);
  }, [query, scope]);

  const openGroupSheet = () => {
    setGroupOpen(true);
    setError(null);
    const fromChats = items
      .filter((c) => c.peer)
      .map((c) => ({ id: c.peer!.id, name: c.peer!.username || c.title }));
    const uniq = new Map(fromChats.map((f) => [f.id, f]));
    setFriends([...uniq.values()]);
  };

  const createGroup = () => {
    startTransition(async () => {
      try {
        const id = await createGroupChat({
          title: groupTitle,
          userIds: [...pickIds],
        });
        router.push(`/app/chat/${id}`);
      } catch (e: unknown) {
        setError(e instanceof Error ? e.message : "Не удалось создать");
      }
    });
  };

  return (
    <div className="min-h-[calc(100dvh-3rem-4.25rem)] bg-surface md:min-h-dvh">
      <div className="mx-auto w-full max-w-[640px]">
        <header className="sticky top-0 z-10 border-b border-line bg-surface/95 px-4 pb-3 pt-3 backdrop-blur-md">
          <div className="flex items-center gap-2">
            <h1 className="min-w-0 flex-1 font-display text-[20px] font-semibold tracking-tight text-ink">
              Сообщения
            </h1>
            <button
              type="button"
              onClick={openGroupSheet}
              className="flex h-10 w-10 items-center justify-center rounded-full bg-mint text-brand"
              title="Новая группа"
              aria-label="Новая группа"
            >
              <Users className="h-5 w-5" strokeWidth={2} />
            </button>
          </div>
          <label className="mt-3 flex h-11 items-center gap-2 rounded-[14px] border border-line bg-bg px-3">
            <Search className="h-4 w-4 shrink-0 text-muted" strokeWidth={2} />
            <input
              value={query}
              onChange={(e) => setQuery(e.target.value)}
              placeholder={scope === "chats" ? "Поиск по чатам" : "Поиск в сообщениях"}
              className="min-w-0 flex-1 bg-transparent text-[14px] text-ink outline-none placeholder:text-muted"
            />
          </label>
          <div className="mt-2 grid grid-cols-2 gap-1 rounded-[12px] bg-bg p-1">
            <button
              type="button"
              onClick={() => setScope("chats")}
              className={`rounded-[10px] py-1.5 text-[12px] font-bold ${
                scope === "chats" ? "bg-surface text-ink shadow-sm" : "text-muted"
              }`}
            >
              Чаты
            </button>
            <button
              type="button"
              onClick={() => setScope("messages")}
              className={`rounded-[10px] py-1.5 text-[12px] font-bold ${
                scope === "messages" ? "bg-surface text-ink shadow-sm" : "text-muted"
              }`}
            >
              В сообщениях
            </button>
          </div>
        </header>

        {scope === "messages" ? (
          searching ? (
            <p className="px-4 py-10 text-center text-sm text-muted">Ищем…</p>
          ) : hits.length === 0 ? (
            <div className="px-6 py-16 text-center">
              <MessagesSquare className="mx-auto h-8 w-8 text-muted" strokeWidth={1.5} />
              <p className="mt-3 text-sm font-semibold text-ink">
                {query.trim().length < 2 ? "Введите от 2 символов" : "Ничего не найдено"}
              </p>
            </div>
          ) : (
            <ul className="divide-y divide-line">
              {hits.map((h) => (
                <li key={h.messageId}>
                  <Link
                    href={`/app/chat/${h.conversationId}`}
                    className="block px-4 py-3 transition hover:bg-mint/40"
                  >
                    <p className="text-[13px] font-bold text-brand">
                      @{h.senderName || "user"}
                    </p>
                    <p className="mt-0.5 line-clamp-2 text-[14px] text-ink">{h.text}</p>
                  </Link>
                </li>
              ))}
            </ul>
          )
        ) : filtered.length === 0 ? (
          <div className="px-6 py-20 text-center">
            <p className="text-sm font-semibold text-ink">
              {items.length === 0 ? "Пока нет чатов" : "Чаты не найдены"}
            </p>
            <p className="mt-1 text-sm text-muted">
              {items.length === 0
                ? "Начните переписку с чужого профиля или создайте группу"
                : "Попробуйте другой запрос"}
            </p>
          </div>
        ) : (
          <ul>
            {filtered.map((chat) => {
              const unread = chat.unreadCount > 0;
              return (
                <li key={chat.id}>
                  <Link
                    href={`/app/chat/${chat.id}`}
                    className={`flex gap-3 px-4 py-3 transition hover:bg-mint/50 ${
                      unread ? "bg-mint/35" : "bg-surface"
                    }`}
                  >
                    <div className="h-[52px] w-[52px] shrink-0 overflow-hidden rounded-full border border-line bg-mint">
                      {chat.avatarUrl ? (
                        // eslint-disable-next-line @next/next/no-img-element
                        <img
                          src={chat.avatarUrl}
                          alt=""
                          className="h-full w-full object-cover"
                        />
                      ) : (
                        <span className="flex h-full w-full items-center justify-center">
                          {chat.isGroup ? (
                            <Users className="h-6 w-6 text-muted" strokeWidth={1.5} />
                          ) : (
                            <User className="h-6 w-6 text-muted" strokeWidth={1.5} />
                          )}
                        </span>
                      )}
                    </div>
                    <div className="min-w-0 flex-1">
                      <div className="flex items-baseline gap-2">
                        <p
                          className={`min-w-0 flex-1 truncate text-[16px] ${
                            unread ? "font-bold text-ink" : "font-semibold text-ink"
                          }`}
                        >
                          {chat.isGroup ? chat.title : `@${chat.title}`}
                        </p>
                        <span
                          className={`shrink-0 text-[12px] ${
                            unread
                              ? "font-semibold text-brand"
                              : "font-medium text-muted"
                          }`}
                        >
                          {formatChatListTime(chat.lastMessageAt)}
                        </span>
                      </div>
                      <div className="mt-0.5 flex items-center gap-1.5">
                        {chat.isLastMessageMine ? (
                          chat.isRead ? (
                            <CheckCheck className="h-3.5 w-3.5 shrink-0 text-brand" />
                          ) : (
                            <Check className="h-3.5 w-3.5 shrink-0 text-muted" />
                          )
                        ) : null}
                        <p
                          className={`min-w-0 flex-1 truncate text-[13px] ${
                            unread ? "font-semibold text-ink" : "text-muted"
                          }`}
                        >
                          {chat.lastMessageText}
                        </p>
                        {unread ? (
                          <span className="flex h-5 min-w-5 items-center justify-center rounded-full bg-brand px-1.5 text-[11px] font-bold text-on-brand">
                            {chat.unreadCount > 99 ? "99+" : chat.unreadCount}
                          </span>
                        ) : null}
                      </div>
                    </div>
                  </Link>
                </li>
              );
            })}
          </ul>
        )}
      </div>

      {groupOpen ? (
        <div className="fixed inset-0 z-50 flex items-end justify-center sm:items-center">
          <button
            type="button"
            className="absolute inset-0 bg-ink/40"
            aria-label="Закрыть"
            onClick={() => setGroupOpen(false)}
          />
          <div className="relative z-10 w-full max-w-md rounded-t-[20px] bg-surface shadow-xl sm:rounded-[20px]">
            <div className="border-b border-line px-4 py-3">
              <h2 className="text-[16px] font-bold text-ink">Новая группа</h2>
            </div>
            <div className="space-y-3 px-4 py-4">
              <input
                value={groupTitle}
                onChange={(e) => setGroupTitle(e.target.value)}
                placeholder="Название"
                className="h-11 w-full rounded-[14px] border border-line bg-bg px-3 text-[14px] text-ink outline-none focus:border-brand"
              />
              <p className="text-[12px] font-semibold text-muted">Участники из недавних чатов</p>
              <ul className="max-h-48 space-y-1 overflow-y-auto">
                {friends.length === 0 ? (
                  <li className="py-4 text-center text-[13px] text-muted">
                    Сначала напишите кому-нибудь в DM
                  </li>
                ) : (
                  friends.map((f) => {
                    const on = pickIds.has(f.id);
                    return (
                      <li key={f.id}>
                        <button
                          type="button"
                          onClick={() =>
                            setPickIds((prev) => {
                              const next = new Set(prev);
                              if (next.has(f.id)) next.delete(f.id);
                              else next.add(f.id);
                              return next;
                            })
                          }
                          className={`flex w-full items-center justify-between rounded-[12px] px-3 py-2 text-left text-[14px] font-semibold ${
                            on ? "bg-mint text-brand" : "hover:bg-bg text-ink"
                          }`}
                        >
                          @{f.name}
                          {on ? "✓" : ""}
                        </button>
                      </li>
                    );
                  })
                )}
              </ul>
              {error ? (
                <p className="text-[12px] font-semibold text-destructive">{error}</p>
              ) : null}
            </div>
            <div className="flex gap-2 border-t border-line px-4 py-3">
              <button
                type="button"
                onClick={() => setGroupOpen(false)}
                className="h-11 flex-1 rounded-[14px] border border-line text-sm font-semibold"
              >
                Отмена
              </button>
              <button
                type="button"
                onClick={createGroup}
                disabled={!groupTitle.trim() || pickIds.size === 0}
                className="h-11 flex-1 rounded-[14px] bg-brand text-sm font-bold text-on-brand disabled:opacity-40"
              >
                Создать
              </button>
            </div>
          </div>
        </div>
      ) : null}
    </div>
  );
}
