"use client";

import { Folder } from "lucide-react";
import { useCallback, useEffect, useState, useTransition } from "react";
import {
  deleteCluster,
  listArchivedClusters,
  unarchiveCluster,
  type ClusterItem,
} from "@/features/profile/lib/clusters-api";
import { SettingsShell } from "@/features/settings/components/settings-shell";

export function ClusterArchiveView() {
  const [items, setItems] = useState<ClusterItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [, startTransition] = useTransition();

  const load = useCallback(() => {
    setLoading(true);
    void listArchivedClusters()
      .then(setItems)
      .catch((e: unknown) =>
        setError(e instanceof Error ? e.message : "Не удалось загрузить"),
      )
      .finally(() => setLoading(false));
  }, []);

  useEffect(() => {
    load();
  }, [load]);

  const restore = (c: ClusterItem) => {
    startTransition(async () => {
      try {
        await unarchiveCluster(c.id);
        setItems((prev) => prev.filter((x) => x.id !== c.id));
      } catch {
        /* ignore */
      }
    });
  };

  const remove = (c: ClusterItem) => {
    startTransition(async () => {
      try {
        await deleteCluster(c.id);
        setItems((prev) => prev.filter((x) => x.id !== c.id));
      } catch {
        /* ignore */
      }
    });
  };

  return (
    <SettingsShell title="Архив кластеров">
      <div className="px-4 py-4">
        {loading ? (
          <p className="py-16 text-center text-sm text-muted">Загрузка…</p>
        ) : error ? (
          <p className="py-8 text-center text-[13px] font-semibold text-destructive">{error}</p>
        ) : items.length === 0 ? (
          <div className="py-16 text-center">
            <Folder className="mx-auto h-8 w-8 text-muted" strokeWidth={1.5} />
            <p className="mt-3 text-sm font-semibold text-ink">Архив пуст</p>
          </div>
        ) : (
          <ul className="grid grid-cols-2 gap-3 sm:grid-cols-3">
            {items.map((c) => (
              <li
                key={c.id}
                className="overflow-hidden rounded-[16px] border border-line bg-surface"
              >
                <div className="relative aspect-square bg-mint">
                  {c.coverUrl ? (
                    // eslint-disable-next-line @next/next/no-img-element
                    <img src={c.coverUrl} alt="" className="h-full w-full object-cover" />
                  ) : (
                    <span className="flex h-full w-full items-center justify-center">
                      <Folder className="h-8 w-8 text-brand/40" />
                    </span>
                  )}
                </div>
                <div className="space-y-2 p-2.5">
                  <p className="truncate text-[13px] font-bold text-ink">{c.title}</p>
                  <button
                    type="button"
                    onClick={() => restore(c)}
                    className="h-9 w-full rounded-[10px] bg-brand text-[12px] font-bold text-on-brand"
                  >
                    Восстановить
                  </button>
                  <button
                    type="button"
                    onClick={() => remove(c)}
                    className="h-9 w-full rounded-[10px] border border-line text-[12px] font-semibold text-destructive"
                  >
                    Удалить
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
