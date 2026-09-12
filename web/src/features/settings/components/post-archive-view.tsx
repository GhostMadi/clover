"use client";

import { Archive } from "lucide-react";
import Link from "next/link";
import { useCallback, useEffect, useState, useTransition } from "react";
import {
  listArchivedPosts,
  restoreArchivedPost,
  type ArchivedPostItem,
} from "@/features/post/lib/posts-archive-api";
import { SettingsShell } from "@/features/settings/components/settings-shell";

export function PostArchiveView() {
  const [items, setItems] = useState<ArchivedPostItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [, startTransition] = useTransition();

  const load = useCallback(() => {
    setLoading(true);
    setError(null);
    void listArchivedPosts()
      .then(setItems)
      .catch((e: unknown) =>
        setError(e instanceof Error ? e.message : "Не удалось загрузить"),
      )
      .finally(() => setLoading(false));
  }, []);

  useEffect(() => {
    load();
  }, [load]);

  const restore = (item: ArchivedPostItem) => {
    startTransition(async () => {
      try {
        await restoreArchivedPost(item);
        setItems((prev) => prev.filter((x) => x.postId !== item.postId));
      } catch {
        /* ignore */
      }
    });
  };

  return (
    <SettingsShell title="Архив публикаций">
      <div className="px-4 py-4">
        {loading ? (
          <p className="py-16 text-center text-sm text-muted">Загрузка…</p>
        ) : error ? (
          <p className="py-8 text-center text-[13px] font-semibold text-destructive">{error}</p>
        ) : items.length === 0 ? (
          <div className="py-16 text-center">
            <Archive className="mx-auto h-8 w-8 text-muted" strokeWidth={1.5} />
            <p className="mt-3 text-sm font-semibold text-ink">Архив пуст</p>
          </div>
        ) : (
          <ul className="grid grid-cols-2 gap-3 sm:grid-cols-3">
            {items.map((item) => (
              <li
                key={item.postId}
                className="overflow-hidden rounded-[16px] border border-line bg-surface"
              >
                <Link href={`/app/posts/${item.postId}`} className="block">
                  <div className="relative aspect-square bg-mint">
                    {item.coverUrl ? (
                      // eslint-disable-next-line @next/next/no-img-element
                      <img src={item.coverUrl} alt="" className="h-full w-full object-cover" />
                    ) : (
                      <span className="flex h-full w-full items-center justify-center text-2xl">
                        {item.textEmoji || "📷"}
                      </span>
                    )}
                    {item.isEvent ? (
                      <span className="absolute left-2 top-2 rounded-full bg-surface/90 px-2 py-0.5 text-[10px] font-bold text-ink">
                        Ивент
                      </span>
                    ) : null}
                  </div>
                </Link>
                <div className="space-y-2 p-2.5">
                  <p className="truncate text-[13px] font-bold text-ink">
                    {item.title?.trim() || (item.isEvent ? "Ивент" : "Публикация")}
                  </p>
                  <button
                    type="button"
                    onClick={() => restore(item)}
                    className="h-9 w-full rounded-[10px] bg-brand text-[12px] font-bold text-on-brand"
                  >
                    Восстановить
                  </button>
                </div>
              </li>
            ))}
          </ul>
        )}
      </div>
    </SettingsShell>
  );
}
