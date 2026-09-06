"use client";

import { ChevronDown, Search, X } from "lucide-react";
import { useMemo, useState } from "react";
import {
  MARKER_TAG_GROUPS,
  tagLabelRu,
  tagsForFilter,
  type MarkerTagDef,
} from "@/features/catalog/lib/marker-tags";

type MarkerTagsFieldProps = {
  values: string[];
  onChange: (keys: string[]) => void;
};

function selectedDisplay(catalog: MarkerTagDef[], keys: string[]): string | null {
  if (keys.length === 0) return null;
  const set = new Set(keys);
  const labels = catalog.filter((t) => set.has(t.key)).map((t) => t.label);
  return labels.length > 0 ? labels.join(", ") : null;
}

/** Поле-селектор тегов с поиском (как MultiMarkerTags / AppMultiSelect). */
export function MarkerTagsField({ values, onChange }: MarkerTagsFieldProps) {
  const catalog = useMemo(() => tagsForFilter(), []);
  const [open, setOpen] = useState(false);
  const [query, setQuery] = useState("");
  const [draft, setDraft] = useState<string[]>(values);

  const display = selectedDisplay(catalog, values);
  const q = query.trim().toLowerCase();

  const filteredGroups = useMemo(() => {
    return MARKER_TAG_GROUPS.map((group) => {
      const items = catalog.filter((t) => {
        if (t.group !== group.key) return false;
        if (!q) return true;
        return (
          t.label.toLowerCase().includes(q) ||
          t.key.toLowerCase().includes(q)
        );
      });
      return { group, items };
    }).filter((g) => g.items.length > 0);
  }, [catalog, q]);

  const openSheet = () => {
    setDraft(values);
    setQuery("");
    setOpen(true);
  };

  const closeSheet = () => {
    setOpen(false);
    setQuery("");
  };

  const toggle = (key: string) => {
    setDraft((prev) =>
      prev.includes(key) ? prev.filter((k) => k !== key) : [...prev, key],
    );
  };

  const confirm = () => {
    onChange(draft);
    closeSheet();
  };

  return (
    <div>
      <p className="mb-2 text-[13px] font-semibold text-muted">Теги маркера</p>
      <button
        type="button"
        onClick={openSheet}
        className="flex min-h-11 w-full items-center gap-2 rounded-[12px] border border-line bg-surface px-3.5 py-2.5 text-left outline-none transition hover:border-brand/30"
      >
        <span
          className={`min-w-0 flex-1 text-[15px] font-semibold leading-snug ${
            display ? "text-ink" : "font-normal text-muted"
          }`}
        >
          {display ?? "Любые — оставьте пустым"}
        </span>
        <ChevronDown className="h-4 w-4 shrink-0 text-muted" strokeWidth={2} />
      </button>

      {open ? (
        <div className="fixed inset-0 z-[60] flex items-end justify-center sm:items-center">
          <button
            type="button"
            aria-label="Закрыть"
            className="absolute inset-0 bg-ink/25"
            onClick={closeSheet}
          />
          <div className="relative flex max-h-[min(85dvh,640px)] w-full max-w-[430px] flex-col rounded-t-2xl border border-line bg-surface shadow-elevate-lg sm:mx-4 sm:rounded-2xl">
            <div className="flex items-center justify-between gap-3 border-b border-line px-4 py-3">
              <p className="text-[16px] font-bold text-ink">Теги маркера</p>
              <button
                type="button"
                onClick={closeSheet}
                className="rounded-full p-1.5 text-muted transition hover:bg-bg hover:text-ink"
                aria-label="Закрыть"
              >
                <X className="h-5 w-5" strokeWidth={2} />
              </button>
            </div>

            <div className="border-b border-line px-4 py-2.5">
              <label className="flex h-10 items-center gap-2 rounded-[12px] border border-line bg-[color-mix(in_srgb,var(--bg)_70%,white)] px-3">
                <Search className="h-4 w-4 shrink-0 text-muted" strokeWidth={2} />
                <input
                  type="search"
                  value={query}
                  onChange={(e) => setQuery(e.target.value)}
                  placeholder="Поиск тега"
                  className="min-w-0 flex-1 bg-transparent text-[14px] font-medium text-ink outline-none placeholder:text-muted"
                  autoFocus
                />
              </label>
              {draft.length > 0 ? (
                <div className="mt-2 flex flex-wrap gap-1.5">
                  {draft.map((key) => (
                    <button
                      key={key}
                      type="button"
                      onClick={() => toggle(key)}
                      className="inline-flex items-center gap-1 rounded-lg bg-mint px-2 py-1 text-[12px] font-semibold text-brand"
                    >
                      {tagLabelRu(key)}
                      <X className="h-3 w-3" strokeWidth={2.5} />
                    </button>
                  ))}
                </div>
              ) : null}
            </div>

            <div className="flex-1 overflow-y-auto px-4 py-3">
              {filteredGroups.length === 0 ? (
                <p className="py-8 text-center text-sm text-muted">Ничего не найдено</p>
              ) : (
                <div className="flex flex-col gap-4">
                  {filteredGroups.map(({ group, items }) => (
                    <div key={group.key}>
                      <p className="mb-2 text-[10px] font-bold uppercase tracking-[0.06em] text-muted">
                        {group.label}
                      </p>
                      <div className="flex flex-col gap-0.5">
                        {items.map((tag) => {
                          const selected = draft.includes(tag.key);
                          return (
                            <button
                              key={tag.key}
                              type="button"
                              onClick={() => toggle(tag.key)}
                              className={`flex items-center justify-between rounded-[12px] px-3 py-2.5 text-left text-[14px] font-semibold transition ${
                                selected
                                  ? "bg-mint text-brand"
                                  : "text-ink hover:bg-[color-mix(in_srgb,var(--bg)_80%,white)]"
                              }`}
                            >
                              <span>{tag.label}</span>
                              <span
                                className={`flex h-5 w-5 items-center justify-center rounded-md border text-[11px] ${
                                  selected
                                    ? "border-brand bg-brand text-on-brand"
                                    : "border-line text-transparent"
                                }`}
                              >
                                ✓
                              </span>
                            </button>
                          );
                        })}
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </div>

            <div className="flex gap-2 border-t border-line p-3">
              <button
                type="button"
                onClick={() => setDraft([])}
                className="h-11 flex-1 rounded-[14px] border border-line text-sm font-bold text-ink transition hover:bg-bg"
              >
                Очистить
              </button>
              <button
                type="button"
                onClick={confirm}
                className="h-11 flex-1 rounded-[14px] bg-brand text-sm font-bold text-on-brand transition hover:opacity-90"
              >
                Готово
              </button>
            </div>
          </div>
        </div>
      ) : null}
    </div>
  );
}
