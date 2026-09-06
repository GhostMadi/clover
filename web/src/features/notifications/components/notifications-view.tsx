"use client";

import { Bell, User } from "lucide-react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { useCallback, useEffect, useRef, useState, useTransition } from "react";
import { followUser, unfollowUser } from "@/features/catalog/lib/social-api";
import {
  listNotificationsPage,
  markNotificationsRead,
} from "@/features/notifications/lib/notifications-api";
import {
  formatRelativeTime,
  notificationMessage,
  type AppNotification,
} from "@/features/notifications/lib/notifications-model";

type NotificationsViewProps = {
  initialItems: AppNotification[];
  initialHasMore: boolean;
};

function hrefFor(item: AppNotification): string | null {
  if (item.showFollowButton) return `/app/u/${item.actor.id}`;
  if (item.postId) return `/app/posts/${item.postId}`;
  if (item.actor.id) return `/app/u/${item.actor.id}`;
  return null;
}

/** Лента уведомлений + пагинация скролла. */
export function NotificationsView({
  initialItems,
  initialHasMore,
}: NotificationsViewProps) {
  const router = useRouter();
  const [items, setItems] = useState(initialItems);
  const [hasMore, setHasMore] = useState(initialHasMore);
  const [loadingMore, setLoadingMore] = useState(false);
  const loadLock = useRef(false);
  const sentinelRef = useRef<HTMLDivElement>(null);
  const [, startTransition] = useTransition();

  useEffect(() => {
    setItems(initialItems);
    setHasMore(initialHasMore);
  }, [initialItems, initialHasMore]);

  useEffect(() => {
    void markNotificationsRead().then(() => {
      setItems((prev) => prev.map((i) => ({ ...i, isUnread: false })));
    });
  }, []);

  const loadMore = useCallback(() => {
    if (loadLock.current || loadingMore || !hasMore || items.length === 0) return;
    loadLock.current = true;
    setLoadingMore(true);
    const cursor = items[items.length - 1];
    startTransition(async () => {
      try {
        const page = await listNotificationsPage({
          cursor: { createdAt: cursor.createdAt, id: cursor.id },
        });
        setItems((prev) => {
          const ids = new Set(prev.map((p) => p.id));
          const next = page.items.filter((p) => !ids.has(p.id));
          return next.length ? [...prev, ...next] : prev;
        });
        setHasMore(page.hasMore && page.items.length > 0);
      } catch {
        // retry on next scroll
      } finally {
        setLoadingMore(false);
        loadLock.current = false;
      }
    });
  }, [hasMore, items, loadingMore, startTransition]);

  useEffect(() => {
    const node = sentinelRef.current;
    if (!node || !hasMore) return;
    const io = new IntersectionObserver(
      (entries) => {
        if (entries.some((e) => e.isIntersecting)) loadMore();
      },
      { rootMargin: "280px 0px" },
    );
    io.observe(node);
    return () => io.disconnect();
  }, [hasMore, loadMore]);

  const toggleFollow = (item: AppNotification) => {
    const next = !item.isFollowingActor;
    setItems((prev) =>
      prev.map((n) => (n.id === item.id ? { ...n, isFollowingActor: next } : n)),
    );
    startTransition(async () => {
      try {
        if (next) await followUser(item.actor.id);
        else await unfollowUser(item.actor.id);
      } catch {
        setItems((prev) =>
          prev.map((n) =>
            n.id === item.id ? { ...n, isFollowingActor: !next } : n,
          ),
        );
      }
    });
  };

  return (
    <div className="min-h-[calc(100dvh-3rem-4.25rem)] bg-bg md:min-h-dvh">
      <div className="mx-auto w-full max-w-[520px]">
        <header className="sticky top-0 z-10 flex h-12 items-center gap-2 border-b border-line bg-surface/95 px-4 backdrop-blur-md">
          <Bell className="h-5 w-5 text-brand" strokeWidth={2} />
          <h1 className="text-[16px] font-bold text-ink">Уведомления</h1>
        </header>

        {items.length === 0 ? (
          <div className="px-6 py-20 text-center">
            <p className="text-sm font-semibold text-ink">Пока тихо</p>
            <p className="mt-1 text-sm text-muted">Здесь появятся реакции, подписки и записи</p>
          </div>
        ) : (
          <ul className="divide-y divide-line">
            {items.map((item) => {
              const href = hrefFor(item);
              return (
                <li key={item.id}>
                  <div
                    className={`flex gap-3 px-4 py-3 ${item.isUnread ? "bg-mint/40" : "bg-surface"}`}
                  >
                    <button
                      type="button"
                      className="h-11 w-11 shrink-0 overflow-hidden rounded-full border border-line bg-bg"
                      onClick={() => router.push(`/app/u/${item.actor.id}`)}
                    >
                      {item.actor.avatarUrl ? (
                        // eslint-disable-next-line @next/next/no-img-element
                        <img
                          src={item.actor.avatarUrl}
                          alt=""
                          className="h-full w-full object-cover"
                        />
                      ) : (
                        <span className="flex h-full w-full items-center justify-center">
                          <User className="h-5 w-5 text-muted" strokeWidth={1.5} />
                        </span>
                      )}
                    </button>

                    <button
                      type="button"
                      className="min-w-0 flex-1 text-left"
                      onClick={() => {
                        if (href) router.push(href);
                      }}
                    >
                      <p className="text-[14px] leading-snug text-ink">
                        {notificationMessage(item)}
                      </p>
                      {item.commentPreview ? (
                        <p className="mt-1 line-clamp-2 text-[13px] text-muted">
                          {item.commentPreview}
                        </p>
                      ) : null}
                      <p className="mt-1 text-[12px] text-muted">
                        {formatRelativeTime(item.createdAt)}
                      </p>
                    </button>

                    {item.showFollowButton ? (
                      item.isFollowingActor ? (
                        <button
                          type="button"
                          onClick={() => toggleFollow(item)}
                          className="h-9 shrink-0 self-center rounded-[12px] border border-line px-3 text-[12px] font-bold text-ink"
                        >
                          Отписаться
                        </button>
                      ) : (
                        <button
                          type="button"
                          onClick={() => toggleFollow(item)}
                          className="h-9 shrink-0 self-center rounded-[12px] bg-brand px-3 text-[12px] font-bold text-on-brand"
                        >
                          Подписаться
                        </button>
                      )
                    ) : item.postPreviewUrl ? (
                      <Link
                        href={item.postId ? `/app/posts/${item.postId}` : "#"}
                        className="h-12 w-12 shrink-0 self-center overflow-hidden rounded-lg bg-bg"
                      >
                        {/* eslint-disable-next-line @next/next/no-img-element */}
                        <img
                          src={item.postPreviewUrl}
                          alt=""
                          className="h-full w-full object-cover"
                        />
                      </Link>
                    ) : null}
                  </div>
                </li>
              );
            })}
          </ul>
        )}

        <div ref={sentinelRef} className="h-8" aria-hidden />
        {loadingMore ? (
          <p className="py-4 text-center text-sm text-muted">Загрузка…</p>
        ) : null}
        {!hasMore && items.length > 0 ? (
          <p className="py-4 text-center text-xs text-muted">Это всё за 30 дней</p>
        ) : null}
      </div>
    </div>
  );
}
