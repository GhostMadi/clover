"use client";

import { Check, SlidersHorizontal, X } from "lucide-react";
import { useEffect, useMemo, useState } from "react";
import { AppButton } from "@/components/shared/app-button";
import {
  filterSelectionKey,
  listProfileFilterCategories,
  parseFilterSelectionKey,
  type ProfileFilterCategory,
} from "@/features/resources/lib/profile-filters-api";

type ProfileFilterChipsProps = {
  profileId: string;
  /** Показывать ли кнопку (profiles.has_filters или свой профиль). */
  enabled: boolean;
  selectedKeys: Set<string>;
  onChange: (keys: Set<string>) => void;
  /** Заголовок секции сетки (как табы рядом с кнопкой на мобилке). */
  title: string;
};

/**
 * Как на мобилке: заголовок + кнопка tune → шторка мультивыбора →
 * строка активных фильтров и «Сбросить».
 */
export function ProfileFilterChips({
  profileId,
  enabled,
  selectedKeys,
  onChange,
  title,
}: ProfileFilterChipsProps) {
  const [categories, setCategories] = useState<ProfileFilterCategory[]>([]);
  const [loading, setLoading] = useState(false);
  const [open, setOpen] = useState(false);
  const [draft, setDraft] = useState<Set<string>>(new Set());
  const [query, setQuery] = useState("");

  useEffect(() => {
    if (!enabled || !profileId) {
      setCategories([]);
      return;
    }
    let cancelled = false;
    setLoading(true);
    void listProfileFilterCategories(profileId)
      .then((list) => {
        if (!cancelled) setCategories(list);
      })
      .catch(() => {
        if (!cancelled) setCategories([]);
      })
      .finally(() => {
        if (!cancelled) setLoading(false);
      });
    return () => {
      cancelled = true;
    };
  }, [enabled, profileId]);

  const activeLabels = useMemo(() => {
    const labels: string[] = [];
    for (const key of selectedKeys) {
      const parsed = parseFilterSelectionKey(key);
      labels.push(parsed?.label ?? key);
    }
    return labels;
  }, [selectedKeys]);

  const openSheet = () => {
    setDraft(new Set(selectedKeys));
    setQuery("");
    setOpen(true);
  };

  const toggleDraft = (key: string) => {
    setDraft((prev) => {
      const next = new Set(prev);
      if (next.has(key)) next.delete(key);
      else next.add(key);
      return next;
    });
  };

  const filteredGroups = useMemo(() => {
    const q = query.trim().toLowerCase();
    return categories
      .map((c) => {
        const values = c.values.filter((v) => {
          if (!q) return true;
          return v.toLowerCase().includes(q) || c.name.toLowerCase().includes(q);
        });
        return { ...c, values };
      })
      .filter((c) => c.values.length > 0);
  }, [categories, query]);

  const showButton = enabled && (loading || categories.length > 0);
  const active = selectedKeys.size > 0;

  return (
    <div className="mb-3 sm:mb-4">
      <div className="flex h-11 items-center justify-between gap-3">
        <div className="flex h-11 min-w-0 flex-1 items-center rounded-[14px] bg-bg p-[3px]">
          <div className="flex h-full min-w-0 flex-1 items-center justify-center rounded-[11px] bg-surface shadow-[0_2px_4px_color-mix(in_srgb,var(--ink)_10%,transparent)]">
            <p className="truncate text-sm font-bold leading-none text-ink sm:text-base">
              {title}
            </p>
          </div>
        </div>
        {showButton ? (
          <button
            type="button"
            disabled={loading || categories.length === 0}
            onClick={openSheet}
            title="Фильтры"
            aria-label={active ? `Фильтры, выбрано ${selectedKeys.size}` : "Фильтры"}
            className="relative flex h-11 w-11 shrink-0 items-center justify-center rounded-[14px] border border-svc-resources-ink/40 bg-svc-resources text-svc-resources-ink transition hover:brightness-[0.98] disabled:opacity-50"
          >
            {loading ? (
              <span className="h-4 w-4 animate-spin rounded-full border-2 border-svc-resources-ink border-r-transparent" />
            ) : (
              <>
                <SlidersHorizontal className="h-5 w-5" strokeWidth={2} />
                {active ? (
                  <span className="absolute right-2 top-2 h-2 w-2 rounded-full bg-svc-resources-ink" />
                ) : null}
              </>
            )}
          </button>
        ) : null}
      </div>

      {activeLabels.length > 0 ? (
        <div className="mt-2.5 flex items-center gap-2">
          <p className="min-w-0 flex-1 truncate text-[12px] font-medium text-muted">
            {activeLabels.join(" · ")}
          </p>
          <button
            type="button"
            onClick={() => onChange(new Set())}
            className="shrink-0 text-[12px] font-bold text-svc-resources-ink"
          >
            Сбросить
          </button>
        </div>
      ) : null}

      {open ? (
        <div
          className="fixed inset-0 z-50 flex items-end justify-center bg-ink/50 sm:items-center sm:p-4"
          role="dialog"
          aria-modal="true"
          aria-label="Фильтры"
          onClick={() => setOpen(false)}
        >
          <div
            className="flex max-h-[min(88dvh,720px)] w-full max-w-md flex-col overflow-hidden rounded-t-2xl border border-line bg-surface shadow-elevate-lg sm:rounded-2xl"
            onClick={(e) => e.stopPropagation()}
          >
            <div className="flex items-center gap-2 border-b border-line px-3 py-2.5">
              <h2 className="min-w-0 flex-1 text-[16px] font-bold text-ink">
                {draft.size > 0 ? `Фильтры (${draft.size})` : "Фильтры"}
              </h2>
              <button
                type="button"
                onClick={() => setOpen(false)}
                className="flex h-10 w-10 items-center justify-center rounded-full text-ink hover:bg-bg"
                aria-label="Закрыть"
              >
                <X className="h-5 w-5" strokeWidth={2} />
              </button>
            </div>

            <div className="border-b border-line px-4 py-3">
              <input
                value={query}
                onChange={(e) => setQuery(e.target.value)}
                placeholder="Поиск по фильтрам"
                className="h-11 w-full rounded-[14px] border border-line bg-bg px-3.5 text-[14px] text-ink outline-none placeholder:text-muted focus:border-svc-resources-ink/40"
              />
            </div>

            <div className="min-h-0 flex-1 overflow-y-auto px-2 py-2">
              {filteredGroups.length === 0 ? (
                <p className="px-3 py-8 text-center text-sm text-muted">Ничего не найдено</p>
              ) : (
                filteredGroups.map((group) => (
                  <div key={group.id} className="mb-3">
                    <p className="px-3 py-1.5 text-[12px] font-bold uppercase tracking-wide text-muted">
                      {group.name}
                    </p>
                    <ul>
                      {group.values.map((label) => {
                        const key = filterSelectionKey(group.id, label);
                        const on = draft.has(key);
                        return (
                          <li key={key}>
                            <button
                              type="button"
                              onClick={() => toggleDraft(key)}
                              className="flex w-full items-center gap-3 rounded-[12px] px-3 py-3 text-left transition hover:bg-svc-resources/40"
                            >
                              <span
                                className={`min-w-0 flex-1 text-[15px] ${
                                  on ? "font-bold text-ink" : "font-medium text-ink"
                                }`}
                              >
                                {label}
                              </span>
                              {on ? (
                                <Check
                                  className="h-5 w-5 shrink-0 text-svc-resources-ink"
                                  strokeWidth={2.5}
                                />
                              ) : null}
                            </button>
                          </li>
                        );
                      })}
                    </ul>
                  </div>
                ))
              )}
            </div>

            <div className="border-t border-line px-4 py-3">
              <AppButton
                service="resources"
                onClick={() => {
                  onChange(new Set(draft));
                  setOpen(false);
                }}
              >
                Применить
              </AppButton>
            </div>
          </div>
        </div>
      ) : null}
    </div>
  );
}
