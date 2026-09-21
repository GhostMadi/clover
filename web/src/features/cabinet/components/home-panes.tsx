"use client";

import { LocateFixed, SlidersHorizontal, X } from "lucide-react";
import { useCallback, useEffect, useRef, useState } from "react";
import { MapMarkerPostSheet } from "@/features/cabinet/components/map-marker-post-sheet";
import { MapboxMap } from "@/features/cabinet/components/mapbox-map";
import {
  DEFAULT_MAP_FILTER,
  fetchMapMarkers,
  mapMarkersCacheKey,
  markersAtLocation,
  postIdsFromMarkers,
  prefetchNeighborMapMarkers,
  readMapMarkersCache,
  shouldFetchMapViewport,
  writeMapMarkersCache,
  type MapMarker,
  type MapMarkersFilter,
  type MapViewport,
} from "@/features/cabinet/lib/map-markers";
import { citiesForCountry, COUNTRY_OPTIONS } from "@/features/catalog/lib/locations";
import { EventEmojiField } from "@/features/feed/components/event-emoji-field";
import { MarkerTagsField } from "@/features/feed/components/marker-tags-field";

const ALMATY = { lat: 43.238949, lon: 76.889709 };

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

/** Полноэкранная карта с маркерами ивентов + фильтры. */
export function MapPane() {
  const [markers, setMarkers] = useState<MapMarker[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [toast, setToast] = useState<string | null>(null);
  const [openPostIds, setOpenPostIds] = useState<string[] | null>(null);
  const [filterOpen, setFilterOpen] = useState(false);
  const [filter, setFilter] = useState<MapMarkersFilter>(DEFAULT_MAP_FILTER);
  const [draft, setDraft] = useState<MapMarkersFilter>(DEFAULT_MAP_FILTER);
  const [flyTo, setFlyTo] = useState<{
    lat: number;
    lon: number;
    zoom?: number;
    nonce: number;
  } | null>(null);
  const [locating, setLocating] = useState(false);
  const fetchGen = useRef(0);
  const flyNonce = useRef(0);
  const viewportRef = useRef<MapViewport>({ center: ALMATY, zoom: 12 });
  const lastFetchedRef = useRef<MapViewport | null>(null);
  const filterRef = useRef(filter);
  const markersRef = useRef(markers);
  filterRef.current = filter;
  markersRef.current = markers;

  const showToast = useCallback((msg: string) => {
    setToast(msg);
    window.setTimeout(() => setToast(null), 2400);
  }, []);

  const load = useCallback(
    async (
      center: { lat: number; lon: number },
      zoom: number,
      opts?: { force?: boolean },
    ) => {
      const next: MapViewport = { center, zoom };
      viewportRef.current = next;

      const prev = lastFetchedRef.current;
      if (!opts?.force && prev && !shouldFetchMapViewport(prev, next)) {
        return;
      }

      const gen = ++fetchGen.current;
      const cacheKey = mapMarkersCacheKey(next, filterRef.current);
      const cached = readMapMarkersCache(cacheKey);
      if (cached?.length) {
        setMarkers(cached);
      }
      setLoading(true);
      setError(null);
      try {
        const list = await fetchMapMarkers(center, zoom, filterRef.current);
        if (gen !== fetchGen.current) return;
        lastFetchedRef.current = next;
        writeMapMarkersCache(cacheKey, list);
        setMarkers(list);
        void prefetchNeighborMapMarkers(next, filterRef.current);
      } catch {
        if (gen !== fetchGen.current) return;
        setError("Не удалось загрузить ивенты");
      } finally {
        if (gen === fetchGen.current) setLoading(false);
      }
    },
    [],
  );

  useEffect(() => {
    lastFetchedRef.current = null;
    void load(viewportRef.current.center, viewportRef.current.zoom, { force: true });
  }, [filter, load]);

  const onViewportChange = useCallback(
    (center: { lat: number; lon: number }, zoom: number) => {
      void load(center, zoom);
    },
    [load],
  );

  const onMarkerClick = useCallback(
    (marker: MapMarker) => {
      if ((marker.pointCount ?? 0) >= 1) {
        showToast("Приблизьте карту");
        return;
      }
      const group = markersAtLocation(markersRef.current, marker.lat, marker.lng);
      const stack = group.length > 0 ? group : [marker];
      const ids = postIdsFromMarkers(stack);
      if (ids.length === 0) {
        showToast("У маркера нет поста");
        return;
      }
      setOpenPostIds(ids);
    },
    [showToast],
  );

  const goMyLocation = useCallback(() => {
    if (!navigator.geolocation) {
      showToast("Геолокация недоступна");
      return;
    }
    setLocating(true);
    navigator.geolocation.getCurrentPosition(
      (pos) => {
        const next = {
          lat: pos.coords.latitude,
          lon: pos.coords.longitude,
          zoom: 14,
          nonce: ++flyNonce.current,
        };
        setFlyTo(next);
        void load({ lat: next.lat, lon: next.lon }, next.zoom, { force: true });
        setLocating(false);
      },
      () => {
        setLocating(false);
        showToast("Не удалось определить местоположение");
      },
      { enableHighAccuracy: true, timeout: 12_000, maximumAge: 30_000 },
    );
  }, [load, showToast]);

  const cities = citiesForCountry(draft.countryCode);
  const filterActive =
    Boolean(filter.emoji) ||
    filter.tagKeys.length > 0 ||
    Boolean(filter.dateFrom) ||
    Boolean(filter.dateTo) ||
    filter.countryCode !== DEFAULT_MAP_FILTER.countryCode ||
    filter.cityCode !== DEFAULT_MAP_FILTER.cityCode;

  return (
    <div className="relative h-[calc(100dvh-3rem-4.25rem)] w-full overflow-hidden bg-mint md:h-dvh">
      <MapboxMap
        className="absolute inset-0 h-full w-full"
        center={ALMATY}
        zoom={12}
        markers={markers}
        onViewportChange={onViewportChange}
        onMarkerClick={onMarkerClick}
        flyTo={flyTo}
      />

      <button
        type="button"
        onClick={() => {
          setDraft(filter);
          setFilterOpen(true);
        }}
        title="Фильтры"
        className={`absolute left-4 top-4 z-20 flex h-12 items-center gap-2 rounded-full border border-line bg-surface px-3.5 text-ink shadow-elevate-md ${
          filterActive ? "ring-2 ring-brand" : ""
        }`}
      >
        <SlidersHorizontal className="h-5 w-5" strokeWidth={2} />
        <span className="text-[13px] font-bold">Фильтры</span>
      </button>

      <button
        type="button"
        onClick={goMyLocation}
        disabled={locating}
        title="Моя геолокация"
        className="absolute bottom-20 right-4 z-20 flex h-12 w-12 items-center justify-center rounded-full border border-line bg-surface text-ink shadow-elevate-md transition hover:bg-mint disabled:opacity-60 md:bottom-6"
      >
        <LocateFixed className={`h-5 w-5 ${locating ? "animate-pulse text-brand" : ""}`} strokeWidth={2} />
      </button>

      {(loading || error || toast) && (
        <p className="pointer-events-none absolute bottom-4 left-1/2 z-10 -translate-x-1/2 rounded-full bg-surface/90 px-3 py-1.5 text-xs text-muted shadow-sm backdrop-blur-sm">
          {toast ?? error ?? "Загрузка…"}
        </p>
      )}

      {openPostIds ? (
        <MapMarkerPostSheet postIds={openPostIds} onClose={() => setOpenPostIds(null)} />
      ) : null}

      {filterOpen ? (
        <div className="fixed inset-0 z-50 flex items-end justify-center sm:items-center">
          <button
            type="button"
            className="absolute inset-0 bg-ink/40"
            aria-label="Закрыть"
            onClick={() => setFilterOpen(false)}
          />
          <div className="relative z-10 max-h-[85dvh] w-full max-w-md overflow-y-auto rounded-t-[20px] bg-surface shadow-xl sm:rounded-[20px]">
            <div className="sticky top-0 flex items-center gap-2 border-b border-line bg-surface px-3 py-3">
              <h2 className="min-w-0 flex-1 text-[16px] font-bold text-ink">Фильтры карты</h2>
              <button
                type="button"
                onClick={() => setFilterOpen(false)}
                className="flex h-9 w-9 items-center justify-center rounded-full hover:bg-bg"
                aria-label="Закрыть"
              >
                <X className="h-5 w-5" strokeWidth={2} />
              </button>
            </div>
            <div className="space-y-4 px-4 py-4">
              <label className="block">
                <span className="mb-1.5 block text-[13px] font-semibold text-ink">Страна</span>
                <select
                  value={draft.countryCode}
                  onChange={(e) => {
                    const countryCode = e.target.value;
                    const citiesNext = citiesForCountry(countryCode);
                    setDraft((d) => ({
                      ...d,
                      countryCode,
                      cityCode: citiesNext[0]?.code ?? d.cityCode,
                    }));
                  }}
                  className="h-11 w-full rounded-[14px] border border-line bg-bg px-3 text-[14px] text-ink"
                >
                  {COUNTRY_OPTIONS.map((c) => (
                    <option key={c.code} value={c.code}>
                      {c.label}
                    </option>
                  ))}
                </select>
              </label>
              <label className="block">
                <span className="mb-1.5 block text-[13px] font-semibold text-ink">Город</span>
                <select
                  value={draft.cityCode}
                  onChange={(e) => setDraft((d) => ({ ...d, cityCode: e.target.value }))}
                  className="h-11 w-full rounded-[14px] border border-line bg-bg px-3 text-[14px] text-ink"
                >
                  {cities.map((c) => (
                    <option key={c.code} value={c.code}>
                      {c.label}
                    </option>
                  ))}
                </select>
              </label>

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
                          setDraft((d) => ({ ...d, dateFrom: r.from, dateTo: r.to }));
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
                        setDraft((d) => ({
                          ...d,
                          dateFrom: v,
                          dateTo: d.dateTo && v && d.dateTo < v ? v : d.dateTo,
                        }));
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
                        setDraft((d) => ({
                          ...d,
                          dateTo: v,
                          dateFrom: d.dateFrom && v && d.dateFrom > v ? v : d.dateFrom,
                        }));
                      }}
                      className="h-9 rounded-[12px] border border-line bg-surface px-2.5 text-sm font-semibold text-ink outline-none"
                    />
                  </label>
                </div>
              </div>

              <div>
                <p className="mb-1.5 text-[13px] font-semibold text-ink">Эмодзи</p>
                <EventEmojiField
                  value={draft.emoji}
                  onChange={(emoji) => setDraft((d) => ({ ...d, emoji }))}
                />
              </div>
              <div>
                <p className="mb-1.5 text-[13px] font-semibold text-ink">Теги</p>
                <MarkerTagsField
                  values={draft.tagKeys}
                  onChange={(tagKeys) => setDraft((d) => ({ ...d, tagKeys }))}
                />
              </div>
            </div>
            <div className="sticky bottom-0 flex gap-2 border-t border-line bg-surface px-4 py-3">
              <button
                type="button"
                onClick={() => {
                  setDraft(DEFAULT_MAP_FILTER);
                  setFilter(DEFAULT_MAP_FILTER);
                  setFilterOpen(false);
                }}
                className="h-11 flex-1 rounded-[14px] border border-line text-sm font-semibold text-ink"
              >
                Сбросить
              </button>
              <button
                type="button"
                onClick={() => {
                  setFilter(draft);
                  setFilterOpen(false);
                }}
                className="h-11 flex-1 rounded-[14px] bg-brand text-sm font-bold text-on-brand"
              >
                Применить
              </button>
            </div>
          </div>
        </div>
      ) : null}
    </div>
  );
}
