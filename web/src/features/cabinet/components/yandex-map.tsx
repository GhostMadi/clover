"use client";

import { useEffect, useId, useRef, useState } from "react";
import type { MapMarker } from "@/features/cabinet/lib/map-markers";

const ALMATY = { lat: 43.238949, lon: 76.889709 };

type YmapsMap = {
  destroy: () => void;
  geoObjects: { removeAll: () => void; add: (obj: unknown) => void };
  events: { add: (name: string, cb: () => void) => void };
  getCenter: () => number[];
  getZoom: () => number;
  setCenter: (center: number[], zoom?: number, opts?: object) => void;
  controls: { add: (c: string, opts?: object) => void };
};

type YmapsPlacemark = {
  events: { add: (name: string, cb: (e: unknown) => void) => void };
};

declare global {
  interface Window {
    ymaps?: {
      ready: (cb: () => void) => void;
      Map: new (
        el: HTMLElement,
        opts: { center: number[]; zoom: number; controls: string[] },
        state?: object,
      ) => YmapsMap;
      Placemark: new (
        coords: number[],
        props?: object,
        opts?: object,
      ) => YmapsPlacemark;
      templateLayoutFactory: {
        createClass: (tpl: string) => unknown;
      };
    };
  }
}

type YandexMapProps = {
  className?: string;
  center?: { lat: number; lon: number };
  zoom?: number;
  markers?: MapMarker[];
  onViewportChange?: (center: { lat: number; lon: number }, zoom: number) => void;
  onMarkerClick?: (marker: MapMarker) => void;
  /** Внешний запрос «моя геолокация» — карта перемещается сюда. */
  flyTo?: { lat: number; lon: number; zoom?: number; nonce?: number } | null;
};

function loadYmaps(apiKey: string): Promise<void> {
  if (typeof window === "undefined") return Promise.resolve();
  if (window.ymaps) {
    return new Promise((resolve) => window.ymaps!.ready(() => resolve()));
  }

  const existing = document.querySelector<HTMLScriptElement>("script[data-yandex-maps]");
  if (existing) {
    return new Promise((resolve, reject) => {
      existing.addEventListener("load", () => window.ymaps!.ready(() => resolve()));
      existing.addEventListener("error", () => reject(new Error("Yandex Maps script failed")));
    });
  }

  return new Promise((resolve, reject) => {
    const script = document.createElement("script");
    script.dataset.yandexMaps = "1";
    script.src = `https://api-maps.yandex.ru/2.1/?apikey=${encodeURIComponent(apiKey)}&lang=ru_RU`;
    script.async = true;
    script.onload = () => window.ymaps!.ready(() => resolve());
    script.onerror = () => reject(new Error("Yandex Maps script failed"));
    document.head.appendChild(script);
  });
}

/** Полноэкранная Яндекс.Карта с emoji-маркерами ивентов. */
export function YandexMap({
  className = "",
  center = ALMATY,
  zoom = 12,
  markers = [],
  onViewportChange,
  onMarkerClick,
  flyTo = null,
}: YandexMapProps) {
  const hostId = useId().replace(/:/g, "");
  const mapRef = useRef<YmapsMap | null>(null);
  const iconLayoutRef = useRef<unknown>(null);
  const onViewportRef = useRef(onViewportChange);
  const onMarkerClickRef = useRef(onMarkerClick);
  onViewportRef.current = onViewportChange;
  onMarkerClickRef.current = onMarkerClick;
  const [error, setError] = useState<string | null>(null);
  const [ready, setReady] = useState(false);
  const apiKey = process.env.NEXT_PUBLIC_YANDEX_MAPS_API_KEY?.trim() ?? "";

  useEffect(() => {
    if (!apiKey) {
      setError("missing-key");
      return;
    }

    let cancelled = false;
    let debounce: ReturnType<typeof setTimeout> | undefined;

    loadYmaps(apiKey)
      .then(() => {
        if (cancelled || !window.ymaps) return;
        const el = document.getElementById(`ymap-${hostId}`);
        if (!el) return;
        mapRef.current?.destroy();

        iconLayoutRef.current = window.ymaps.templateLayoutFactory.createClass(
          `<div style="
            transform: translate(-50%, -100%);
            display: flex;
            align-items: center;
            justify-content: center;
            min-width: 40px;
            height: 40px;
            padding: 0 10px;
            border-radius: 999px;
            background: var(--surface);
            border: 2px solid var(--brand);
            box-shadow: var(--elevate-md);
            font-size: 20px;
            line-height: 1;
            cursor: pointer;
          ">$[properties.iconContent]</div>`,
        );

        const map = new window.ymaps.Map(
          el,
          {
            center: [center.lat, center.lon],
            zoom,
            controls: [],
          },
          { suppressMapOpenBlock: true },
        );
        map.controls.add("zoomControl", { size: "small", position: { right: 16, top: 128 } });
        map.controls.add("geolocationControl", { position: { right: 16, top: 208 } });

        map.events.add("boundschange", () => {
          clearTimeout(debounce);
          debounce = setTimeout(() => {
            const c = map.getCenter();
            onViewportRef.current?.({ lat: c[0], lon: c[1] }, map.getZoom());
          }, 450);
        });

        mapRef.current = map;
        setReady(true);
        onViewportRef.current?.({ lat: center.lat, lon: center.lon }, zoom);
      })
      .catch(() => {
        if (!cancelled) setError("load-failed");
      });

    return () => {
      cancelled = true;
      clearTimeout(debounce);
      mapRef.current?.destroy();
      mapRef.current = null;
      setReady(false);
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps -- initial center/zoom only
  }, [apiKey, hostId]);

  useEffect(() => {
    if (!ready || !mapRef.current || !window.ymaps) return;
    const map = mapRef.current;
    map.geoObjects.removeAll();

    for (const m of markers) {
      const placemark = new window.ymaps.Placemark(
        [m.lat, m.lng],
        {
          hintContent: m.textEmoji,
          iconContent: m.textEmoji,
        },
        {
          iconLayout: iconLayoutRef.current,
          iconShape: {
            type: "Circle",
            coordinates: [0, -20],
            radius: 22,
          },
        },
      );
      placemark.events.add("click", (e) => {
        // не открывать balloon / не пробрасывать клик в карту
        const ev = e as { stopPropagation?: () => void };
        ev.stopPropagation?.();
        onMarkerClickRef.current?.(m);
      });
      map.geoObjects.add(placemark);
    }
  }, [markers, ready]);

  useEffect(() => {
    if (!ready || !flyTo || !mapRef.current) return;
    mapRef.current.setCenter([flyTo.lat, flyTo.lon], flyTo.zoom ?? mapRef.current.getZoom(), {
      duration: 400,
    });
  }, [flyTo, ready]);

  if (!apiKey || error === "missing-key") {
    return (
      <div className={`flex flex-col items-center justify-center gap-3 bg-mint/50 p-8 text-center ${className}`}>
        <p className="font-semibold text-ink">Яндекс.Карта</p>
        <p className="max-w-sm text-sm text-muted">
          Добавь <code className="text-ink">NEXT_PUBLIC_YANDEX_MAPS_API_KEY</code> в{" "}
          <code className="text-ink">web/.env.local</code>
        </p>
      </div>
    );
  }

  if (error === "load-failed") {
    return (
      <div className={`flex items-center justify-center bg-surface p-8 ${className}`}>
        <p className="text-sm text-muted">Не удалось загрузить карту. Проверь ключ JS API и домен.</p>
      </div>
    );
  }

  return <div id={`ymap-${hostId}`} className={`bg-mint ${className}`} />;
}
