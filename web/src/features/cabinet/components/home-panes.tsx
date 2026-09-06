"use client";

import { LocateFixed, SlidersHorizontal, X } from "lucide-react";
import { useCallback, useEffect, useRef, useState } from "react";
import { MapMarkerPostSheet } from "@/features/cabinet/components/map-marker-post-sheet";
import { YandexMap } from "@/features/cabinet/components/yandex-map";
import {
  DEFAULT_MAP_FILTER,
  fetchMapMarkers,
  type MapMarker,
  type MapMarkersFilter,
} from "@/features/cabinet/lib/map-markers";
import { citiesForCountry, COUNTRY_OPTIONS } from "@/features/catalog/lib/locations";
import { EventEmojiField } from "@/features/feed/components/event-emoji-field";
import { MarkerTagsField } from "@/features/feed/components/marker-tags-field";

const ALMATY = { lat: 43.238949, lon: 76.889709 };

/** Полноэкранная карта с маркерами ивентов + фильтры. */
export function MapPane() {
  const [markers, setMarkers] = useState<MapMarker[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [toast, setToast] = useState<string | null>(null);
  const [openPostId, setOpenPostId] = useState<string | null>(null);
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
  const viewportRef = useRef({ center: ALMATY, zoom: 12 });
  const filterRef = useRef(filter);
  filterRef.current = filter;

  const showToast = useCallback((msg: string) => {
    setToast(msg);
    window.setTimeout(() => setToast(null), 2400);
  }, []);

  const load = useCallback(async (center: { lat: number; lon: number }, zoom: number) => {
    viewportRef.current = { center, zoom };
    const gen = ++fetchGen.current;
    setLoading(true);
    setError(null);
    try {
      const next = await fetchMapMarkers(center, zoom, filterRef.current);
      if (gen !== fetchGen.current) return;
      setMarkers(next);
    } catch {
      if (gen !== fetchGen.current) return;
      setError("Не удалось загрузить ивенты");
      setMarkers([]);
    } finally {
      if (gen === fetchGen.current) setLoading(false);
    }
  }, []);

  useEffect(() => {
    void load(viewportRef.current.center, viewportRef.current.zoom);
  }, [filter, load]);

  const onMarkerClick = useCallback(
    (marker: MapMarker) => {
      const postId = marker.postId?.trim();
      if (!postId) {
        showToast("У маркера нет поста");
        return;
      }
      setOpenPostId(postId);
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
        void load({ lat: next.lat, lon: next.lon }, next.zoom);
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
    filter.emoji ||
    filter.tagKeys.length > 0 ||
    filter.countryCode !== DEFAULT_MAP_FILTER.countryCode ||
    filter.cityCode !== DEFAULT_MAP_FILTER.cityCode;

  return (
    <div className="relative h-[calc(100dvh-3rem-4.25rem)] w-full overflow-hidden bg-mint md:h-dvh">
      <YandexMap
        className="absolute inset-0 h-full w-full"
        center={ALMATY}
        zoom={12}
        markers={markers}
        onViewportChange={load}
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

      {openPostId ? (
        <MapMarkerPostSheet postId={openPostId} onClose={() => setOpenPostId(null)} />
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
