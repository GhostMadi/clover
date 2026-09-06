"use client";

import { Folder, MoreHorizontal, X } from "lucide-react";
import { useEffect, useState, useTransition } from "react";
import {
  getPostClusterId,
  listUserClusters,
  setPostCluster,
  type ClusterItem,
} from "@/features/profile/lib/clusters-api";

type PostClusterMenuProps = {
  postId: string;
  ownerId: string;
};

/** Меню автора: привязать / отвязать пост от кластера. */
export function PostClusterMenu({ postId, ownerId }: PostClusterMenuProps) {
  const [open, setOpen] = useState(false);
  const [picker, setPicker] = useState(false);
  const [clusters, setClusters] = useState<ClusterItem[]>([]);
  const [clusterId, setClusterId] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [, startTransition] = useTransition();

  useEffect(() => {
    void getPostClusterId(postId)
      .then(setClusterId)
      .catch(() => setClusterId(null));
  }, [postId]);

  const openPicker = () => {
    setOpen(false);
    setError(null);
    startTransition(async () => {
      try {
        const list = await listUserClusters(ownerId);
        setClusters(list);
        if (list.length === 0) {
          setError("Сначала создайте кластер на профиле");
          setPicker(true);
          return;
        }
        setPicker(true);
      } catch (e: unknown) {
        setError(e instanceof Error ? e.message : "Ошибка");
        setPicker(true);
      }
    });
  };

  const attach = (id: string) => {
    startTransition(async () => {
      try {
        await setPostCluster(postId, id);
        setClusterId(id);
        setPicker(false);
      } catch (e: unknown) {
        setError(e instanceof Error ? e.message : "Не удалось привязать");
      }
    });
  };

  const detach = () => {
    setOpen(false);
    startTransition(async () => {
      try {
        await setPostCluster(postId, null);
        setClusterId(null);
      } catch {
        /* ignore */
      }
    });
  };

  return (
    <>
      <div className="relative">
        <button
          type="button"
          onClick={() => setOpen((v) => !v)}
          className="flex h-10 w-10 items-center justify-center rounded-full text-ink hover:bg-bg"
          aria-label="Ещё"
        >
          <MoreHorizontal className="h-5 w-5" strokeWidth={2} />
        </button>
        {open ? (
          <div className="absolute right-0 top-11 z-20 min-w-[200px] overflow-hidden rounded-[14px] border border-line bg-surface shadow-lg">
            <button
              type="button"
              onClick={openPicker}
              className="flex w-full items-center gap-2 px-3 py-2.5 text-left text-[13px] font-semibold text-ink hover:bg-bg"
            >
              <Folder className="h-4 w-4 text-brand" />
              Привязать к кластеру
            </button>
            {clusterId ? (
              <button
                type="button"
                onClick={detach}
                className="block w-full px-3 py-2.5 text-left text-[13px] font-semibold text-muted hover:bg-bg"
              >
                Отвязать от кластера
              </button>
            ) : null}
          </div>
        ) : null}
      </div>

      {picker ? (
        <div className="fixed inset-0 z-50 flex items-end justify-center sm:items-center">
          <button
            type="button"
            className="absolute inset-0 bg-ink/40"
            aria-label="Закрыть"
            onClick={() => setPicker(false)}
          />
          <div className="relative z-10 max-h-[70dvh] w-full max-w-md overflow-y-auto rounded-t-[20px] bg-surface shadow-xl sm:rounded-[20px]">
            <div className="sticky top-0 flex items-center gap-2 border-b border-line bg-surface px-3 py-3">
              <h2 className="min-w-0 flex-1 text-[16px] font-bold text-ink">Кластер</h2>
              <button
                type="button"
                onClick={() => setPicker(false)}
                className="flex h-9 w-9 items-center justify-center rounded-full hover:bg-bg"
              >
                <X className="h-5 w-5" />
              </button>
            </div>
            {error ? (
              <p className="px-4 py-6 text-center text-[13px] font-semibold text-muted">{error}</p>
            ) : (
              <ul className="p-2">
                {clusters.map((c) => (
                  <li key={c.id}>
                    <button
                      type="button"
                      onClick={() => attach(c.id)}
                      className={`flex w-full items-center gap-3 rounded-[14px] px-3 py-3 text-left hover:bg-bg ${
                        clusterId === c.id ? "bg-mint" : ""
                      }`}
                    >
                      <span className="h-12 w-12 shrink-0 overflow-hidden rounded-[12px] bg-mint">
                        {c.coverUrl ? (
                          // eslint-disable-next-line @next/next/no-img-element
                          <img src={c.coverUrl} alt="" className="h-full w-full object-cover" />
                        ) : (
                          <span className="flex h-full w-full items-center justify-center">
                            <Folder className="h-5 w-5 text-brand" />
                          </span>
                        )}
                      </span>
                      <span className="min-w-0 flex-1">
                        <span className="block truncate text-[14px] font-bold text-ink">{c.title}</span>
                        <span className="text-[12px] text-muted">{c.postsCount} фото</span>
                      </span>
                    </button>
                  </li>
                ))}
              </ul>
            )}
          </div>
        </div>
      ) : null}
    </>
  );
}
