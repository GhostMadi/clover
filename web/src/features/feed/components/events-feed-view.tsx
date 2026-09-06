"use client";

import { ChevronDown, MapPin, SlidersHorizontal } from "lucide-react";
import { useRouter } from "next/navigation";
import { useCallback, useEffect, useRef, useState, useTransition } from "react";
import { citiesForCountry, CITY_OPTIONS, COUNTRY_OPTIONS } from "@/features/catalog/lib/locations";
import { EventEmojiField } from "@/features/feed/components/event-emoji-field";
import { EventFeedCard } from "@/features/feed/components/event-feed-card";
import { MarkerTagsField } from "@/features/feed/components/marker-tags-field";
import { listEventsFeedMore } from "@/features/feed/lib/events-feed-client";
import {
  DEFAULT_EVENTS_FILTER,
  eventsFilterHasExtras,
  type EventsFeedFilter,
} from "@/features/feed/lib/events-feed-filter";
import type { FeedPost } from "@/features/post/lib/parse-feed";

type EventsFeedViewProps = {
  posts: FeedPost[];
  hasMore: boolean;
  filter: EventsFeedFilter;
  currentUserId: string | null;
};

type DatePreset = "today" | "tomorrow" | "dayAfter" | "week" | "month";

const DATE_PRESETS: { id: DatePreset; label: string }[] = [
  { id: "today", label: "Сегодня" },
  { id: "tomorrow", label: "Завтра" },
  { id: "dayAfter", label: "Послезавтра" },
  { id: "week", label: "Неделя" },
  { id: "month", label: "Месяц" },
];

function pad2(n: number) {
  return String(n).padStart(2, "0");
}

function toDateOnly(d: Date): string {
  return `${d.getFullYear()}-${pad2(d.getMonth() + 1)}-${pad2(d.getDate())}`;
}

function addDays(base: Date, days: number): Date {
  const d = new Date(base);
  d.setDate(d.getDate() + days);
  return d;
}

function dateOnlyToday(): Date {
  const n = new Date();
  return new Date(n.getFullYear(), n.getMonth(), n.getDate());
}

function rangeForPreset(preset: DatePreset): { from: string; to: string } {
  const today = dateOnlyToday();
  switch (preset) {
    case "today":
      return { from: toDateOnly(today), to: toDateOnly(today) };
    case "tomorrow": {
      const d = addDays(today, 1);
      return { from: toDateOnly(d), to: toDateOnly(d) };
    }
    case "dayAfter": {
      const d = addDays(today, 2);
      return { from: toDateOnly(d), to: toDateOnly(d) };
    }
    case "week":
      return { from: toDateOnly(today), to: toDateOnly(addDays(today, 6)) };
    case "month":
      return { from: toDateOnly(today), to: toDateOnly(addDays(today, 29)) };
  }
}

function matchesPreset(from: string | null, to: string | null, preset: DatePreset): boolean {
  if (!from || !to) return false;
  const r = rangeForPreset(preset);
  return from === r.from && to === r.to;
}

function buildHref(next: EventsFeedFilter): string {
  const q = new URLSearchParams();
  q.set("country", next.countryCode);
  q.set("city", next.cityCode);
  if (next.contentKind === "events_only") {
    q.set("kind", "events");
    if (next.emoji) q.set("emoji", next.emoji);
    if (next.dateFrom) q.set("from", next.dateFrom);
    if (next.dateTo) q.set("to", next.dateTo);
    if (next.tagKeys.length > 0) q.set("tags", next.tagKeys.join(","));
  }
  return `/app?${q.toString()}`;
}

function cityLabel(code: string): string {
  return CITY_OPTIONS.find((c) => c.code.toLowerCase() === code.toLowerCase())?.label ?? code;
}

function filterSummary(filter: EventsFeedFilter): string {
  const parts = [cityLabel(filter.cityCode)];
  parts.push(filter.contentKind === "events_only" ? "Ивенты" : "Все");
  if (filter.emoji) parts.push(filter.emoji);
  if (filter.dateFrom || filter.dateTo) {
    if (filter.dateFrom && filter.dateTo && filter.dateFrom === filter.dateTo) {
      parts.push(filter.dateFrom);
    } else if (filter.dateFrom || filter.dateTo) {
      parts.push(`${filter.dateFrom ?? "…"} → ${filter.dateTo ?? "…"}`);
    }
  }
  if (filter.tagKeys.length > 0) parts.push(`${filter.tagKeys.length} тег.`);
  return parts.join(" · ");
}

/** Лента: белый фон + колонка. Фильтр — как EventsFilterSheet (страна/город/даты/эмодзи/теги). */
export function EventsFeedView({
  posts: initialPosts,
  hasMore: initialHasMore,
  filter,
  currentUserId,
}: EventsFeedViewProps) {
  const router = useRouter();
  const [open, setOpen] = useState(false);
  const [draft, setDraft] = useState<EventsFeedFilter>(filter);
  const [items, setItems] = useState(initialPosts);
  const [hasMore, setHasMore] = useState(initialHasMore);
  const [loadingMore, setLoadingMore] = useState(false);
  const [, startTransition] = useTransition();
  const loadLock = useRef(false);
  const sentinelRef = useRef<HTMLDivElement>(null);
  const [followByAuthor, setFollowByAuthor] = useState<Record<string, boolean>>(() => {
    const map: Record<string, boolean> = {};
    for (const p of initialPosts) map[p.userId] = p.myFollowingAuthor;
    return map;
  });
  const [toggledAuthors, setToggledAuthors] = useState<Record<string, true>>({});
  const panelRef = useRef<HTMLDivElement>(null);
  const cities = citiesForCountry(draft.countryCode);
  const cityOk = cities.some((c) => c.code.toLowerCase() === draft.cityCode.toLowerCase());
  const showEventFilters = draft.contentKind === "events_only";
  const extras = eventsFilterHasExtras(filter);

  useEffect(() => {
    setItems(initialPosts);
    setHasMore(initialHasMore);
    const map: Record<string, boolean> = {};
    for (const p of initialPosts) map[p.userId] = p.myFollowingAuthor;
    setFollowByAuthor(map);
    setToggledAuthors({});
    loadLock.current = false;
  }, [initialPosts, initialHasMore, filter]);

  const loadMore = useCallback(() => {
    if (loadLock.current || loadingMore || !hasMore || items.length === 0) return;
    loadLock.current = true;
    setLoadingMore(true);
    const cursor = items[items.length - 1];
    startTransition(async () => {
      try {
        const page = await listEventsFeedMore(filter, cursor);
        setItems((prev) => {
          const ids = new Set(prev.map((p) => p.id));
          const next = page.posts.filter((p) => !ids.has(p.id));
          return next.length ? [...prev, ...next] : prev;
        });
        setFollowByAuthor((prev) => {
          const next = { ...prev };
          for (const p of page.posts) {
            if (next[p.userId] == null) next[p.userId] = p.myFollowingAuthor;
          }
          return next;
        });
        setHasMore(page.hasMore && page.posts.length > 0);
      } catch {
        // keep hasMore — можно повторить при следующем скролле
      } finally {
        setLoadingMore(false);
        loadLock.current = false;
      }
    });
  }, [filter, hasMore, items, loadingMore, startTransition]);

  useEffect(() => {
    const node = sentinelRef.current;
    if (!node || !hasMore) return;
    const io = new IntersectionObserver(
      (entries) => {
        if (entries.some((e) => e.isIntersecting)) loadMore();
      },
      { rootMargin: "320px 0px" },
    );
    io.observe(node);
    return () => io.disconnect();
  }, [hasMore, loadMore]);

  const openPanel = () => {
    setDraft(filter);
    setOpen(true);
  };

  const closePanel = () => setOpen(false);

  const apply = () => {
    let next = draft;
    if (next.contentKind === "all") {
      next = { ...next, emoji: null, dateFrom: null, dateTo: null, tagKeys: [] };
    }
    router.push(buildHref(next));
    setOpen(false);
  };

  const reset = () => {
    setDraft({
      ...DEFAULT_EVENTS_FILTER,
      contentKind: "events_only",
      countryCode: filter.countryCode,
      cityCode: filter.cityCode,
      emoji: null,
      dateFrom: null,
      dateTo: null,
      tagKeys: [],
    });
  };

  useEffect(() => {
    if (!open) return;
    const onPointer = (e: MouseEvent | TouchEvent) => {
      const el = panelRef.current;
      if (!el) return;
      if (e.target instanceof Node && !el.contains(e.target)) closePanel();
    };
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape") closePanel();
    };
    document.addEventListener("mousedown", onPointer);
    document.addEventListener("touchstart", onPointer);
    document.addEventListener("keydown", onKey);
    return () => {
      document.removeEventListener("mousedown", onPointer);
      document.removeEventListener("touchstart", onPointer);
      document.removeEventListener("keydown", onKey);
    };
  }, [open]);

  const setCountry = (countryCode: string) => {
    const list = citiesForCountry(countryCode);
    const keep = list.some((c) => c.code.toLowerCase() === draft.cityCode.toLowerCase());
    setDraft({
      ...draft,
      countryCode,
      cityCode: keep ? draft.cityCode : list[0]?.code ?? "almaty",
    });
  };

  const setKind = (contentKind: EventsFeedFilter["contentKind"]) => {
    if (contentKind === "all") {
      setDraft({
        ...draft,
        contentKind,
        emoji: null,
        dateFrom: null,
        dateTo: null,
        tagKeys: [],
      });
      return;
    }
    setDraft({ ...draft, contentKind });
  };

  const onFollowChange = (authorId: string, following: boolean) => {
    setFollowByAuthor((prev) => ({ ...prev, [authorId]: following }));
    setToggledAuthors((prev) => ({ ...prev, [authorId]: true }));
  };

  return (
    <div className="flex min-h-[calc(100dvh-3rem-4.25rem)] w-full flex-col bg-surface md:min-h-dvh">
      <div className="relative z-20 mx-auto w-full max-w-[430px] px-4 pt-3 sm:max-w-[480px]" ref={panelRef}>
        <button
          type="button"
          aria-expanded={open}
          aria-controls="feed-filter-panel"
          onClick={() => (open ? closePanel() : openPanel())}
          className={`mx-auto flex max-w-full items-center gap-1.5 rounded-full px-2.5 py-1 text-[13px] transition hover:bg-[color-mix(in_srgb,var(--ink)_4%,transparent)] ${
            extras ? "text-brand" : "text-muted hover:text-ink"
          }`}
        >
          {extras ? (
            <SlidersHorizontal className="h-3.5 w-3.5 shrink-0" strokeWidth={2} />
          ) : (
            <MapPin className="h-3.5 w-3.5 shrink-0 opacity-70" strokeWidth={2} />
          )}
          <span className="truncate font-medium tracking-[-0.01em]">{filterSummary(filter)}</span>
          <ChevronDown
            className={`h-3.5 w-3.5 shrink-0 opacity-60 transition-transform duration-200 ${open ? "rotate-180" : ""}`}
            strokeWidth={2}
          />
        </button>

        {open ? (
          <div
            id="feed-filter-panel"
            className="absolute left-4 right-4 top-full z-30 mt-1.5 max-h-[min(70dvh,560px)] origin-top animate-[rise_180ms_var(--ease-out)] overflow-y-auto rounded-2xl border border-line bg-surface p-3 shadow-elevate-lg"
          >
            <div className="flex flex-col gap-3">
              <div className="grid grid-cols-2 gap-2">
                <label className="flex flex-col gap-1">
                  <span className="px-0.5 text-[10px] font-bold uppercase tracking-[0.06em] text-muted">
                    Страна
                  </span>
                  <select
                    aria-label="Страна"
                    value={draft.countryCode}
                    onChange={(e) => setCountry(e.target.value)}
                    className="h-9 w-full rounded-[12px] border border-line bg-surface px-2.5 text-sm font-semibold text-ink outline-none"
                  >
                    {COUNTRY_OPTIONS.map((c) => (
                      <option key={c.code} value={c.code}>
                        {c.label}
                      </option>
                    ))}
                  </select>
                </label>
                <label className="flex flex-col gap-1">
                  <span className="px-0.5 text-[10px] font-bold uppercase tracking-[0.06em] text-muted">
                    Город
                  </span>
                  <select
                    aria-label="Город"
                    value={cityOk ? draft.cityCode : cities[0]?.code}
                    onChange={(e) => setDraft({ ...draft, cityCode: e.target.value })}
                    className="h-9 w-full rounded-[12px] border border-line bg-surface px-2.5 text-sm font-semibold text-ink outline-none"
                  >
                    {cities.map((c) => (
                      <option key={c.code} value={c.code}>
                        {c.label}
                      </option>
                    ))}
                  </select>
                </label>
              </div>

              <div className="flex rounded-[12px] border border-line p-0.5">
                <button
                  type="button"
                  onClick={() => setKind("all")}
                  className={`flex-1 rounded-[10px] px-3 py-1.5 text-sm font-semibold transition ${
                    draft.contentKind === "all" ? "bg-mint text-brand" : "text-muted hover:text-ink"
                  }`}
                >
                  Все
                </button>
                <button
                  type="button"
                  onClick={() => setKind("events_only")}
                  className={`flex-1 rounded-[10px] px-3 py-1.5 text-sm font-semibold transition ${
                    draft.contentKind === "events_only"
                      ? "bg-mint text-brand"
                      : "text-muted hover:text-ink"
                  }`}
                >
                  Ивенты
                </button>
              </div>

              {showEventFilters ? (
                <>
                  <div>
                    <p className="mb-2 text-[13px] font-semibold text-muted">Дни ивента</p>
                    <div className="flex flex-wrap gap-2">
                      {DATE_PRESETS.map((p) => {
                        const selected = matchesPreset(draft.dateFrom, draft.dateTo, p.id);
                        return (
                          <button
                            key={p.id}
                            type="button"
                            onClick={() => {
                              const r = rangeForPreset(p.id);
                              setDraft({ ...draft, dateFrom: r.from, dateTo: r.to });
                            }}
                            className={`rounded-xl border px-3 py-2 text-[13px] font-semibold transition ${
                              selected
                                ? "border-border-card-green bg-surface-soft-green/70 text-brand"
                                : "border-line bg-surface-muted text-ink"
                            }`}
                          >
                            {p.label}
                          </button>
                        );
                      })}
                    </div>
                    <div className="mt-2.5 grid grid-cols-2 gap-2">
                      <label className="flex flex-col gap-1">
                        <span className="px-0.5 text-[10px] font-bold uppercase tracking-[0.06em] text-muted">
                          С
                        </span>
                        <input
                          type="date"
                          value={draft.dateFrom ?? ""}
                          max={draft.dateTo ?? undefined}
                          onChange={(e) => {
                            const v = e.target.value || null;
                            setDraft({
                              ...draft,
                              dateFrom: v,
                              dateTo:
                                draft.dateTo && v && draft.dateTo < v ? v : draft.dateTo,
                            });
                          }}
                          className="h-9 rounded-[12px] border border-line bg-surface px-2.5 text-sm font-semibold text-ink outline-none"
                        />
                      </label>
                      <label className="flex flex-col gap-1">
                        <span className="px-0.5 text-[10px] font-bold uppercase tracking-[0.06em] text-muted">
                          По
                        </span>
                        <input
                          type="date"
                          value={draft.dateTo ?? ""}
                          min={draft.dateFrom ?? undefined}
                          onChange={(e) => {
                            const v = e.target.value || null;
                            setDraft({
                              ...draft,
                              dateTo: v,
                              dateFrom:
                                draft.dateFrom && v && draft.dateFrom > v ? v : draft.dateFrom,
                            });
                          }}
                          className="h-9 rounded-[12px] border border-line bg-surface px-2.5 text-sm font-semibold text-ink outline-none"
                        />
                      </label>
                    </div>
                  </div>

                  <EventEmojiField
                    value={draft.emoji}
                    onChange={(emoji) => setDraft({ ...draft, emoji })}
                  />

                  <MarkerTagsField
                    values={draft.tagKeys}
                    onChange={(tagKeys) => setDraft({ ...draft, tagKeys })}
                  />
                </>
              ) : null}

              <div className="flex gap-2 pt-1">
                <button
                  type="button"
                  onClick={reset}
                  className="h-11 flex-1 rounded-[14px] border border-line text-sm font-bold text-ink transition hover:bg-bg"
                >
                  Сбросить
                </button>
                <button
                  type="button"
                  onClick={apply}
                  className="h-11 flex-1 rounded-[14px] bg-brand text-sm font-bold text-on-brand transition hover:opacity-90"
                >
                  Применить
                </button>
              </div>
            </div>
          </div>
        ) : null}
      </div>

      <div className="mx-auto flex w-full max-w-[430px] flex-col gap-2.5 pb-8 pt-1 sm:max-w-[480px]">
        {items.length === 0 ? (
          <div className="px-6 py-16 text-center">
            <p className="text-sm font-semibold text-ink">Ничего не найдено</p>
            <p className="mt-1 text-sm text-muted">Попробуйте изменить фильтр</p>
          </div>
        ) : (
          <>
            {items.map((post) => (
              <EventFeedCard
                key={post.id}
                post={post}
                currentUserId={currentUserId}
                followingAuthor={followByAuthor[post.userId] ?? post.myFollowingAuthor}
                followToggledInSession={Boolean(toggledAuthors[post.userId])}
                onFollowChange={onFollowChange}
              />
            ))}
            <div ref={sentinelRef} className="h-8 w-full" aria-hidden />
            {loadingMore ? (
              <p className="py-4 text-center text-sm text-muted">Загрузка…</p>
            ) : null}
            {!hasMore && items.length > 0 ? (
              <p className="py-4 text-center text-xs text-muted">Это всё</p>
            ) : null}
          </>
        )}
      </div>
    </div>
  );
}
