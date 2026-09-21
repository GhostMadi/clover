"use client";

import { X } from "lucide-react";
import Link from "next/link";
import { useEffect, useState } from "react";
import { EventFeedCard } from "@/features/feed/components/event-feed-card";
import { getPostsEnrichedClient } from "@/features/post/lib/get-post-client";
import type { FeedPost } from "@/features/post/lib/parse-feed";
import { createClient } from "@/lib/supabase/client";

type MapMarkerPostSheetProps = {
  /** Один или несколько постов стопки (как Flutter MapMarkerGroupSheet). */
  postIds: string[];
  onClose: () => void;
};

/** Шторка маркера / стопки — лента карточек. */
export function MapMarkerPostSheet({ postIds, onClose }: MapMarkerPostSheetProps) {
  const ids = [...new Set(postIds.map((x) => x.trim()).filter(Boolean))];
  const [posts, setPosts] = useState<FeedPost[]>([]);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  const [currentUserId, setCurrentUserId] = useState<string | null>(null);
  const [followByAuthor, setFollowByAuthor] = useState<Record<string, boolean>>({});
  const [toggledAuthors, setToggledAuthors] = useState<Set<string>>(new Set());

  useEffect(() => {
    let cancelled = false;
    setLoading(true);
    setError(null);
    setPosts([]);

    (async () => {
      const supabase = createClient();
      const {
        data: { session },
      } = await supabase.auth.getSession();
      if (!cancelled) setCurrentUserId(session?.user.id ?? null);

      if (ids.length === 0) {
        if (!cancelled) {
          setError("У маркера нет поста");
          setLoading(false);
        }
        return;
      }

      try {
        const items = await getPostsEnrichedClient(ids);
        if (cancelled) return;
        if (items.length === 0) {
          setError("Пост не найден");
          return;
        }
        setPosts(items);
        const follow: Record<string, boolean> = {};
        for (const p of items) {
          follow[p.userId] = p.myFollowingAuthor;
        }
        setFollowByAuthor(follow);
        setToggledAuthors(new Set());
      } catch {
        if (!cancelled) setError("Не удалось загрузить пост");
      } finally {
        if (!cancelled) setLoading(false);
      }
    })();

    return () => {
      cancelled = true;
    };
    // ids joined — stable when same set
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [ids.join(",")]);

  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape") onClose();
    };
    document.addEventListener("keydown", onKey);
    const prev = document.body.style.overflow;
    document.body.style.overflow = "hidden";
    return () => {
      document.removeEventListener("keydown", onKey);
      document.body.style.overflow = prev;
    };
  }, [onClose]);

  const title =
    posts.length > 1 ? `События · ${posts.length}` : "Событие";
  const single = posts.length === 1 ? posts[0]! : null;

  return (
    <div className="fixed inset-0 z-[70] flex items-end justify-center sm:items-center sm:p-4">
      <button
        type="button"
        aria-label="Закрыть"
        className="absolute inset-0 bg-ink/35 backdrop-blur-[2px]"
        onClick={onClose}
      />

      <div
        role="dialog"
        aria-modal="true"
        className="relative flex max-h-[min(86dvh,900px)] w-full max-w-[480px] flex-col overflow-hidden rounded-t-2xl border border-line bg-surface shadow-elevate-lg sm:rounded-2xl"
      >
        <div className="flex shrink-0 items-center justify-between gap-2 border-b border-line px-3 py-2.5">
          <button
            type="button"
            onClick={onClose}
            className="flex h-10 w-10 items-center justify-center rounded-full bg-mint text-brand transition hover:bg-brand/20"
            aria-label="Назад"
          >
            <X className="h-5 w-5" strokeWidth={2.25} />
          </button>
          <p className="min-w-0 flex-1 truncate text-center text-[15px] font-bold text-ink">
            {title}
          </p>
          {single ? (
            <Link
              href={`/app/posts/${single.id}`}
              onClick={onClose}
              className="px-2 text-[13px] font-semibold text-brand"
            >
              Открыть
            </Link>
          ) : (
            <span className="w-16" />
          )}
        </div>

        <div className="min-h-0 flex-1 overflow-y-auto overscroll-contain">
          {loading ? (
            <div className="flex flex-col gap-3 p-5">
              <div className="h-11 w-11 animate-pulse rounded-full bg-bg" />
              <div className="aspect-[4/3] w-full animate-pulse rounded-xl bg-bg" />
              <div className="h-4 w-2/3 animate-pulse rounded bg-bg" />
              <div className="h-3 w-full animate-pulse rounded bg-bg" />
            </div>
          ) : error ? (
            <div className="px-6 py-16 text-center">
              <p className="text-sm font-semibold text-ink">{error}</p>
              <button
                type="button"
                onClick={onClose}
                className="mt-4 text-sm font-semibold text-brand"
              >
                Закрыть
              </button>
            </div>
          ) : (
            <div className="flex flex-col gap-3 px-2 py-3 sm:px-3">
              {posts.map((post) => (
                <EventFeedCard
                  key={post.id}
                  post={post}
                  currentUserId={currentUserId}
                  followingAuthor={followByAuthor[post.userId] ?? post.myFollowingAuthor}
                  followToggledInSession={toggledAuthors.has(post.userId)}
                  onFollowChange={(authorId, next) => {
                    setFollowByAuthor((prev) => ({ ...prev, [authorId]: next }));
                    setToggledAuthors((prev) => new Set(prev).add(authorId));
                  }}
                />
              ))}
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
