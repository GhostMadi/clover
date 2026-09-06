"use client";

import { useCallback, useEffect, useRef, useState } from "react";
import { PostsGrid } from "@/features/post/components/posts-grid";
import { toGridPosts } from "@/features/post/lib/grid-post";
import { listMySavedPosts } from "@/features/post/lib/saved-posts-api";
import type { FeedPost } from "@/features/post/lib/parse-feed";
import { SettingsShell } from "@/features/settings/components/settings-shell";

const PAGE = 24;

export function SavedPostsView() {
  const [posts, setPosts] = useState<FeedPost[]>([]);
  const [loading, setLoading] = useState(true);
  const [loadingMore, setLoadingMore] = useState(false);
  const [done, setDone] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const sentinel = useRef<HTMLDivElement>(null);

  const load = useCallback(async (offset: number, append: boolean) => {
    if (append) setLoadingMore(true);
    else setLoading(true);
    try {
      const page = await listMySavedPosts(PAGE, offset);
      setPosts((prev) => (append ? [...prev, ...page] : page));
      if (page.length < PAGE) setDone(true);
      setError(null);
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : "Не удалось загрузить");
    } finally {
      setLoading(false);
      setLoadingMore(false);
    }
  }, []);

  useEffect(() => {
    void load(0, false);
  }, [load]);

  useEffect(() => {
    const el = sentinel.current;
    if (!el || done || loading) return;
    const io = new IntersectionObserver(
      (entries) => {
        if (entries[0]?.isIntersecting && !loadingMore) {
          void load(posts.length, true);
        }
      },
      { rootMargin: "200px" },
    );
    io.observe(el);
    return () => io.disconnect();
  }, [done, load, loading, loadingMore, posts.length]);

  return (
    <SettingsShell title="Сохранённые">
      <div className="px-3 py-4 sm:px-4">
        {error ? (
          <p className="mb-3 text-center text-[12px] font-semibold text-destructive">{error}</p>
        ) : null}
        {loading && posts.length === 0 ? (
          <p className="py-16 text-center text-sm text-muted">Загрузка…</p>
        ) : (
          <PostsGrid posts={toGridPosts(posts)} />
        )}
        <div ref={sentinel} className="h-8" />
        {loadingMore ? (
          <p className="pb-6 text-center text-[12px] text-muted">Ещё…</p>
        ) : null}
      </div>
    </SettingsShell>
  );
}
