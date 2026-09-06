"use client";

import { Folder, MoreHorizontal, X } from "lucide-react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { useEffect, useRef, useState, useTransition } from "react";
import {
  archiveCluster,
  deleteCluster,
  type ClusterItem,
} from "@/features/profile/lib/clusters-api";

type ProfileClustersProps = {
  initial: ClusterItem[];
  canManage: boolean;
  selectedId: string | null;
  onSelect: (id: string | null) => void;
  onChanged?: (items: ClusterItem[]) => void;
};

/** Полоска кластеров: тап = фильтр сетки; ⋯ = архив/удалить. */
export function ProfileClusters({
  initial,
  canManage,
  selectedId,
  onSelect,
  onChanged,
}: ProfileClustersProps) {
  const router = useRouter();
  const [items, setItems] = useState(initial);
  const [menuId, setMenuId] = useState<string | null>(null);
  const [confirmDelete, setConfirmDelete] = useState<ClusterItem | null>(null);
  const [, startTransition] = useTransition();
  const menuRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    setItems(initial);
  }, [initial]);

  useEffect(() => {
    if (!menuId) return;
    const onDoc = (e: MouseEvent) => {
      if (!menuRef.current?.contains(e.target as Node)) setMenuId(null);
    };
    document.addEventListener("mousedown", onDoc);
    return () => document.removeEventListener("mousedown", onDoc);
  }, [menuId]);

  if (!canManage && items.length === 0) return null;

  const applyItems = (next: ClusterItem[]) => {
    setItems(next);
    onChanged?.(next);
  };

  const onArchive = (c: ClusterItem) => {
    setMenuId(null);
    startTransition(async () => {
      try {
        await archiveCluster(c.id);
        applyItems(items.filter((x) => x.id !== c.id));
        if (selectedId === c.id) onSelect(null);
        router.refresh();
      } catch {
        /* ignore */
      }
    });
  };

  const onDelete = (c: ClusterItem) => {
    setConfirmDelete(null);
    startTransition(async () => {
      try {
        await deleteCluster(c.id);
        applyItems(items.filter((x) => x.id !== c.id));
        if (selectedId === c.id) onSelect(null);
        router.refresh();
      } catch {
        /* ignore */
      }
    });
  };

  return (
    <div className="mt-5 border-t border-line px-4 pt-4 sm:mt-6 sm:px-5 sm:pt-5 lg:px-6">
      <div className="mb-3">
        <p className="text-sm font-semibold text-ink sm:text-base">Коллекции</p>
      </div>

      {items.length === 0 ? (
        <div className="rounded-[16px] border border-dashed border-line bg-bg px-4 py-6 text-center">
          <Folder className="mx-auto h-8 w-8 text-muted" strokeWidth={1.5} />
          <p className="mt-2 text-[13px] font-semibold text-ink">Пока нет коллекций</p>
          {canManage ? (
            <Link
              href="/app/clusters/new"
              className="mt-2 inline-block text-[13px] font-bold text-brand"
            >
              Добавить кластер
            </Link>
          ) : null}
        </div>
      ) : (
        <ul className="-mx-1 flex gap-2.5 overflow-x-auto px-1 pb-1">
          {items.map((c) => {
            const selected = selectedId === c.id;
            return (
              <li key={c.id} className="relative w-[132px] shrink-0 sm:w-[148px]">
                <button
                  type="button"
                  onClick={() => onSelect(selected ? null : c.id)}
                  className={`group w-full overflow-hidden rounded-[16px] border-2 text-left transition ${
                    selected
                      ? "border-brand shadow-elevate-brand"
                      : "border-line hover:border-brand/40"
                  }`}
                >
                  <div className="relative aspect-square bg-mint">
                    {c.coverUrl ? (
                      // eslint-disable-next-line @next/next/no-img-element
                      <img
                        src={c.coverUrl}
                        alt=""
                        className="absolute inset-0 h-full w-full object-cover"
                      />
                    ) : (
                      <span className="absolute inset-0 flex items-center justify-center">
                        <Folder className="h-10 w-10 text-brand/50" strokeWidth={1.5} />
                      </span>
                    )}
                    <div className="absolute inset-x-0 bottom-0 bg-gradient-to-t from-ink/70 to-transparent px-2 pb-2 pt-8">
                      <p className="truncate text-[13px] font-bold text-on-media">{c.title}</p>
                      {c.subtitle ? (
                        <p className="truncate text-[11px] text-on-media/80">{c.subtitle}</p>
                      ) : null}
                    </div>
                    <span
                      className={`absolute right-1.5 top-1.5 rounded-full px-2 py-0.5 text-[10px] font-bold ${
                        selected
                          ? "bg-brand text-on-brand"
                          : "bg-surface/90 text-ink backdrop-blur-sm"
                      }`}
                    >
                      {c.postsCount > 0 ? `${c.postsCount} фото` : "Нет фото"}
                    </span>
                  </div>
                </button>

                {canManage ? (
                  <div className="absolute left-1.5 top-1.5 z-10" ref={menuId === c.id ? menuRef : undefined}>
                    <button
                      type="button"
                      onClick={(e) => {
                        e.stopPropagation();
                        setMenuId(menuId === c.id ? null : c.id);
                      }}
                      className="flex h-7 w-7 items-center justify-center rounded-full bg-ink/45 text-on-media backdrop-blur-sm"
                      aria-label="Меню"
                    >
                      <MoreHorizontal className="h-4 w-4" strokeWidth={2} />
                    </button>
                    {menuId === c.id ? (
                      <div className="absolute left-0 top-8 z-20 min-w-[140px] overflow-hidden rounded-[12px] border border-line bg-surface shadow-lg">
                        <button
                          type="button"
                          onClick={() => onArchive(c)}
                          className="block w-full px-3 py-2.5 text-left text-[13px] font-semibold text-ink hover:bg-bg"
                        >
                          В архив
                        </button>
                        <button
                          type="button"
                          onClick={() => {
                            setMenuId(null);
                            setConfirmDelete(c);
                          }}
                          className="block w-full px-3 py-2.5 text-left text-[13px] font-semibold text-destructive hover:bg-bg"
                        >
                          Удалить
                        </button>
                      </div>
                    ) : null}
                  </div>
                ) : null}
              </li>
            );
          })}
        </ul>
      )}

      {selectedId ? (
        <p className="mt-2 text-[12px] text-muted">
          Показаны посты коллекции ·{" "}
          <button type="button" onClick={() => onSelect(null)} className="font-bold text-brand">
            сбросить
          </button>
        </p>
      ) : null}

      {confirmDelete ? (
        <div className="fixed inset-0 z-50 flex items-center justify-center px-4">
          <button
            type="button"
            className="absolute inset-0 bg-ink/40"
            aria-label="Закрыть"
            onClick={() => setConfirmDelete(null)}
          />
          <div className="relative z-10 w-full max-w-sm rounded-[20px] bg-surface p-5 shadow-xl">
            <button
              type="button"
              onClick={() => setConfirmDelete(null)}
              className="absolute right-3 top-3 flex h-8 w-8 items-center justify-center rounded-full hover:bg-bg"
            >
              <X className="h-4 w-4" />
            </button>
            <p className="pr-8 text-[16px] font-bold text-ink">Удалить коллекцию?</p>
            <p className="mt-2 text-[13px] text-muted">
              «{confirmDelete.title}» исчезнет. Посты останутся в профиле.
            </p>
            <div className="mt-4 flex gap-2">
              <button
                type="button"
                onClick={() => setConfirmDelete(null)}
                className="h-11 flex-1 rounded-[14px] border border-line text-sm font-semibold"
              >
                Отмена
              </button>
              <button
                type="button"
                onClick={() => onDelete(confirmDelete)}
                className="h-11 flex-1 rounded-[14px] bg-destructive text-sm font-bold text-on-media"
              >
                Удалить
              </button>
            </div>
          </div>
        </div>
      ) : null}
    </div>
  );
}
